#!/usr/bin/env ruby
# cd t && ./scale.rb > scale.spec

require 'rubygems'
gem 'activesupport'
require 'activesupport'

[
'second',
'minute',
'hour',
'day',
'week',
'fortnight',
'month',
'year',
].each do |m|
  ep = "2->#{m}"
  er = "2.#{m}.to_i"
  printf "=== %s\n--- input: %s\n--- expected: %d\n\n", m, ep, eval(er)

  m = m+'s'
  ep = "3->#{m}"
  er = "3.#{m}.to_i"
  printf "=== %s\n--- input: %s\n--- expected: %d\n\n", m, ep, eval(er)
end

