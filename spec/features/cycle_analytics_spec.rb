require 'spec_helper'

feature 'Cycle Analytics', feature: true, js: true do
  include WaitForAjax

  let(:user) { create(:user) }
  let(:project) { create(:project) }
  
  before do 
    project.team << [user, :master]
    login_as(user)
  end

  context 'as an allowed user' do
    context 'when project is new' do
      before  do
        visit namespace_project_cycle_analytics_path(project.namespace, project)
      end

      it 'shows introductory message' do
        wait_for_ajax
        expect(page).to have_content('Introducing Cycle Analytics')
      end

      it 'shows active stage with empty message' do
        expect(page).to have_selector('.stage-nav-item.active', text: 'Issue')
        expect(page).to have_content("We don’t have enough data to show this stage.")
      end
    end

    context "when there's cycle analytics data" do
      let(:issue) { create :issue, project: project }

      before  do
        visit namespace_project_cycle_analytics_path(project.namespace, project)
      end

      context 'on Issue stage' do
        it 'shows issues on the events list' do
          expect(page).to have_content(issue.title)
        end
      end
    end
  end
end
