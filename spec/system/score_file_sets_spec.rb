# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Score FileSets and PDF reader", type: :system do
  let(:press) { create(:press, subdomain: Services.score_press) }
  let(:user) { create(:press_admin, press: press) }
  let(:score) do
    create(:score, press: press.subdomain,
                   user: user,
                   visibility: "open",
                   representative_id: cover.id,
                   title: ["A Title"],
                   creator: ["A Composer"],
                   octave_compass: ['2', '2.5', '3'],
                   solo: "yes",
                   amplified_electronics: ["Optional"],
                   musical_presentation: "Traditional concert")
  end

  # Visibility and edit_groups which would normally propagate from the Work don't
  # here because we can't use redis. So we need to add them to each FileSet.
  let(:cover) do
    create(:file_set, content: File.open(File.join(fixture_path, 'csv', 'miranda.jpg')),
                      edit_groups: ['admin', 'carillon_admin'],
                      visibility: "open")
  end
  let(:file_set) do
    create(:file_set, content: File.open(File.join(fixture_path, 'kitty.tif')),
                      creator: ["Ida No"],
                      title: ["Kitty"],
                      description: ["Just a file"],
                      extra_json_properties: { score_version: "eleventy-three" }.to_json,
                      edit_groups: ['admin', 'carillon_admin'],
                      visibility: "open")
  end
  let(:pdf) do
    create(:file_set, content: File.open(File.join(fixture_path, 'dummy.pdf')),
                      title: ['PDF EBook'],
                      edit_groups: ['admin', 'carillon_admin'],
                      visibility: "open")
  end

  before do
    sign_in user
    stub_out_redis
    score.ordered_members = [cover, file_set, pdf]
    score.save!
    cover.save!
    file_set.save!
    pdf.save!
  end

  it do
    visit score_catalog_path(score.id)

    expect(page).to have_content('A Title')
    expect(page).not_to have_content('Read Book')

    click_on('Kitty')

    # Make sure the score specific file_set fields (like score_version) that are
    # in extra_json_properties show up on the file_set page.
    expect(page).to have_content('Score version')
    expect(page).to have_content('eleventy-three')

    # Make sure FeaturedRepresentative can be set for the pdf
    visit score_show_path(score.id)

    within_fieldset pdf.id do
      expect(page).not_to have_xpath('.//div/div/b')
      select('pdf_ebook', from: 'kind')
      click_on('Set')
      expect(page).to have_xpath('.//div/div/b') # this is now "pdf_ebook"
    end

    visit score_catalog_path(score.id)

    expect(page).to have_content('Read Book')

    # Make sure the ereader loads.
    # TODO: HELIO-2924

    # And then finally un-set the pdf_ebook to make sure that's all working
    # since I don't think we test that elsewhere.
    visit score_show_path(score.id)

    within_fieldset pdf.id do
      expect(page).to have_xpath('.//div/div/b')
      accept_alert do
        click_on('Unset')
      end
      expect(page).not_to have_xpath('.//div/div/b') # 'pdf_ebook' is gone now
    end
  end
end