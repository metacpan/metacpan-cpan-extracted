#!/usr/bin/perl
use feature 'say';
use lib "./lib";
use Tie::Queue;
use Data::Dumper;
use Time::HiRes qw(time);

tie my @a, 'Tie::Queue', '127.0.0.1', 1978, 1, 0, 'sdsd' ;
tie my @b, 'Tie::Queue', '127.0.0.1', 1978, 1, 0, 'tata';
tie my @c, 'Tie::Queue', '127.0.0.1', 1978, 0, 1, 'titi';
tie my @d, 'Tie::Queue', '127.0.0.1', 1978, 0, 1;
tie my @e, 'Tie::Queue', '127.0.0.1', 1978, 0, 0, 'toto', 0, 0, 0, 0, 1 ;

print "******   Test push\n";
push @a, 'test';

print Dumper( \@a );

for ( 101 .. 110 )
{
    push @a, $_.'_'.time;

}

for ( 1001 .. 1005 )
{
    push @b, $_.'_'.time;

}

print Dumper( \@a );


print "******   Test pop\n";
my $t = pop @a;
say "t=$t";

print "******   Test shift\n";
my $t = shift @a;
say "t=$t";

print "******   Test serialisation of complex data \n";
my %test = ( a => 'key_a', b => 'key_B' , c => 3 );
print Dumper(\%test);
push @d , \%test;

my $r = pop @d;
print Dumper($r);


#
# print "size of array=". scalar @a. "\n";
#
# print "size of array a = " . scalar @a . "\n";
# print Dumper( \@b );
# print "size of array b = " . scalar @b . "\n";
#
#
# $res1 = pop @a;
# print "latest element in a $res1\n";
#
# print "size of array a = " . scalar @a . "\n";
# print "size of array b = " . scalar @b . "\n";
# print "size of array c = " . scalar @c . "\n";
# #
# $resC = pop @c;
# print "latest element in c $resC\n";
# print "size of array c =" . scalar @c . "\n";
# print Dumper( \@a );


print "******   Test index\n";
$res2 = $a[3];
print "element 3 = $res2\n";

$res3 = shift @a;
print "first element of a = <$res3>\n";

print "size of array=" . scalar @a . "\n";

print Dumper( \@a );


print "******   Test exists\n";
if ( exists $a[4] )
{
    print "elem 4 exists\n";
}
else
{
    print "elem 4 NOT exists\n";
}

if ( exists $a[40] )
{
    print "elem 40 exists\n";
}
else
{
    print "elem 40 is NOT existing\n";
}

print "******   Test CLEAR\n";
(tied @a)->CLEAR;
print Dumper( \@a );


undef @b;
 
print Dumper( \@b );


print "******   Test SIZE ( scalar )\n";
print "size of array a = " . scalar @a . "\n";
print "size of array b = " . scalar @b . "\n";
print "size of array c = " . scalar @c . "\n";


print "******   Test no duplicate feature\n";
for my $a ( 1 .. 10 )
{
   push @e , $a;
}
print Dumper( \@e );

push @e , 7;
print Dumper( \@e );
