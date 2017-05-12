#!perl -T

use strict;
use warnings;

use Test::More tests => 26;

use Variable::Magic qw<wizard cast>;

my $wiz = eval { wizard get => sub { undef } };
is($@, '',             'wizard creation doesn\'t croak');
ok(defined $wiz,       'wizard is defined');
is(ref $wiz, 'SCALAR', 'wizard is a scalar ref');

my $n = int rand 1000;
my $a = $n;

my $res = eval { cast $a, $wiz };
is($@, '', 'cast doesn\'t croak');
ok($res,   'cast is valid');

my $x;
eval {
 local $SIG{__WARN__} = sub { die };
 $x = $a
};
is($@, '', 'callback returning undef doesn\'t warn/croak');
is($x, $n, 'callback returning undef fails');

{
 my $c = 0;
 sub X::wat { ++$c }
 my $wiz = eval { wizard get => \'X::wat' };
 is($@, '', 'wizard with a qualified string callback doesn\'t croak');
 my $b = $n;
 my $res = eval { cast $b, $wiz };
 is($@, '', 'cast a wizard with a qualified string callback doesn\'t croak');
 my $x;
 eval {
  local $SIG{__WARN__} = sub { die };
  $x = $b;
 };
 is($@, '', 'qualified string callback doesn\'t warn/croak');
 is($c, 1,  'qualified string callback is called');
 is($x, $n, 'qualified string callback returns the right thing');
}

{
 my $c = 0;
 sub wut { fail 'main::wut was called' }
 sub Y::wut { ++$c }
 my $wiz = eval { wizard get => \'wut' };
 is($@, '', 'wizard with a short string callback doesn\'t croak');
 my $b = $n;
 my $res = eval { cast $b, $wiz };
 is($@, '', 'cast a wizard with a short string callback doesn\'t croak');
 my $x;
 eval {
  local $SIG{__WARN__} = sub { die };
  package Y;
  $x = $b;
 };
 is($@, '', 'short string callback doesn\'t warn/croak');
 is($c, 1,  'short string callback is called');
 is($x, $n, 'short string callback returns the right thing');
}

{
 my $wiz = eval { wizard get => \undef };
 is($@, '', 'wizard with a ref-to-undef callback doesn\'t croak');
 my $b = $n;
 my $res = eval { cast $b, $wiz };
 is($@, '', 'cast a wizard with a ref-to-undef callback doesn\'t croak');
 my $x;
 eval {
  local $SIG{__WARN__} = sub { die };
  $x = $b;
 };
 is($@, '', 'ref-to-undef callback doesn\'t warn/croak');
 is($x, $n, 'ref-to-undef callback returns the right thing');
}

my @callers;
$wiz = wizard get => sub {
 my @c;
 my $i = 0;
 while (@c = caller $i++) {
  push @callers, [ @c[0, 1, 2] ];
 }
};

my $b;
cast $b, $wiz;

my $u = $b;
is_deeply(\@callers, [
 ([ 'main', $0, __LINE__-2 ]) x 2,
], 'caller into callback returns the right thing');

@callers = ();
$u = $b;
is_deeply(\@callers, [
 ([ 'main', $0, __LINE__-2 ]) x 2,
], 'caller into callback returns the right thing (second time)');

{
 @callers = ();
 my $u = $b;
 is_deeply(\@callers, [
  ([ 'main', $0, __LINE__-2 ]) x 2,
 ], 'caller into callback into block returns the right thing');
}

@callers = ();
eval { my $u = $b };
is($@, '', 'caller into callback doesn\'t croak');
is_deeply(\@callers, [
 ([ 'main', $0, __LINE__-3 ]) x 3,
], 'caller into callback into eval returns the right thing');

