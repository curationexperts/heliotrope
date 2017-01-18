require 'rails_helper'

feature "Monograph Catalog Facets" do
  before do
    stub_out_redis
  end

  let(:cover) { create(:public_file_set) }

  context "keywords" do
    let(:monograph) { create(:public_monograph, title: ["Yellow"], representative_id: cover.id) }
    let(:file_set1) { create(:public_file_set, keywords: ["cat", "dog", "elephant", "lizard", "monkey", "mouse", "tiger"]) }
    before do
      monograph.ordered_members << cover
      monograph.ordered_members << file_set1
      monograph.save!
    end
    scenario "shows keywords in the intended order" do
      visit monograph_catalog_facet_path(id: 'keywords_sim', monograph_id: monograph.id)
      expect(page).to have_selector '.facet-values li:first', text: "cat"
    end
  end

  context "sections" do
    let(:section1) { build(:public_section, title: ['C 1']) }
    let(:section2) { build(:public_section, title: ['B 2']) }
    let(:section3) { build(:public_section, title: ['A 3']) }

    let(:monograph) do
      m = build(:public_monograph, title: ["Yellow"], representative_id: cover.id)
      m.ordered_members = [cover, section1, section2, section3]
      m.save! # Now m will have an ID
      [section1, section2, section3].each do |section|
        section.monograph_id = m.id
        section.save!
      end
      m
    end

    let(:fs1) { build(:public_file_set, title: ['Sec 1 File 1']) }
    let(:fs2) { build(:public_file_set, title: ['Sec 2 File 1']) }
    let(:fs3) { build(:public_file_set, title: ['Sec 2 File 2']) }
    let(:fs4) { build(:public_file_set, title: ['Sec 3 File 1']) }
    let(:fs5) { build(:public_file_set, title: ['Sec 3 File 2']) }
    let(:fs6) { build(:public_file_set, title: ['Sec 3 File 3']) }

    before do
      # Section 1 has 1 file
      section1.ordered_members = [fs1]
      section1.save!
      # Section 2 has 2 files
      section2.ordered_members = [fs2, fs3]
      section2.save!
      # Section 3 has 3 files
      section3.ordered_members = [fs4, fs5, fs6]
      section3.save!

      # Update the solr index for each file to add section info
      [section1, section2, section3].each do |section|
        section.ordered_members.to_a.each(&:update_index)
      end
    end

    scenario "shows sections in intended order" do
      visit monograph_catalog_facet_path(id: 'section_title_sim', monograph_id: monograph.id)

      # facet section order should be:
      # "C 1"
      # "B 2"
      # "A 3"
      # so by order, not alphabetically or by frequency

      expect(page).to have_selector '.facet-values li:first', text: "C 1"
      expect(page).to_not have_selector '.facet-values li:first', text: "A 3"
    end
  end

  context "with italics in the title" do
    let(:section) { create(:public_section, title: ["A Section with _Italicized Title_ Stuff"]) }

    let(:monograph) do
      m = build(:public_monograph, title: ["Yellow"], representative_id: cover.id)
      m.ordered_members = [cover, section]
      m.save!
      section.monograph_id = m.id
      section.save!
      m
    end

    let(:fs) { create(:public_file_set) }

    before do
      section.ordered_members = [fs]
      section.save!
      fs.update_index
    end

    scenario "shows italics (emphasis) in section facet links" do
      visit monograph_catalog_path(id: monograph.id)
      # get text inside <em> tags
      italicized_text = page.first('#facet-section_title_sim li .facet_select em').text
      expect(italicized_text).to eq 'Italicized Title'

      # the facet breadcrumb does not show the markdown underscores
      click_link 'A Section with Italicized Title Stuff'
      facet_breadcrumb_text = page.first('.appliedFilter span .filterValue').text
      expect(facet_breadcrumb_text).to eq 'A Section with Italicized Title Stuff'
    end
  end

  context "all facets" do
    let(:user) { create(:platform_admin) }
    let(:monograph) { create(:monograph, user: user, title: ["Yellow"], representative_id: cover.id) }
    before do
      login_as user
      monograph.ordered_members << cover
      monograph.save!
    end

    scenario "shows the correct facets" do
      visit new_curation_concerns_section_path
      fill_in 'Title', with: "A Section"
      select monograph.title.first, from: "Monograph"
      click_button 'Create Section'

      click_link 'Attach a File'
      fill_in 'Title', with: 'File Title'
      fill_in 'Resource Type', with: 'image'
      fill_in 'Content Type', with: 'portrait'
      fill_in 'Exclusive to Platform?', with: 'yes'
      fill_in 'Primary Creator (family name)', with: 'McTesterson'
      fill_in 'Primary Creator (given name)', with: 'Testy'
      fill_in 'Search Year', with: '1974'
      fill_in 'Keywords', with: 'stuff'
      attach_file 'file_set_files', File.join(fixture_path, 'csv', 'miranda.jpg')
      click_button 'Attach to Section'

      # Selectors needed for assets/javascripts/ga_event_tracking.js
      # If these change, fix here then update ga_event_tracking.js
      visit monograph_catalog_path(id: monograph.id)

      expect(page).to have_selector('#facet-section_title_sim a.facet_select')
      expect(page).to have_selector('#facet-keywords_sim a.facet_select')
      expect(page).to have_selector('#facet-creator_full_name_sim a.facet_select')
      expect(page).to have_selector('#facet-resource_type_sim a.facet_select')
      # content type is nested/pivoted under resource type
      expect(find('#facet-resource_type_sim-image a.facet_select').text).to eq 'portrait'
      expect(page).to have_selector('#facet-search_year_sim a.facet_select')
      expect(page).to have_selector('#facet-exclusive_to_platform_sim a.facet_select')
    end
  end
end
