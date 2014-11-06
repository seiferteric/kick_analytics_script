#!/usr/bin/ruby

require 'kickscraper'
require 'open-uri'
require 'nokogiri'
require 'csv'

PROJECT_LIMIT = 100

client = Kickscraper.client
projects = []
page_num = 1
loop do 
  page_projs = client.search_projects('board game', page_num)
  projects.concat page_projs
  break if projects.count >= PROJECT_LIMIT or page_projs.count == 0
  page_num += 1
end

CSV.open("report.csv", "wb") do |csv|
  csv << ["ID", "Name", "State", "Launch Date", "Category", "Goal", "Pledged", "# of Rewards"]
  projects.each do |project|
    
    doc = Nokogiri::HTML(open(project.urls.web.rewards))
    rewards = doc.css("span.money").map(&:text)
    num_backers = doc.css("span.num-backers").map(&:text).map do |s| s.strip end
    row = [project.id, project.name, project.state, Time.at(project.launched_at), project.category, project.goal, project.pledged, rewards.count]
    rewards.zip(num_backers).each do |r, b|
      row << "#{r} : #{b}"
    end
    csv << row
  end
end
