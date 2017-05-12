#!perl -Tw
use constant TAINTMODE => 1;
#!/usr/bin/env perl -w
use strict;
use warnings;
use subs qw( trim );
use Test::More qw( no_plan );
use Text::Template::Simple;

ok( my $t = Text::Template::Simple->new( monolith => 1 ), 'Got the object' );

ok( my $got  = trim $t->compile( 't/data/monolith.tts' ), 'Compile' );
my $expected = trim expected();

is( $got, $expected, 'Testing Monolith' );

sub expected {
    return <<'EXPECT';
[ dynamic include error ] Interpolated includes don't work under monolith option. Please disable monolith and use the 'SHARE' directive in the include command: t/data/monolith-1.tts | PARAM: 'test'
$VAR1 = [42,{'abc' => 123},1,2,3];
$VAR1 = [42,{'abc' => 123},1,2,3];
EXPECT
}

sub trim {
    my $s = shift;
    $s =~ s{ \A \s+    }{}xms;
    $s =~ s{    \s+ \z }{}xms;
    return $s;
}
