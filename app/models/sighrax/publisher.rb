# frozen_string_literal: true

module Sighrax
  class Publisher
    private_class_method :new

    attr_reader :subdomain
    attr_reader :press

    # Class Methods

    def self.null_publisher(subdomain = 'null_subdomain')
      subdomain = 'null_subdomain' if subdomain.blank?
      NullPublisher.send(:new, subdomain)
    end

    def self.from_subdomain(subdomain)
      press = Press.find_by(subdomain: subdomain)
      return self.null_publisher(subdomain) if press.blank?
      self.send(:new, subdomain, press)
    end

    def self.from_press(press)
      return self.null_publisher unless press.present? && press.is_a?(Press)
      self.send(:new, press.subdomain, press)
    end

    # Instance Methods

    def valid?
      !instance_of?(NullPublisher)
    end

    def resource_type
      type
    end

    def resource_id
      subdomain
    end

    def resource_token
      resource_type.to_s + ':' + resource_id.to_s
    end

    def parent
      return self.class.null_publisher unless press.present? && press.parent.present?
      self.class.from_press(press.parent)
    end

    def children
      return [] if press.blank? || press.children.blank?
      children = []
      press.children.each do |child|
        children << self.class.from_press(child)
      end
      children
    end

    def work_noids(recursive = false)
      subdomains = recursive ? press.children.pluck(:subdomain) : []
      subdomains = subdomains.push(subdomain).uniq
      docs = ActiveFedora::SolrService.query("{!terms f=press_sim}#{subdomains.map(&:downcase).join(',')}", fl: ['id'], rows: 100_000)
      docs.map { |doc| doc['id'] }.uniq
    end

    def resource_noids(recursive = false)
      resource_noids = []
      work_noids(recursive).each do |noid|
        docs = ActiveFedora::SolrService.query("{!terms f=id}#{noid}", fl: ['id', Solrizer.solr_name('ordered_member_ids', :symbol)], rows: 1)
        resource_noids += (docs[0][Solrizer.solr_name('ordered_member_ids', :symbol)] || []) if docs.present?
      end
      resource_noids.uniq
    end

    def user_ids(recursive = false)
      press_ids = recursive ? press.children.pluck(:id) : []
      press_ids = press_ids.push(press.id).uniq
      User.joins("INNER JOIN roles ON roles.user_id = users.id AND roles.resource_id IN (#{press_ids.join(', ')}) AND roles.resource_type = 'Press'").map(&:id)
    end

    def ==(other)
      return false unless other.present? && subdomain == other.subdomain
      press == other.press
    end

    protected

      def type
        @type ||= /^Sighrax::(.+$)/.match(self.class.to_s)[1].to_sym
      end

    private

      def initialize(subdomain, press)
        @subdomain = subdomain
        @press = press
      end
  end
end
