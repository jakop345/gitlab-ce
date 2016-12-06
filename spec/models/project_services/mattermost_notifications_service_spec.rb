require 'spec_helper'

describe MattermostNotificationsService, models: true do
  it_behaves_like "slack or mattermost"
end
