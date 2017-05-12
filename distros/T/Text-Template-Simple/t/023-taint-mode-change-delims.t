#!perl -Tw
use constant TAINTMODE => 1;
#!/usr/bin/env perl -w
use strict;
use warnings;
use Test::More qw( no_plan );
use Text::Template::Simple;

my $raw     = q~<? my $x = 2008; ?>Foo: <?= $x ?><?# comment ?>~;
my $static  = q~<?+ t/data/raw.txt ?>~;
my $dynamic = q~<?* t/data/dynamic_delim.tts ?>~;
my @delims  = qw/ <? ?> /;

ok( my $t = Text::Template::Simple->new( delimiters => [ @delims ] ),
    'Got the object' );

my @tests = (
    [ $raw,     'Foo: 2008',             'CODE/CAPTURE/COMMENT' ],
    [ $static,  'raw content <%= $$ %>', 'STATIC'               ],
    [ $dynamic, 'Dynamic: 42',           'DYNAMIC'              ],
);

my $info = qq(: Delimiters changed into @delims);

foreach my $test ( @tests ) {
    is( $t->compile( $test->[0] ), $test->[1], $test->[2] . $info );
}
