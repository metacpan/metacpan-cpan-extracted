use strict;
use WebService::KoreanSpeller;
use Encode qw/decode/;
use Test::More tests => 1;

use utf8;

my $checker = WebService::KoreanSpeller->new( text => '안뇽하세요' );
my @results = $checker->spellcheck;

is( $results[0]->{correct}, '안녕하세요' );
