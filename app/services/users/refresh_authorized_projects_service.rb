module Users
  # Service for refreshing the authorized projects of a user.
  #
  # This particular service class can not be used to update data for the same
  # user concurrently. Doing so could lead to an incorrect state. To ensure this
  # doesn't happen a caller must synchronize access (e.g. using
  # `Gitlab::ExclusiveLease`).
  #
  # Usage:
  #
  #     user = User.find_by(username: 'alice')
  #     service = Users::RefreshAuthorizedProjectsService.new(some_user)
  #     service.execute
  class RefreshAuthorizedProjectsService
    attr_reader :user

    # user - The User for which to refresh the authorized projects.
    def initialize(user)
      @user = user
    end

    def execute
      current = current_authorizations_per_project
      fresh = fresh_access_levels_per_project

      remove = current.each_with_object([]) do |(project_id, row), array|
        # rows not in the new list or with a different access level should be
        # removed.
        if !fresh[project_id] || fresh[project_id] != row.access_level
          array << row.id
        end
      end

      add = fresh.each_with_object([]) do |(project_id, level), array|
        # rows not in the old list or with a different access level should be
        # added.
        if !current[project_id] || current[project_id].access_level != level
          array << [user.id, project_id, level]
        end
      end

      update_authorizations(remove, add)
    end

    # Updates the list of authorizations for the current user.
    #
    # remove - The IDs of the authorization rows to remove.
    # add - Rows to insert in the form `[user id, project id, access level]`
    def update_authorizations(remove = [], add = [])
      return if remove.empty? && add.empty?

      User.transaction do
        user.remove_project_authorizations(remove) unless remove.empty?
        ProjectAuthorization.insert_authorizations(add) unless add.empty?
        user.set_authorized_projects_column
      end
    end

    def fresh_access_levels_per_project
      fresh_authorizations.each_with_object({}) do |row, hash|
        hash[row.project_id] = row.access_level
      end
    end

    def current_authorizations_per_project
      current_authorizations.each_with_object({}) do |row, hash|
        hash[row.project_id] = row
      end
    end

    def current_authorizations
      user.project_authorizations.select(:id, :project_id, :access_level)
    end

    def fresh_authorizations
      ProjectAuthorization.
        unscoped.
        from("(#{project_authorizations_union.to_sql}) #{ProjectAuthorization.table_name}").
        select(:project_id, :access_level)
    end

    private

    # Returns a union query of projects that the user is authorized to access
    def project_authorizations_union
      relations = [
        user.personal_projects.select("#{user.id} AS user_id, projects.id AS project_id, #{Gitlab::Access::MASTER} AS access_level"),
        user.groups_projects.select_for_project_authorization,
        user.projects.select_for_project_authorization,
        user.groups.joins(:shared_projects).select_for_project_authorization
      ]

      Gitlab::SQL::Union.new(relations)
    end
  end
end
