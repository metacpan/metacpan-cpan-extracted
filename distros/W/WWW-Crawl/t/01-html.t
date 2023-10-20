#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use JSON::PP;

eval "use Test::Mock::HTTP::Tiny";

plan skip_all => "Skipping tests: Test::Mock::HTTP::Tiny not available!" if $@;

use WWW::Crawl;

plan tests => 4;

$/ = undef;
open my $fh, '<', 't/mock_html.dat' or BAIL_OUT("Can't open datafile");
my $replay = <$fh>;
close $fh;

$replay = eval { decode_json($replay) };

ok ( !$@, 'Parsed JSON' ) or BAIL_OUT($@);

is ( ref($replay), 'ARRAY', '$replay is an ARRAY ' );

BAIL_OUT("Nothing to replay") unless $replay;

Test::Mock::HTTP::Tiny->set_mocked_data( $replay );

my $crawl = WWW::Crawl->new(
    'timestamp' => 'a',
    'nolinks'   => 1,
);

my @links = $crawl->crawl('https://www.www-crawl.test/', \&link);

cmp_ok ( scalar @links, '==', 8, 'Correct link count');

sub link {
    cmp_ok ($_[0], 'eq', 'https://www.www-crawl.test/', 'Correct callback link');
}

