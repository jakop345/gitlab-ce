class ChangeSlackServiceToSlackNotificationService < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = true
  DOWNTIME_REASON = 'Rename SlackService to SlackNotificationsService'

  def up
    execute("UPDATE services SET type = 'SlackNotificationsService' WHERE type = 'SlackService'")
  end

  def down
    execute("UPDATE services SET type = 'SlackService' WHERE type = 'SlackNotificationsService'")
  end
end
