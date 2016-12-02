module Gitlab
  module ChatCommands
    class Command < BaseCommand

      COMMANDS = [
        Gitlab::ChatCommands::IssueShow,
        Gitlab::ChatCommands::IssueCreate,
        Gitlab::ChatCommands::IssueSearch,
        Gitlab::ChatCommands::Deploy,
      ].freeze

      def execute
        command, match = match_command

        if command
          if command.allowed?(project, current_user)
            command.new(project, current_user, params).execute(match)
          else
            Gitlab::ChatCommands::Presenters::Command.new(match).access_denied
          end
        else
          Gitlab::ChatCommands::Presenters::Command.
            new(match).
            help(available_commands, params[:command])
        end
      end

      # Not private because of now its testable
      def match_command
        match = nil
        service =
          available_commands.find do |klass|
            match = klass.match(params[:text])
          end

        [service, match]
      end

      private

      def available_commands
        @available_commands ||=
          COMMANDS.select do |klass|
            klass.available?(project)
          end
      end
    end
  end
end
