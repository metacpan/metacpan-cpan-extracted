
use strict;
use Test;
use XML::CuteQueries;
use Data::Dumper;

$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Indent   = 0;

my $CQ = XML::CuteQueries->new;
   $CQ->parsefile("example.xml");

my $exemplar = Dumper({
    result => 'OK',

    data => [
        {f1=> '7', f2=>'11', f3=>'13'},
        {f1=>'17', f2=>'19', f3=>'23'},
        {f1=>'29', f2=>'31', f3=>'37'},
    ],

    atad => {
        c1 => [qw(503 509)],
        c2 => [qw(521 523)],
    },

});

my $actual = Dumper($CQ->cute_query('.' => {
    result => '',
    data   => [row => {'*'=>''}],
    atad   => {'*' => [ f1=>'']},
}));

plan tests => 1;
ok( $actual, $exemplar );
