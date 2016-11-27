require 'spec_helper'

describe NotesFinder do
  let(:user) { create :user }
  let(:project) { create :project }
  let!(:note1) { create :note_on_commit, project: project }
  let!(:note2) { create :note_on_commit, project: project }
  let(:commit) { note1.noteable }
  subject { NotesFinder.new(project, user, params) }

  before do
    # project.team << [user, :master]
  end

  describe '#execute' do
    let(:params)  { { target_id: commit.id, target_type: 'commit', last_fetched_at: 1.hour.ago.to_i } }

    it 'finds all notes' do
      notes = subject.execute
      expect(notes.size).to eq(2)
    end

    it 'raises an exception for an invalid target_type' do
      params.merge!(target_type: 'invalid')
      expect { subject.execute }.to raise_error('invalid target_type')
    end

    it 'filters out old notes' do
      note2.update_attribute(:updated_at, 2.hours.ago)
      notes = subject.execute
      expect(notes).to eq([note1])
    end

    context 'confidential issue notes' do
      let(:confidential_issue) { create(:issue, :confidential, project: project) }
      let!(:confidential_note) { create(:note, noteable: confidential_issue, project: confidential_issue.project) }

      let(:params) { { target_id: confidential_issue.id, target_type: 'issue', last_fetched_at: 1.hour.ago.to_i } }

      context 'when user is the author of the issue' do
        before do
          confidential_issue.update(author: user)
        end

        it 'returns confidential notes' do
          expect(subject.execute).to eq([confidential_note])
        end
      end

      context 'when user is a master on the team' do
        before do
          project.team << [user, :master]
        end

        it 'returns confidential notes' do
          expect(subject.execute).to eq([confidential_note])
        end
      end

      context 'when user is a guest on the team' do
        before do
          project.team << [user, :guest]
        end

        it 'raises an error' do
          expect { subject.execute }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context 'when user is not a member of the team' do
        it 'raises an error if user can not see the issue' do
          expect { subject.execute }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end
end
