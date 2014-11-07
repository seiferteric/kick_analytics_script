#!/usr/bin/ruby

require 'kickscraper'
require 'open-uri'
require 'nokogiri'
require 'csv'
require 'ruby-progressbar'
SEARCH_TERMS = 'tabletop games'
PROJECT_LIMIT = nil

start_time = Time.now
client = Kickscraper.client
projects = []
page_num = 1
loop do 
  puts "Getting Page #{page_num}"
  page_projs = client.search_projects(SEARCH_TERMS, page_num)
  projects.concat page_projs
  break if page_projs.count == 0
  break if PROJECT_LIMIT and projects.count >= PROJECT_LIMIT
  page_num += 1
end
projects.pop(projects.count - PROJECT_LIMIT) if PROJECT_LIMIT and projects.count > PROJECT_LIMIT
puts "Found #{projects.count} projects"

CSV.open("report.csv", "wb") do |csv|
  csv << ["ID", "Name", "State", "Country", "Currency", "Launch Date", "Deadline", "Created At", "Category", "Location", "Backers", "Goal", "Pledged", "# of Rewards"]
  prog = ProgressBar.create(:total => projects.count, :title => "Rewards")
  projects.each do |project|
    begin
      doc = Nokogiri::HTML(open(project.urls.web.rewards))
    rescue
      puts "Failed to get rewards info for project id #{project.id} with URL: #{project.urls.web.rewards} SKIPPING"
      next
    end
    rewards = doc.css("span.money").map(&:text)
    num_backers = doc.css("span.num-backers").map(&:text).map do |s| s.strip end
    row = [project.id, project.name, project.state, project.country, project.currency, Time.at(project.launched_at), Time.at(project.deadline), Time.at(project.created_at), project.category, project.location.displayable_name, project.backers_count, project.goal, project.pledged, rewards.count]
    rewards.zip(num_backers).each do |r, b|
      row << "#{r} : #{b}"
    end
    csv << row
    prog.increment
  end
end
stop_time = Time.now
puts "Run time was #{stop_time - start_time} seconds"
