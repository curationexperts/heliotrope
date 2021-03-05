# frozen_string_literal: true

class PdfEbooksController < CheckpointController
  include Watermark::Watermarkable

  def show
    pdf_ebook = Sighrax.from_noid(params[:id])
    policy = PdfEbookPolicy.new(current_actor, pdf_ebook)
    policy.authorize! :show?

    @presenter = Sighrax.hyrax_presenter(pdf_ebook, current_ability)
    @parent_presenter = Sighrax.hyrax_presenter(pdf_ebook.parent, current_ability)
    @title = @presenter.parent.present? ? @presenter.parent.page_title : @presenter.page_title
    @citable_link = @parent_presenter.citable_link
    @back_link = if params[:publisher].present?
                   URI.join(main_app.root_url, params[:publisher]).to_s
                 else
                   @presenter.parent.catalog_url
                 end
    @ebook_download_presenter = EBookDownloadPresenter.new(@parent_presenter, current_ability, current_actor)

    CounterService.from(self, @presenter).count(request: 1)
    render layout: false
  end

  def file
    pdf_ebook = Sighrax.from_noid(params[:id])
    policy = PdfEbookPolicy.new(current_actor, pdf_ebook)
    policy.authorize! :show?

    do_reader_download(pdf_ebook)
  rescue StandardError => e
    Rails.logger.error "PdfEbooks#file raised #{e}"
    head :no_content
  end

  def do_reader_download(pdf_ebook)
    pdf = UnpackService.root_path_from_noid(pdf_ebook.noid, 'pdf_ebook') + ".pdf"
    if File.exist? pdf
      response.headers['Accept-Ranges'] = 'bytes'
      pdf.gsub!(/releases\/\d+/, "current")
      response.headers['X-Sendfile'] = pdf
      send_file pdf
    else
      # This really should *never* happen, but might if the pdf wasn't unpacked right...
      # Consider this an error. We don't want to go through ActiveFedora for this.
      Rails.logger.error("[PDF EBOOK ERROR] The pdf_ebook #{pdf} is not in the derivative directory!!!!")
      response.headers['Content-Length'] = pdf_ebook.file_size.to_s
      # Prevent Rack::ETag from calculating a digest over body with a Last-Modified response header
      # any Solr document save will change this, see definition of browser_cache_breaker
      response.headers['Cache-Control'] = 'max-age=31536000, private'
      response.headers['Last-Modified'] = (pdf_ebook.last_modified || Time.now.utc).strftime("%a, %d %b %Y %T GMT")
      send_data pdf_ebook.content, filename: pdf_ebook.filename, type: "application/pdf", disposition: "inline"
    end
  end

  #
  # download
  #
  def download
    id = params[:id]
    pdf_ebook = Sighrax.from_noid(id)
    policy = PdfEbookPolicy.new(current_actor, pdf_ebook)
    policy.authorize! :show?

    press = Sighrax.press(pdf_ebook)
    press_policy = PressPolicy.new(actor, press)

    if press_policy.watermark_download?
      do_watermark_download(pdf_ebook)
    else
      redirect_to(hyrax.download_path(id))
      # do_download(pdf_ebook)
    end
  rescue StandardError => e
    Rails.logger.error "PdfEbooks#download raised #{e}"
    head :no_content
  end

  # def do_download(pdf_ebook)
  #   presenter = Sighrax.hyrax_presenter(pdf_ebook)
  #   CounterService.from(self, presenter).count(request: 1)
  #   self.status = 200
  #   send_file_headers! content_options.merge(disposition: disposition(presenter))
  #   response.headers['Content-Length'] ||= file.size.to_s
  #   response.headers['Last-Modified'] = asset.modified_date.utc.strftime("%a, %d %b %Y %T GMT")
  #   stream_body file.stream
  # end

  def do_watermark_download(pdf_ebook)
    presenter = Sighrax.hyrax_presenter(pdf_ebook)
    CounterService.from(self, presenter).count(request: 1)
    send_data watermark_pdf(pdf_ebook, pdf_ebook.filename), type: pdf_ebook.media_type, filename: pdf_ebook.filename
  end
end
