# Store object full path in separate table for easy lookup and uniq validation
# Object must have path db field and respond to full_path and full_path_changed? methods.
module Routable
  extend ActiveSupport::Concern

  included do
    has_one :route, as: :source, autosave: true, dependent: :destroy

    validates_associated :route
    validates :route, presence: true

    before_validation :update_route_path, if: :full_path_changed?
  end

  private

  def update_route_path
    route || build_route(source: self)
    route.path = full_path
  end
end
