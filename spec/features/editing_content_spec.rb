require 'rails_helper'

RSpec.describe 'editing content', type: :feature do
  include ::NodesHelper

  Warden.test_mode!
  let!(:root_node) { Fabricate(:root_node) }
  let!(:section) { Fabricate(:section) }
  let!(:section_home) { Fabricate(:section_home, section: section) }
  let!(:author) { Fabricate(:user, author_of: section) }

  before :each do
    login_as(author, scope: :user)
  end

  after do
    logout(:user)
  end

  context 'on a node page' do
    let!(:node) { Fabricate(:general_content, parent: section_home) }

    it 'should show a link to edit the content in the CMS' do
      visit public_node_path(node)
      expect(page).to have_link('Edit')
    end

    context 'as a user with an open submission' do
      let(:user_b) { Fabricate(:user, author_of: section)}
      let(:revision) { Fabricate(:revision, revisable: node) }
      let!(:submission) { Fabricate(:submission, revision: revision, submitter: author)}

      it 'should show a link to view the existing submission' do
        visit public_node_path(node)
        expect(page).to have_link('View submission')
      end

      it 'should show an edit link for a user without an open submission' do
        logout(author)
        login_as(user_b)
        visit public_node_path(node)
        expect(page).to have_link('Edit')
      end
    end
  end

  context 'when editing content' do
    let!(:section1) { Fabricate(:section) }
    let!(:section_home1) { Fabricate(:section_home, section: section1) }
    let!(:section2) { Fabricate(:section) }
    let!(:section_home2) { Fabricate(:section_home, section: section2) }
    let!(:node1) { Fabricate(:general_content, state: 'published', parent: section_home1) }
    let!(:node2) { Fabricate(:news_article, state: 'published', parent: section_home2) }
    let!(:node3) { Fabricate(:custom_template_node, state: 'published', parent: section_home2) }

    before :each do
      author.add_role(:author, section1)
      author.add_role(:author, section2)
    end

    it 'should prefill the form' do
      [node1, node2, node3].each do |node|
        visit public_node_path(node)
        click_link 'Edit'
        expect(find_field('Body').value).to eq node.content_body
        expect(find_field('Name').value).to eq node.name
        expect(find_field('Short summary').value).to eq node.short_summary
        unless node.class == CustomTemplateNode
          expect(find_field('Long summary').value).to eq node.summary
        end
      end
    end

    context 'for a news article' do
      it 'should prefill the form' do
        visit public_node_path(node2)
        click_link 'Edit metadata'
        field = 'node_release_date'
        expect(find_field("#{field}_1i").value).to eq node2.release_date.year.to_s
        expect(find_field("#{field}_2i").value).to eq node2.release_date.month.to_s
        expect(find_field("#{field}_3i").value).to eq node2.release_date.day.to_s
      end
    end

    context 'creating a submission' do
      context 'with good content' do
        before do
          visit new_editorial_section_submission_path(node1.section, node_id: node1)
          fill_in 'Body', with: 'Brand new content'
          click_button 'Submit for review'
        end

        it 'should take the user to the created submission view' do
          expect(current_path).to match /editorial\/#{node1.section.id}\/submissions\/\d+/
        end

        it 'should not update the record directly' do
          visit "/#{node1.path}"
          expect(page).not_to have_content 'Brand new content'
        end
      end

      it_behaves_like 'robust to XSS' do
        before { visit new_editorial_section_submission_path(node1.section, node_id: node1) }
      end
      it_behaves_like 'robust to XSS' do
        before { visit new_editorial_section_submission_path(node2.section, node_id: node2) }
      end
    end
  end

end
