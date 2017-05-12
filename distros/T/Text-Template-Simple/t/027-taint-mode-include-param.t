#!perl -Tw
use constant TAINTMODE => 1;
#!/usr/bin/env perl -w
use strict;
use warnings;
use Test::More qw( no_plan );
use Text::Template::Simple;
use File::Spec;

ok( my $t = Text::Template::Simple->new(), 'Got the object' );

my $file = File::Spec->catfile( qw( t data ), '027-dynamic.tts' );

ok( my $got = $t->compile( $file ), 'Compile' );

is( $got, 'Dynamic: Perl ROCKS!', 'Dynamic include got params');
