Given(/^The course ([A-Z]+) (\d+) has (\d+) reviews$/) do |dept, course_num, review_count|
  course = Course.where(department: dept, course_number: course_num.to_i).first ||
           FactoryGirl.create(:course, department: dept, course_number: course_num.to_i)
  count_diff = course.reviews.count - review_count.to_i
  if count_diff < 0
    FactoryGirl.create_list(:review, count_diff.abs, course: course)
  elsif count_diff > 0
    Review.where(course: course).limit(count_diff).destroy_all
  end
  expect(course.reload.reviews.count).to eq review_count.to_i
end

Given(/^The course ([A-Z]+) (\d+) has a review with helpfulness (\d+)$/) do |dept, course_num, helpfulness|
  helpfulness = helpfulness.to_i
  course = Course.where(department: dept, course_number: course_num.to_i).first ||
           FactoryGirl.create(:course, department: dept, course_number: course_num.to_i)
  course.reviews.destroy_all
  @review = FactoryGirl.create(:review, course: course)
  FactoryGirl.create_list(:review_vote, helpfulness, review: @review, score: helpfulness < 0 ? -1 : 1)
  course.reload
  expect(course.reviews.count).to eq 1
  expect(course.reviews.first.helpfulness).to eq helpfulness
end

Given(/^I have already upvoted that review$/) do
  # This has the unfortunate side-effect of changing the helpfulness of the
  # review, which breaks expectations in other parts of the tests. So, we
  # need to do some extra to make sure the helpfulness is held constant for the
  # review.
  helpfulness = @review.helpfulness
  vote = ReviewVote.where(review: @review, user: @current_user).first ||
         FactoryGirl.create(:review_vote, review: @review, user: @current_user, score: 1)
  vote.update_attributes(score: 1) unless vote.score == 1
  @review.reload
  if @review.helpfulness > helpfulness
    FactoryGirl.create_list(:review_vote, @review.helpfulness - helpfulness, review: @review, score: -1)
  end
end

Given(/^I have already downvoted that review$/) do
  # See the comment in the block for "I've already upvoted ..."
  helpfulness = @review.helpfulness
  vote = ReviewVote.where(review: @review, user: @current_user).first ||
         FactoryGirl.create(:review_vote, review: @review, user: @current_user, score: -1)
  vote.update_attributes(score: -1) unless vote.score == -1
  @review.reload
  if @review.helpfulness < helpfulness
    FactoryGirl.create_list(:review_vote, helpfulness - @review.helpfulness, review: @review, score: 1)
  end
end

When(/^I click the (.*) button for that review$/) do |button_class|
  within('#reviews') do
    find(".#{button_class}").click
  end
end

When(/^I select a professor from the dropdown$/) do
  options = page.all('#review_professor_id option')
  option = options.sample
  @professor = Professor.find(option.value)
  select option.text, from: 'review_professor_id'
end

Then(/^I should see that review$/) do
  @review = Review.where(user: @current_user,
                         course: @course,
                         professor: @professor,
                         body: @text).first
  expect(page.find('#reviews')).to have_content @review.body
end

Then(/^That review should have helpfulness (\d+)$/) do |helpfulness|
  expect(@review.reload.helpfulness).to eq helpfulness.to_i
  within('#reviews') do
    expect(find('span.helpfulness').text).to eq helpfulness
  end
end

Then(/^I should see (\d+) reviews$/) do |count|
  reviews = page.all('#reviews .review')
  expect(reviews.count).to eq count.to_i
end

Then(/^The reviews should be ordered by helpfulness$/) do
  reviews = page.all('#reviews .review')
  reviews.each_with_index do |review_row, index|
    if reviews[index + 1]
      expect(review_row.find('span.helpfulness').text.to_i).to be >=
        reviews[index + 1].find('span.helpfulness').text.to_i
    end
  end
end
