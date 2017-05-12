
use strict;
use Test;
use XML::CuteQueries;
use Data::Dumper;

$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Indent   = 0;

my $CQ = XML::CuteQueries->new;
   $CQ->parsefile("example.xml");

my $exemplar = Dumper([
    {f1=> '7', f2=>'11', f3=>'13'},
    {f1=>'17', f2=>'19', f3=>'23'},
    {f1=>'29', f2=>'31', f3=>'37'},
]);

my $matched = Dumper($CQ->cute_query(
    data => [row => {'*'=>''}],
));

plan tests => 1;
ok( $matched, $exemplar );
