#!/usr/bin/perl

# basic tests to see if things compile and are imported okay.

use strict;

use Test::More tests => 10;

use_ok "Test::utf8";
ok(defined(&is_valid_string),        "is_valid_string imported");
ok(defined(&is_sane_utf8),           "is_sane_utf8 imported");
ok(defined(&is_dodgy_utf8),          "is_dodgy_utf8 imported");
ok(defined(&is_within_ascii),        "is_within_ascii imported");
ok(defined(&is_within_latin_1),      "is_within_latin_1 imported");
ok(defined(&is_within_latin1),       "is_within_latin1 imported");
ok(defined(&is_flagged_utf8),        "is_flagged_utf8 imported");
ok(defined(&isnt_flagged_utf8),      "isnt_flagged_utf8 imported");
ok(defined(&isn't_flagged_utf8),     "isn't_flagged_utf8 imported");
