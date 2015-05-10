#!/usr/bin/env ruby
# show_info
# provides a simple access to the name of a season for a tv show
require 'yaml/store'

module ShowInfo
  extend self
  YAML_FILE = File.expand_path("~/.show_info_db.yaml")
  DATA = YAML::Store.new YAML_FILE

  # if not set, show_title becomes show, and label becomes
  # "#{type} #{season}#{season_title? " - "+season_title : ""}" (probably like "Season 1")
  def set(show, season=nil, type:nil, show_title:nil, season_title:nil, label:nil)

    DATA.transaction do
      DATA[show] ||= {}
      DATA[show][:title] = show_title || DATA[show][:title]
      DATA[show][:type] = type || DATA[show][:type]

      if season
        DATA[show][:seasons]  ||= {}
        s = ((DATA[show][:seasons][season] ||= {}))
        s[:title] = season_title || s[:title]
        s[:label] = label || s[:label]
      end
    end
  end

  # fetch the information
  def get(show, season=nil)
    if season
      show_ = DATA.transaction do
        DATA[show]
      end
      data = show_ && show_[:seasons] && show_[:seasons][season] || {}
      data[:type]  ||= show_ && show_[:type] || "Season"
      data[:label] ||= "#{data[:type]} #{season}#{data[:title] ? ": "+data[:title] : ""}"
      data
    else
      DATA.transaction do
        { title: ( ( DATA[show]||{} )[:title]||show ).dup,
          type: ( ( DATA[show]||{} )[:type]||"Season" ).dup }
      end
    end
  end
  # searches for the tvdb name of the show based on the on-disk name.
  # if not found, returns the name passed.
  def find(show)
    DATA.transaction do
      DATA.roots.find do |root|
        DATA[root][:title].to_s.downcase == show.downcase
      end
    end || show
  end
end
