#!perl -Tw
use constant TAINTMODE => 1;
#!/usr/bin/env perl -w
use strict;
use warnings;
use Test::More qw( no_plan );
use Text::Template::Simple;

ok( my $t = Text::Template::Simple->new(), 'Got the object' );

#$t->DEBUG(10);

ok( my $got = $t->compile( 't/data/shared-var.tts' ), 'Compile' );

my $expected = <<'WANTED';
Foo: 42
$bar before: 123
$bar is not shared and not defined
Foo is 42
$bar after: I love Text::Template::Simple
WANTED

chomp $expected;

is( $got, $expected, 'Shared variables seem to work as intended');
