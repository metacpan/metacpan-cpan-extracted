#!/usr/bin/perl
use strict;
use feature qw( say );
use Data::Dumper;

use lib './lib';
use Tie::Array::QueueExpire;

my $t = tie( my @myarray, "Tie::Array::QueueExpire", '/tmp/db_test.bdb' );

for ( 1 .. 10 )
{
    my $r = ( $t->PUSH( $_ . ' ' . time, 20 ) );
    my $r1 = substr( $r, 0, 10 );
    say "t=" . time . " $_ $r  $r1";
    sleep 1;
}

if ( exists $myarray[12] )
{
    say "elem 12 exist ";
}
else
{
    say "elem 12 NOT present ";
}
say "time=" . time;
my @ex = $t->EXPIRE( 7 );
say Dumper( \@ex );

sleep 10;
say "time=" . time;
my @ex = $t->EXPIRE( 7 );
say Dumper( \@ex );

say "toto=" . time . '  ' . ( $t->PUSH( 'toto' . ' ' . time, 2 ) );
for ( 11 .. 20 )
{
    say "t=" . time . '  ' . ( $t->PUSH( $_ . ' ' . time ) );
    sleep 1;
}
if ( exists $myarray[12] )
{
    say "elem 12 exist ";
}
else
{
    say "elem 12 NOT present ";
}
exit;
say "time=" . time;
@ex = $t->EXPIRE( 7 );
say Dumper( \@ex );
sleep 5;

say Dumper( @myarray );
@ex = $t->EXPIRE( 20, 1 );
say Dumper( \@ex );

say "time=" . time;
@ex = $t->EXPIRE( 7 );
say Dumper( \@ex );
say "t=" . time . '  ' . ( $t->PUSH( 'tata' . ' ' . time, -14 ) );
for ( 21 .. 30 )
{
    say "t=" . time . '  ' . ( $t->PUSH( $_ . ' ' . time, 10 ) );
    sleep 1;
}

my $a = $t->FETCH( 6 );
my @b = $t->FETCH( 6 );
my @c = $myarray[6];

say Dumper( $a );
say Dumper( \@b );
say Dumper( \@c );
say "-" x 20;

say Dumper( \@myarray );
say "x" x 20;
my @tt = $t->SLICE( 0, 0 );
say Dumper( \@tt );
testq( $t );
say "+" x 20;
say Dumper( \@myarray );
my $l = $t->FETCH( -1 );
say $l;
say Dumper( $t->FETCH( -1 ) );
say scalar( $t->FETCH );
say scalar( $t->FETCH( 0 ) );

sub testq
{
    my $i  = shift;
    my @ee = $i->SLICE();
    say "+-*-" x 20;
    say Dumper( \@ee );
    say "+-*-" x 20;
}

