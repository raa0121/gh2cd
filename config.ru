require 'bundler'
Bundler.require

require './web'
$stdout.sync = true
run Gh2Cd
