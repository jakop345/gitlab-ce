require 'spec_helper'

describe Group, 'Routable' do
  let!(:group) { create(:group) }

  describe 'Associations' do
    it { is_expected.to have_one(:route).dependent(:destroy) }
  end

  describe 'Callbacks' do
    it 'creates route record on create' do
      expect(group.route.path).to eq(group.path)
    end

    it 'updates route record on path change' do
      group.update_attributes(path: 'wow')

      expect(group.route.path).to eq('wow')
    end

    it 'ensure route path uniqueness across different objects' do
      create(:group, parent: group, path: 'xyz')
      duplicate = build(:project, namespace: group, path: 'xyz')

      expect { duplicate.save! }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Route path has already been taken, Route is invalid')
    end
  end
end
