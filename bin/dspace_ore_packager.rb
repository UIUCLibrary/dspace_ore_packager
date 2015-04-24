#!/usr/bin/env ruby -rubygems
$:.unshift(File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib')))
require 'dspace_ore_packager'

#Provide the file path of the ORE file in first argument
DspaceOrePackager::Base.new().doPackage(ARGV[0])