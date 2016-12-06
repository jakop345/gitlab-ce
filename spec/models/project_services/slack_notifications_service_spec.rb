require 'spec_helper'

describe SlackNotificationsService, models: true do
  it_behaves_like "slack or mattermost"
end
