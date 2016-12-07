require 'spec_helper'

feature 'Diff note avatars', feature: true, js: true do
  include WaitForAjax

  let(:user)          { create(:user) }
  let(:project)       { create(:project, :public) }
  let(:merge_request) { create(:merge_request_with_diffs, source_project: project, author: user, title: "Bug NS-04") }
  let(:path)          { "files/ruby/popen.rb" }
  let(:position) do
    Gitlab::Diff::Position.new(
      old_path: path,
      new_path: path,
      old_line: nil,
      new_line: 9,
      diff_refs: merge_request.diff_refs
    )
  end
  let!(:note) { create(:diff_note_on_merge_request, project: project, noteable: merge_request, position: position) }

  before do
    project.team << [user, :master]
    login_as user
  end

  ['inline', 'parallel'].each do |view|
    context "#{view} view" do
      before do
        visit diffs_namespace_project_merge_request_path(project.namespace, project, merge_request, view: view)

        wait_for_ajax
      end

      it 'shows note avatar' do
        page.within find("[id='#{position.line_code(project.repository)}']") do
          expect(page).to have_selector('img.js-diff-comment-avatar', count: 1)
        end
      end

      it 'shows comment on note avatar' do
        page.within find("[id='#{position.line_code(project.repository)}']") do
          expect(first('img.js-diff-comment-avatar')["title"]).to eq("#{note.author.name}: #{note.note.truncate(17)}")
        end
      end

      it 'toggles comments when clicking avatar' do
        page.within find("[id='#{position.line_code(project.repository)}']") do
          first('img.js-diff-comment-avatar').click
        end

        expect(page).to have_selector('.notes_holder', visible: false)

        page.within find("[id='#{position.line_code(project.repository)}']") do
          first('img.js-diff-comment-avatar').click
        end

        expect(page).to have_selector('.notes_holder')
      end

      it 'removes avatar when note is deleted' do
        page.within find(".note-row-#{note.id}") do
          find('.js-note-delete').click
        end

        wait_for_ajax

        page.within find("[id='#{position.line_code(project.repository)}']") do
          expect(page).not_to have_selector('img.js-diff-comment-avatar')
        end
      end

      it 'adds avatar when commenting' do
        click_button 'Reply...'

        page.within '.js-discussion-note-form' do
          find('.js-note-text').native.send_keys('Test')

          click_button 'Comment'

          wait_for_ajax
        end

        page.within find("[id='#{position.line_code(project.repository)}']") do
          expect(page).to have_selector('img.js-diff-comment-avatar', count: 2)
        end
      end

      it 'adds multiple comments' do
        3.times do
          click_button 'Reply...'

          page.within '.js-discussion-note-form' do
            find('.js-note-text').native.send_keys('Test')

            click_button 'Comment'

            wait_for_ajax
          end
        end

        page.within find("[id='#{position.line_code(project.repository)}']") do
          expect(page).to have_selector('img.js-diff-comment-avatar', count: 3)
          expect(find('.diff-comments-more-count')).to have_content '+1'
        end
      end

      context 'multiple comments' do
        before do
          create(:diff_note_on_merge_request, project: project, noteable: merge_request, position: position)
          create(:diff_note_on_merge_request, project: project, noteable: merge_request, position: position)
          create(:diff_note_on_merge_request, project: project, noteable: merge_request, position: position)

          visit diffs_namespace_project_merge_request_path(project.namespace, project, merge_request, view: view)

          wait_for_ajax
        end

        it 'shows extra comment count' do
          page.within find("[id='#{position.line_code(project.repository)}']") do
            expect(find('.diff-comments-more-count')).to have_content '+1'
          end
        end
      end
    end
  end
end