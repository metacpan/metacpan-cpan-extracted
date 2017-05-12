use strict;
use warnings;
use Test::More;
use t::lib::Harness qw(constructor_io skip_unless_has_keys);

skip_unless_has_keys;

plan tests => 3;

ok constructor_io->track_search(term => "item"), "Successfully tracked a search";
ok constructor_io->track_click_through(term => "item", autocomplete_section =>
  "standard"), "Successfully tracked a click through";
ok constructor_io->track_conversion(term => "item", autocomplete_section =>
  "standard"), "Successfully tracked a conversion";
