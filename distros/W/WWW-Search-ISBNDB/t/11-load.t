use strict;
use Test::More tests => 3;

use_ok('WWW::Search');
use_ok('WWW::Search::ISBNDB');

my $search = WWW::Search->new('ISBNDB');
ok($search, 'WWW::Search::ISBNDB');
