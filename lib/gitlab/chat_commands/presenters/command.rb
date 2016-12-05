module Gitlab::ChatCommands::Presenters
  class Command < BasePresenter
    def access_denied
      ephemeral_response(text: "Whoops! This action is not allowed. This incident will be [reported](https://xkcd.com/838/).")
    end
  end
end
