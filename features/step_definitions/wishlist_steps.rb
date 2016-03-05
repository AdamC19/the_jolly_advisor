Given(/^I have a course in my wishlist$/) do
  @wishlist_item = WishlistItem.where(user: @current_user).first ||
    FactoryGirl.create(:wishlist_item, user: @current_user)
  @course = @wishlist_item.course
end

Given(/^I have notifications turned (on|off) for that course$/) do |m|
  status = m == 'on'
  @wishlist_item.update_attributes!(notify: status)
end

When(/^I view my wishlist$/) do
  step 'I visit "/wishlist"'
end

When(/^I select a course via wishlist search$/) do
  @course = Course.first || FactoryGirl.create(:course)
  step "I fill in \"course_title\" with \"#{@course.to_param}\""
  step 'I click the hidden button "#submit"'
end

When(/^I add it to my wishlist$/) do
  step 'I click the link "Add to my wishlist"'
end

When(/^I remove it from my wishlist$/) do
  step 'I click the link "Remove from my wishlist"'
end

When(/^I turn (on|off) notifications$/) do |m|
  step "I click the link \"Turn #{m} notifications\""
end

Then(/^I should(?: (not))? see that course in my wishlist$/) do |m|
  if m == "not"
    expect(page).to_not have_content(@course)
  else
    expect(page).to have_content(@course)
  end
end

Then(/^I should have notifications turned (on|off) for that course$/) do |m|
  status = m == 'on'
  expect(@wishlist_item.reload.notify).to eq status
end
