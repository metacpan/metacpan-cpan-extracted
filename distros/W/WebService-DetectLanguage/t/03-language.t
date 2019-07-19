#!perl

use strict;
use warnings;

use Test::More 0.88 tests => 1;
use WebService::DetectLanguage::Language;

my $language = WebService::DetectLanguage::Language->new(code => 'XYZ123');

is($language->name, "UNKNOWN",
   "Unknown language code should have name UNKNOWN");
