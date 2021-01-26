use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Mediainfo;

# Test.
my $obj = Wikibase::Datatype::Mediainfo->new;
my $ret = $obj->lastrevid;
is($ret, undef, 'Without last revision id.');
