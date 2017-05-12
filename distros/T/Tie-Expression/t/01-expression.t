#!perl -T
use strict;
use warnings;
use Tie::Expression;

#use Test::More 'no_plan';
use Test::More tests => 6;

tie my %X, 'Tie::Expression';
ok tied(%X);
is "$X{1 + 1}", 2, '$X{1 + 1} is 2';
my $pi = 4 * atan2( 1, 1 );
is "$X{4 * atan2(1,1)}", $pi, '$X{4 * atan2(1,1)} is' . $pi;
use File::Spec;
my $catfile = File::Spec->catfile(qw[/usr bin perl]);
is "$X{ File::Spec->catfile(qw[/usr bin perl]) }", $catfile,
  '$X{ File::Spec->catfile(qw[/usr bin perl]) } is ' . $catfile;
untie %X;
ok !tied(%X);
no warnings 'uninitialized';
is "$X{1 + 1}", '', '$X{1 + 1} is ""';
