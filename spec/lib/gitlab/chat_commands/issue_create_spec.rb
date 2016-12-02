require 'spec_helper'

describe Gitlab::ChatCommands::IssueCreate, service: true do
  describe '#execute' do
    let(:project) { create(:empty_project) }
    let(:user) { create(:user) }
    let(:regex_match) { described_class.match("issue create bird is the word") }

    before do
      project.team << [user, :master]
    end

    subject do
      described_class.new(project, user).execute(regex_match)
    end

    context 'without description' do
      it 'creates the issue' do
        expect { subject }.to change { project.issues.count }.by(1)

        expect(subject[:response_type]).to be(:in_channel)
        expect(subject).to have_key(:attachments)
      end
    end

    context 'with description' do
      let(:description) { "Surfin bird" }
      let(:regex_match) { described_class.match("issue create bird is the word\n#{description}") }

      it 'creates the issue with description' do
        subject

        expect(Issue.last.description).to eq(description)
      end
    end

    context "with more newlines between the title and the description" do
      let(:description) { "Surfin bird" }
      let(:regex_match) { described_class.match("issue create bird is the word\n\n#{description}\n") }

      it 'creates the issue' do
        expect { subject }.to change { project.issues.count }.by(1)
      end
    end
  end

  describe '.match' do
    it 'matches the title without description' do
      match = described_class.match("issue create my title")

      expect(match[:title]).to eq('my title')
      expect(match[:description]).to eq("")
    end

    it 'matches the title with description' do
      match = described_class.match("issue create my title\n\ndescription")

      expect(match[:title]).to eq('my title')
      expect(match[:description]).to eq('description')
    end
  end
end
