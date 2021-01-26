use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Mediainfo;

# Test.
my $obj = Wikibase::Datatype::Mediainfo->new;
my $ret = $obj->title;
is($ret, undef, 'Without title.');
