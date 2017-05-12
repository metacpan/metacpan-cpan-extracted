use strict;
use Test::More tests => 2;

use_ok("WWW::Search");

my $search = WWW::Search->new('UrbanDictionary');
ok($search, "WWW::Search::UrbanDictionary Loaded");
