
use strict;
use Test;
use XML::CuteQueries;
use Data::Dumper;

$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Indent   = 0;

my $CQ = XML::CuteQueries->new;
   $CQ->parsefile("example.xml");

my $exemplar = Dumper({
    c1 => [qw(503 509)],
    c2 => [qw(521 523)],
});

my $actual = Dumper($CQ->cute_query(
    atad => {'*' => [f1=>'']},
));

plan tests => 1;
ok( $actual, $exemplar );
