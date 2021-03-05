# frozen_string_literal: true

class FulcrumController < ApplicationController
  before_action :authenticate_user!

  def dashboard
    redirect_to action: :index, partials: :dashboard
  end

  def exec # rubocop:disable Metrics/CyclomaticComplexity
    case params[:cmd]
    when 'ingest'
      ExtractIngestJob.perform_later(params[:token], params[:base], params[:noid], params[:target])
    when 'unpack'
      UnpackJob.perform_now(params[:noid], params[:kind])
    when 'handle'
      case params[:job]
      when 'create'
        HandleCreateJob.perform_now(params[:noid])
      when 'delete'
        HandleDeleteJob.perform_now(params[:noid])
      when 'verify'
        HandleVerifyJob.perform_now(params[:noid])
      end
    when 'aptrust'
      case params[:job]
      when 'deposit'
        AptrustDepositJob.perform_now(params[:noid])
      when 'verify'
        AptrustVerifyJob.perform_now(params[:noid])
      end
    when 'migrate'
      MigrateMetadataJob.perform_later(params[:job], params[:noid])
    when 'recache_in_common_metadata'
      RecacheInCommonMetadataJob.perform_now
    when 'reindex'
      ReindexJob.perform_later(params[:noid])
    when 'reindex_everything'
      ReindexJob.perform_later('everything')
    when 'reindex_monographs'
      ReindexJob.perform_later('monographs')
    when 'reindex_file_sets'
      ReindexJob.perform_later('file_sets')
    end
    redirect_to action: :index, partials: :dashboard
  end

  def index # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    @partials = params[:partials]
    @individuals = []
    @institutions = []
    @publishers_stats = { presses: [], timestampe: Time.now.utc.to_s }
    if ['dashboard', 'licenses', 'products', 'components', 'individuals', 'institutions', 'publishers', 'users', 'tokens', 'logs', 'grants', 'monographs', 'resources', 'pages', 'reports', 'customize', 'settings', 'help', 'csv', 'jobs', 'refresh'].include? @partials
      if /dashboard/.match?(@partials)
        @individuals = Greensub::Individual.where("identifier like ? or name like ?", "%#{params['individual_filter']}%", "%#{params['individual_filter']}%").map { |individual| ["#{individual.identifier} (#{individual.name})", individual.id] }
        @institutions = Greensub::Institution.where("identifier like ? or name like ?", "%#{params['institution_filter']}%", "%#{params['institution_filter']}%").map { |institution| ["#{institution.identifier} (#{institution.name})", institution.id] }
      end
      if /publishers/.match?(@partials)
        begin
          @publishers_stats = YAML.load(File.read(publisher_stats_file)) || { presses: [], timestampe: Time.now.utc.to_s } # rubocop:disable Security/YAMLLoad
        rescue StandardError => e
          Rails.logger.error(e.message)
        end
      end
      if /refresh/.match?(@partials)
        publisher_stats
        return redirect_to action: :index, partials: :publishers
      end
      incognito(incognito_params(params)) if /incognito/i.match?(params['submit'] || '')
      render
    else
      render 'hyrax/base/unauthorized', status: :unauthorized
    end
  end

  def show
    @partials = params[:partials]
    if ['users'].include? @partials
      @identifier = Base64.urlsafe_decode64(params[:id])
      render
    else
      render 'hyrax/base/unauthorized', status: :unauthorized
    end
  end

  private

    def publisher_stats_file
      Rails.root.join('tmp', 'publisher_stats.yml')
    end

    def publisher_stats
      PublisherStatsJob.perform_now(publisher_stats_file.to_s)
    end

    def incognito_params(params)
      params.slice(:actor, :platform_admin, :ability_can, :action_permitted)
    end

    def incognito(options) # rubocop:disable Metrics/CyclomaticComplexity
      Incognito.reset(current_actor)
      options.each do |key, _value|
        case key
        when 'actor'
          Incognito.sudo_actor(current_actor, true, params[:individual_id] || 0, params[:institution_id] || 0)
        when 'platform_admin'
          Incognito.allow_platform_admin(current_actor, false)
        when 'ability_can'
          Incognito.allow_ability_can(current_actor, false)
        when 'action_permitted'
          Incognito.allow_action_permitted(current_actor, false)
        end
      end
    end
end
