#!/bin/env ruby
# frozen_string_literal: true

require 'csv'
require 'pry'
require 'scraped'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class Riigikogu
  # details for an individual member
  class Member < Scraped::HTML
    field :id do
      url.split('/').last(2).first
    end

    field :name do
      noko.css('h3').text.tidy
    end

    field :url do
      noko.css('h3 a/@href').text
    end

    field :faktion do
      noko.css('li')[1].text.tidy
    end

    field :komisjon do
      noko.css('li')[2].text.tidy
    end
  end

  # The page listing all the members
  class Members < Scraped::HTML
    field :members do
      noko.css('ul.profile-list li.item').map { |mp| fragment(mp => Member).to_h }
    end
  end
end

url = 'https://www.riigikogu.ee/riigikogu/koosseis/riigikogu-liikmed/'
data = Riigikogu::Members.new(response: Scraped::Request.new(url: url).response).members

header = data.first.keys.to_csv
rows = data.map { |row| row.values.to_csv }
puts header + rows.join
