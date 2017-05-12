
use strict;
use utf8;
use Text::CSV::Encoded;

my $csv  = Text::CSV::Encoded->new;

eval q| $csv->decode( "あいうえお" ) |;

ok( !$@ );


eval q| $csv->decode('utf8', "あいうえお") |;

ok( $csv->automatic_UTF8 ? 1 : $@ );

1;
