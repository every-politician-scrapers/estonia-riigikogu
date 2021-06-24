#!/bin/env ruby
# frozen_string_literal: true

require 'cgi'
require 'csv'
require 'scraped'

class Results < Scraped::JSON
  field :members do
    json[:results][:bindings].map { |result| fragment(result => Member).to_h }
  end
end

class Member < Scraped::JSON
  field :id do
    json.dig(:id, :value)
  end

  field :name do
    json.dig(:name, :value)
  end
end

# In this case it might make more sense to fetch as CSV and output it
# directly, but this way keeps it in sync with our normal approach, and
# allows us to more easily post-process if needed
WIKIDATA_SPARQL_URL = 'https://query.wikidata.org/sparql?format=json&query=%s'

memberships_query = <<SPARQL
  SELECT DISTINCT ?id ?name WHERE {
    # Current members of the Riigikogu
    ?item p:P39 ?ps .
    ?ps ps:P39 wd:Q61976148 .
    FILTER NOT EXISTS { ?ps pq:P582 [] }

    # A Riigikogu ID, and optional "named as"
    OPTIONAL {
      ?item p:P4287 ?idstatement .
      ?idstatement ps:P4287 ?id .
      OPTIONAL { ?idstatement pq:P1810 ?riigikoguName }
    }

    # Their on-wiki label as a fall-back if no Riigikogu name
    OPTIONAL { ?item rdfs:label ?etLabel FILTER(LANG(?etLabel) = "et") }
    BIND(COALESCE(?riigikoguName, ?etLabel) AS ?name)
  }
  ORDER BY ?name
SPARQL

url = WIKIDATA_SPARQL_URL % CGI.escape(memberships_query)
headers = { 'User-Agent' => 'every-politican-scrapers/estonia-riigikogu' }
data = Results.new(response: Scraped::Request.new(url: url, headers: headers).response).members

header = data.first.keys.to_csv
rows = data.map { |row| row.values.to_csv }
abort 'No results' if rows.count.zero?

puts header + rows.join
