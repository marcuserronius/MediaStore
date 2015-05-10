# tag.rb
# A library to interface with the "tag" utility on a mac.
# The "tag" util can be installed using homebrew:
#   brew install tag
# note that some methods will fail if there are null characters in the
# filename. if it becomes a problem, this could either be changed to
# newline delimiter, or it could be called twice, once with each
# delimiter, and the result could be reliably parsed from that.
# perhaps I'll add this as an option at a later time.

# Since "Tag" is a fairly generic name, we'll put it in a submodule hierarchy.
module OSX; module Filesystem; end; end


module OSX::Filesystem::Tag
  TAG = "/usr/local/bin/tag"
  extend self

  # add tags to file
  def add(tags, file)
    call('-a', syms2tags(tags), file)
  end

  # remove given tags from file
  def remove(tags, file)
    call('-r', syms2tags(tags), file)
  end

  # set the tags for this file
  def set(tags, file)
    call('-s', syms2tags(tags), file)
  end

  # list all tags for this file
  def list(file)
    tags2syms call('-Nl', file)
  end

  # filter list of files to only those with matching tags
  def match(tags, files)
    call('-0m', syms2tags(tags), *files).split(?\0)
  end

  # find all files on this system matching given tags.
  # if given, a domain will set the scope of the search to either the
  # entire network (:network), just the user's home directory (:home),
  # or the default: the local filesystem (:local)
  def find(tags, domain=:local)
    dom = [{:home=>"-H", :local=>"-L", :network=>"-R"}[domain]]
    call('-0f', *dom, syms2tags(tags) ).split(?\0)
  end

  def call(*args)
    require 'open3'
    Open3.capture2(TAG,*args).chomp
  end

  # convert an array of symbols to a comma separated string
  def syms2tags(syms)
    syms.inject(){|a,b|"#{a},#{b}"}.to_s # to_s fixes single/null element arrays
  end

  # convert from comma separated string to symbols
  def tags2syms(tags)
    tags.split(",").map &:to_sym
  end
end