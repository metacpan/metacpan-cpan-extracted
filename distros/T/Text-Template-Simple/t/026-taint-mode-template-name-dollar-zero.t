#!perl -Tw
use constant TAINTMODE => 1;
#!/usr/bin/env perl -w
use strict;
use warnings;
use Test::More qw( no_plan );
use Text::Template::Simple;

ok( my $t = Text::Template::Simple->new(), 'Got the object' );

ok( my $got = $t->compile( 't/data/tname_main.tts' ), 'Compile' );

my $expected = 't/data/tname_main.tts & t/data/tname_sub.tts';

is( $got, $expected, 'Template names are accessible via dollar zero' );
