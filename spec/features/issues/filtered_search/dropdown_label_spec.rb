require 'spec_helper'

describe 'Dropdown label', js: true, feature: true do
  let(:project) { create(:empty_project) }
  let(:user) { create(:user) }
  let(:filtered_search) { find('.filtered-search') }
  let(:js_dropdown_label) { '#js-dropdown-label' }
  let(:filter_dropdown) { find("#{js_dropdown_label} .filter-dropdown") }

  shared_context 'with labels' do
    let!(:bug_label) { create(:label, project: project, title: 'bug-label') }
    let!(:uppercase_label) { create(:label, project: project, title: 'BUG-LABEL') }
    let!(:two_words_label) { create(:label, project: project, title: 'High Priority') }
    let!(:wont_fix_label) { create(:label, project: project, title: 'Won"t Fix') }
    let!(:wont_fix_single_label) { create(:label, project: project, title: 'Won\'t Fix') }
    let!(:special_label) { create(:label, project: project, title: '!@#$%^+&*()') }
    let!(:long_label) { create(:label, project: project, title: 'this is a very long title this is a very long title this is a very long title this is a very long title this is a very long title') }
  end

  def init_label_search
    filtered_search.set('label:')
    # This ensures the dropdown is shown
    expect(find(js_dropdown_label)).not_to have_css('.filter-dropdown-loading')
  end

  def search_for_label(label)
    init_label_search
    filtered_search.send_keys(label)
  end

  def click_label(text)
    filter_dropdown.find('.filter-dropdown-item', text: text).click
  end

  def dropdown_label_size
    filter_dropdown.all('.filter-dropdown-item').size
  end

  def clear_search_field
    find('.filtered-search-input-container .clear-search').click
  end

  before do
    project.add_master(user)
    login_as(user)
    create(:issue, project: project)

    visit namespace_project_issues_path(project.namespace, project)
  end

  describe 'keyboard navigation' do
    it 'selects label' do
      bug_label = create(:label, project: project, title: 'bug-label')
      init_label_search

      filtered_search.native.send_keys(:down, :down, :enter)

      expect(filtered_search.value).to eq("label:~#{bug_label.title} ")
    end
  end

  describe 'behavior' do
    it 'opens when the search bar has label:' do
      filtered_search.set('label:')

      expect(page).to have_css(js_dropdown_label)
    end

    it 'closes when the search bar is unfocused' do
      find('body').click

      expect(page).not_to have_css(js_dropdown_label)
    end

    it 'shows loading indicator when opened and hides it when loaded' do
      filtered_search.set('label:')

      expect(find(js_dropdown_label)).to have_css('.filter-dropdown-loading')
      expect(find(js_dropdown_label)).not_to have_css('.filter-dropdown-loading')
    end

    it 'loads all the labels when opened' do
      bug_label = create(:label, project: project, title: 'bug-label')
      filtered_search.set('label:')

      expect(filter_dropdown).to have_content(bug_label.title)
      expect(dropdown_label_size).to eq(1)
    end
  end

  describe 'filtering' do
    include_context 'with labels'

    before do
      init_label_search
    end

    it 'filters by case-insensitive name with or without symbol' do
      search_for_label('b')

      expect(filter_dropdown.find('.filter-dropdown-item', text: bug_label.title)).to be_visible
      expect(filter_dropdown.find('.filter-dropdown-item', text: uppercase_label.title)).to be_visible
      expect(dropdown_label_size).to eq(2)

      clear_search_field
      init_label_search

      search_for_label('~bu')

      expect(filter_dropdown.find('.filter-dropdown-item', text: bug_label.title)).to be_visible
      expect(filter_dropdown.find('.filter-dropdown-item', text: uppercase_label.title)).to be_visible
      expect(dropdown_label_size).to eq(2)
    end

    it 'filters by multiple words with or without symbol' do
      filtered_search.send_keys('Hig')

      expect(filter_dropdown.find('.filter-dropdown-item', text: two_words_label.title)).to be_visible
      expect(dropdown_label_size).to eq(1)

      clear_search_field
      init_label_search

      filtered_search.send_keys('~Hig')

      expect(filter_dropdown.find('.filter-dropdown-item', text: two_words_label.title)).to be_visible
      expect(dropdown_label_size).to eq(1)
    end

    it 'filters by multiple words containing single quotes with or without symbol' do
      filtered_search.send_keys('won\'t')

      expect(filter_dropdown.find('.filter-dropdown-item', text: wont_fix_single_label.title)).to be_visible
      expect(dropdown_label_size).to eq(1)

      clear_search_field
      init_label_search

      filtered_search.send_keys('~won\'t')

      expect(filter_dropdown.find('.filter-dropdown-item', text: wont_fix_single_label.title)).to be_visible
      expect(dropdown_label_size).to eq(1)
    end

    it 'filters by multiple words containing double quotes with or without symbol' do
      filtered_search.send_keys('won"t')

      expect(filter_dropdown.find('.filter-dropdown-item', text: wont_fix_label.title)).to be_visible
      expect(dropdown_label_size).to eq(1)

      clear_search_field
      init_label_search

      filtered_search.send_keys('~won"t')

      expect(filter_dropdown.find('.filter-dropdown-item', text: wont_fix_label.title)).to be_visible
      expect(dropdown_label_size).to eq(1)
    end

    it 'filters by special characters with or without symbol' do
      filtered_search.send_keys('^+')

      expect(filter_dropdown.find('.filter-dropdown-item', text: special_label.title)).to be_visible
      expect(dropdown_label_size).to eq(1)

      clear_search_field
      init_label_search

      filtered_search.send_keys('~^+')

      expect(filter_dropdown.find('.filter-dropdown-item', text: special_label.title)).to be_visible
      expect(dropdown_label_size).to eq(1)
    end
  end

  describe 'selecting from dropdown' do
    include_context 'with labels'

    before do
      init_label_search
    end

    it 'fills in the label name when the label has not been filled' do
      click_label(bug_label.title)

      expect(page).not_to have_css(js_dropdown_label)
      expect(filtered_search.value).to eq("label:~#{bug_label.title} ")
    end

    it 'fills in the label name when the label is partially filled' do
      filtered_search.send_keys('bu')
      click_label(bug_label.title)

      expect(page).not_to have_css(js_dropdown_label)
      expect(filtered_search.value).to eq("label:~#{bug_label.title} ")
    end

    it 'fills in the label name that contains multiple words' do
      click_label(two_words_label.title)

      expect(page).not_to have_css(js_dropdown_label)
      expect(filtered_search.value).to eq("label:~\"#{two_words_label.title}\" ")
    end

    it 'fills in the label name that contains multiple words and is very long' do
      click_label(long_label.title)

      expect(page).not_to have_css(js_dropdown_label)
      expect(filtered_search.value).to eq("label:~\"#{long_label.title}\" ")
    end

    it 'fills in the label name that contains double quotes' do
      click_label(wont_fix_label.title)

      expect(page).not_to have_css(js_dropdown_label)
      expect(filtered_search.value).to eq("label:~'#{wont_fix_label.title}' ")
    end

    it 'fills in the label name with the correct capitalization' do
      click_label(uppercase_label.title)

      expect(page).not_to have_css(js_dropdown_label)
      expect(filtered_search.value).to eq("label:~#{uppercase_label.title} ")
    end

    it 'fills in the label name with special characters' do
      click_label(special_label.title)

      expect(page).not_to have_css(js_dropdown_label)
      expect(filtered_search.value).to eq("label:~#{special_label.title} ")
    end

    it 'selects `no label`' do
      find("#{js_dropdown_label} .filter-dropdown-item", text: 'No Label').click

      expect(page).not_to have_css(js_dropdown_label)
      expect(filtered_search.value).to eq("label:none ")
    end
  end

  describe 'input has existing content' do
    it 'opens label dropdown with existing search term' do
      filtered_search.set('searchTerm label:')

      expect(page).to have_css(js_dropdown_label)
    end

    it 'opens label dropdown with existing author' do
      filtered_search.set('author:@person label:')

      expect(page).to have_css(js_dropdown_label)
    end

    it 'opens label dropdown with existing assignee' do
      filtered_search.set('assignee:@person label:')

      expect(page).to have_css(js_dropdown_label)
    end

    it 'opens label dropdown with existing label' do
      filtered_search.set('label:~urgent label:')

      expect(page).to have_css(js_dropdown_label)
    end

    it 'opens label dropdown with existing milestone' do
      filtered_search.set('milestone:%v2.0 label:')

      expect(page).to have_css(js_dropdown_label)
    end
  end

  describe 'caching requests' do
    it 'caches requests after the first load' do
      create(:label, project: project, title: 'bug-label')
      init_label_search

      expect(dropdown_label_size).to eq(1)

      create(:label, project: project)
      clear_search_field
      init_label_search

      expect(dropdown_label_size).to eq(1)
    end
  end
end
