#!/usr/bin/perl
use strict; use warnings;

use Test::More;
use Test::Exception;

use_ok( 'Whisper' );

my $file = 't/test.wsp';

my %args = ( file => $file );

ok( 
	wsp_fetch( %args ), "Is able to read a wsp file"
);

$args{from} = time - 3600;
ok(
    wsp_fetch( %args ), "Takes a from parameter" 
);

$args{until} = time - 60;
ok(
    wsp_fetch( %args ), "Takes an until parameter" 
);

$args{date_format} = '%s';
ok(
    wsp_fetch( %args ), "Is able to format dates" 
);

$args{format} = 'tuples';
ok(
    wsp_fetch( %args ), "Is able to do tuples format" 
);

$args{format} = 'split';
ok(
    wsp_fetch( %args ), "Is able to to splitted format" 
);

done_testing();
