# mediainfo interface
# Uses the mediainfo tool to get resolution, bitrate, etc. specs
#
# So, mediainfo returns a completely different set of keys and values
# depending on what file type it is. Understandable, but frustrating.
# This library will attempt to find the subset that can be made
# accessible by the same name and in the same format (ie, 128kbps vs
# 128000bps). Any that aren't supported but can be reliably
# calculated will have that done as well.

require 'rubygems'
require 'open3'     # for running command line tools
require 'nokogiri'  # for parsing the resulting xml

class MediaInfo

  # The default path to mediainfo
  PATH = "/usr/local/bin/mediainfo"

  # Change the default path
  def self.use_executable_at(path)
    PATH.replace(path)
  end
  
  # Creates a new MediaInfo object from the file at +path+
  def initialize(path)
    @path=path
    extend Generic
  end

  # Runs the command, parses/memoizes the results, returns an array
  def results
    @results ||= begin
      xml = Nokogiri::XML.parse(
        Open3.capture2(PATH, "--Output=XML", "--Language=raw", "--Full", @path).first
      )
      xml.css('track').map do |track|
        Track.new.tap do |t|
          t.track_type = track.attr 'type'
          t.track_id   = track.attr 'streamid'
          track.css('*').each do |el|
            t[el.name.to_sym] = el.text
          end
        end
      end
    end
  end



  # returns the video tracks
  def general
    results.select{|t|t.track_type == "General"}
  end

  # returns the video tracks
  def video
    results.select{|t|t.track_type == "Video"}
  end

  # returns the audio tracks
  def audio
    results.select{|t|t.track_type == "Audio"}
  end

  # nicer inspect
  def inspect
    %Q[#<#{self.class.name}:"#{File.basename(@path)}">]
  end

  # re-runs the command, reparses results
  def refresh
    @results = nil
    results
  end

  # add some attributes to a hash, to make it suitable
  class Track < Hash
    attr_accessor :track_type, :track_id
    def inspect
      %Q[#<#{self.class.name}:#{track_type}(#{track_id}):#{super}]
    end
  end

  module Generic
    def width;         video[0][:Width].to_i;         end
    def height;        video[0][:Height].to_i;        end
    def duration;    general[0][:Duration].to_f/1000; end # duration in seconds, usually to the ms
    def bitrate_video; video[0][:BitRate].to_i;       end

    def resolution
      case width
      when 0..340 # 320x240
        "240p"
      when 320..760 # 640/720x480
        "480p"
      when 760..1300 # 1280x720
        "720p"
      when 1300..1940 # 1920x1080
        "1080p"
      else
        "2k+"
      end
    end
  end


end