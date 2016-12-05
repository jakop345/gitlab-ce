module API
  class Services < Grape::API
    services = {
      'asana' => [
        {
          required: true,
          name: :api_key,
          type: String,
          desc: 'User API token'
        },
        {
          required: false,
          name: :restrict_to_branch,
          type: String,
          desc: 'Comma-separated list of branches which will be automatically inspected. Leave blank to include all branches'
        },
      ],
      'assembla' => [
        {
          required: true,
          name: :token,
          type: String,
          desc: 'The authentication token'
        },
        {
          required: false,
          name: :subdomain,
          type: String,
          desc: 'Subdomain setting'
        }
      ]
    }

    trigger_services = {
      'mattermost-slash-commands' => 'foo'
    }

    services.each do |service_slug, settings|
      resource :projects do
        before { authenticate! }
        before { authorize_admin_project }

        desc "Set #{service_slug} service for project"
        params do
          settings.each do |setting|
            if setting[:required]
              requires setting[:name], type: setting[:type], desc: setting[:desc]
            else
              optional setting[:name], type: setting[:type], desc: setting[:desc]
            end
          end
        end
        put ":id/services/#{service_slug}" do
          service = user_project.find_or_initialize_service(service_slug.underscore)

          validators = service.class.validators.select do |s|
            s.class == ActiveRecord::Validations::PresenceValidator &&
              s.attributes != [:project_id]
          end

          service_params = declared_params(include_missing: false).merge(active: true)
          if service.update_attributes(service_params)
            true
          else
            not_found!
          end
        end


        desc "Delete #{service_slug} service for project"
        delete ":id/services/#{service_slug}" do
          service = user_project.find_or_initialize_service("#{service_slug}".underscore)

          attrs = service_attributes(service).inject({}) do |hash, key|
            hash.merge!(key => nil)
          end

          if service.update_attributes(attrs.merge(active: false))
            true
          else
            not_found!
          end
        end

        desc "Get #{service_slug} service settings for project"
        get ":id/services/#{service_slug}" do
          service = user_project.find_or_initialize_service(service_slug.underscore)
          present service, with: Entities::ProjectService, include_passwords: current_user.is_admin?
        end
      end
    end

    trigger_services.each do |service_slug, settings|
      resource :projects do
        desc "Trigger a slash command for #{service_slug}" do
          detail 'Added in GitLab 8.13'
        end
        post ":id/services/#{service_slug.underscore}/trigger" do
          project = find_project(params[:id])

          # This is not accurate, but done to prevent leakage of the project names
          not_found!('Service') unless project

          service = project.find_or_initialize_service(service_slug.underscore)

          result = service.try(:active?) && service.try(:trigger, params)

          if result
            status result[:status] || 200
            present result
          else
            not_found!('Service')
          end
        end
      end
    end
  end
end
