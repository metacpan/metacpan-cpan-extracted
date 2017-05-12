#!perl -Tw
use constant TAINTMODE => 1;
#!/usr/bin/env perl -w
use strict;
use warnings;
use lib qw(t/lib lib);
use Test::More qw( no_plan );
use Text::Template::Simple;
use MyUtil;

ok( my $t   = Text::Template::Simple->new(),         'Got the object' );
ok( my $out = $t->compile( 't/data/recursive.tts' ), 'Compile' );

_p $out, "\n";

ok( $out, 'Nasty recursive test did not fail' );
