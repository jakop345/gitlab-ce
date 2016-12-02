module Gitlab
  module ChatCommands
    class IssueCreate < IssueCommand
      def self.match(text)
        # we can not match \n with the dot by passing the m modifier as than
        # the title and description are not seperated
        /\Aissue\s+create\s+(?<title>[^\n]*)\n*(?<description>(.|\n)*)/.match(text)
      end

      def self.help_message
        'issue create <title>\n<description>'
      end

      def self.allowed?(project, user)
        can?(user, :create_issue, project)
      end

      def execute(match)
        title = match[:title]
        description = match[:description].to_s.rstrip

        issue = create_issue(title: title, description: description)
        Gitlab::ChatCommands::Presenters::NewIssue.new(issue).execute
      end

      def create_issue(title:, description:)
        Issues::CreateService.new(project, current_user, title: title, description: description).execute
      end
    end
  end
end
