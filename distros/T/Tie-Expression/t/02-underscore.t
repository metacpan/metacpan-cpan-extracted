#!perl -T
use strict;
use warnings;
use Percent::Underscore;

#use Test::More 'no_plan';
use Test::More tests => 6;

ok tied(%_);
is "$_{1 + 1}", 2, '$_{1 + 1} is 2';
my $pi = 4 * atan2( 1, 1 );
is "$_{4 * atan2(1,1)}", $pi, '$_{4 * atan2(1,1)} is' . $pi;
use File::Spec;
my $catfile = File::Spec->catfile(qw[/usr bin perl]);
is "$_{ File::Spec->catfile(qw[/usr bin perl]) }", $catfile,
  '$_{ File::Spec->catfile(qw[/usr bin perl]) } is ' . $catfile;
untie %_;
ok !tied(%_);
no warnings 'uninitialized';
is "$_{1 + 1}", '', '$_{1 + 1} is ""';
