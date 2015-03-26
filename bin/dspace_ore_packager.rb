#!/usr/bin/env ruby -rubygems
$:.unshift(File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib')))
require 'dspace_ore_packager'

DspaceOrePackager::Base.new().doPackage(ARGV[0])