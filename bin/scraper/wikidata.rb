#!/bin/env ruby
# frozen_string_literal: true

require 'every_politician_scraper/wikidata_query'

query = <<SPARQL
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

puts EveryPoliticianScraper::WikidataQuery.new(query, 'every-politican-scrapers/estonia-riigikogu').csv
