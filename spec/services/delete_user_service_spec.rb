require 'spec_helper'

describe DeleteUserService, services: true do
  describe "Deletes a user and all their personal projects" do
    let!(:user)         { create(:user) }
    let!(:current_user) { create(:user) }
    let!(:namespace)    { create(:namespace, owner: user) }
    let!(:project)      { create(:project, namespace: namespace) }

    context 'no options are given' do
      it 'deletes the user' do
        user_data = DeleteUserService.new(current_user).execute(user)

        expect { user_data['email'].to eq(user.email) }
        expect { User.find(user.id) }.to raise_error(ActiveRecord::RecordNotFound)
        expect { Namespace.with_deleted.find(user.namespace.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'will delete the project in the near future' do
        expect_any_instance_of(Projects::DestroyService).to receive(:async_execute).once

        DeleteUserService.new(current_user).execute(user)
      end
    end

    context "a deleted user's issues" do
      let(:project) { create :project }

      before { project.team << [user, :developer] }

      context "for an issue the user has created" do
        let!(:issue) { create(:issue, project: project, author: user) }

        before { DeleteUserService.new(current_user).execute(user) }

        it 'does not delete the issue' do
          expect(Issue.find_by_id(issue.id)).to be_present
        end

        it 'migrates the issue so that the "Ghost User" is the issue owner' do
          migrated_issue = Issue.find_by_id(issue.id)

          expect(migrated_issue.author).to eq(User.ghost)
        end
      end

      context "for an issue the user was assigned to" do
        let!(:issue) { create(:issue, project: project, assignee: user) }

        before { DeleteUserService.new(current_user).execute(user) }

        it 'does not delete issues the user is assigned to' do
          expect(Issue.find_by_id(issue.id)).to be_present
        end

        it 'migrates the issue so that it is "Unassigned"' do
          migrated_issue = Issue.find_by_id(issue.id)

          expect(migrated_issue.assignee).to be_nil
        end
      end
    end

    context "solo owned groups present" do
      let(:solo_owned)  { create(:group) }
      let(:member)      { create(:group_member) }
      let(:user)        { member.user }

      before do
        solo_owned.group_members = [member]
        DeleteUserService.new(current_user).execute(user)
      end

      it 'does not delete the user' do
        expect(User.find(user.id)).to eq user
      end
    end

    context "deletions with solo owned groups" do
      let(:solo_owned)      { create(:group) }
      let(:member)          { create(:group_member) }
      let(:user)            { member.user }

      before do
        solo_owned.group_members = [member]
        DeleteUserService.new(current_user).execute(user, delete_solo_owned_groups: true)
      end

      it 'deletes solo owned groups' do
        expect { Project.find(solo_owned.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'deletes the user' do
        expect { User.find(user.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
