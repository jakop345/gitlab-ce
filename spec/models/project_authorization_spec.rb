require 'spec_helper'

describe ProjectAuthorization do
  let(:user) { create(:user) }
  let(:project) { create(:empty_project) }

  describe '.insert_authorizations' do
    it 'inserts the authorizations' do
      described_class.
        insert_authorizations([[user.id, project.id, Gitlab::Access::MASTER]])

      expect(user.project_authorizations.count).to eq(1)
    end
  end
end
