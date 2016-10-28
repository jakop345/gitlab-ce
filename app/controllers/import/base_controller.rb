class Import::BaseController < ApplicationController
  private

  def find_or_create_namespace
    name = params[:target_namespace]

    return current_user.namespace if name == current_user.namespace_path

    owned_namespace = current_user.owned_groups.find_by(path: name)
    return owned_namespace if owned_namespace

    return current_user.namespace unless current_user.can_create_group?

    begin
      namespace = Group.create!(name: name, path: name, owner: current_user)
      namespace.add_owner(current_user)
      namespace
    rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
      current_user.namespace
    end
  end
end
