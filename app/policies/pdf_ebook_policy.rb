# frozen_string_literal: true

class PdfEbookPolicy < ResourcePolicy
  def initialize(actor, target, share = false)
    super(actor, target)
    @share = share
  end

  def show?
    @share || PdfEbookReaderOperation.new(actor, target).allowed?
  end
end
