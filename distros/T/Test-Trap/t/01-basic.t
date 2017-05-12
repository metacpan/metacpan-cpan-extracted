#!perl -T
# -*- mode: cperl ; compile-command: "cd .. ; ./Build ; prove -vb t/01-*.t" -*-

BEGIN { $_ = defined && /(.*)/ && $1 for @ENV{qw/ TMPDIR TEMP TMP /} } # taint vs tempfile
use Test::More tests => 2 + 8*9;
use strict;
use warnings;

BEGIN {
  use_ok( 'Test::Trap', 'trap', '$trap' );
}

my $name; # name of the test group

sub is_scalar {
  ok( !$trap->list,   "$name: Not list context" );
  ok(  $trap->scalar, "$name: Scalar context"   );
  ok( !$trap->void,   "$name: Not void context" );
}

sub is_list {
  ok(  $trap->list,   "$name: List context"       );
  ok( !$trap->scalar, "$name: Not scalar context" );
  ok( !$trap->void,   "$name: Not void context"   );
}

sub is_void {
  ok( !$trap->list,   "$name: Not list context"   );
  ok( !$trap->scalar, "$name: Not scalar context" );
  ok(  $trap->void,   "$name: Void context"       );
}

sub is_return {
  is( $trap->leaveby, 'return', "$name: Returned" );
  is( $trap->die,  undef, "$name: No exception trapped" );
  is( $trap->exit, undef, "$name: No exit trapped" );
}

sub is_die {
  is( $trap->leaveby, 'die', "$name: Died" );
  is_deeply( $trap->return, undef, "$name: Trapped return: none" );
  is( $trap->exit, undef, "$name: No exit trapped" );
}

sub is_exit {
  is( $trap->leaveby, 'exit', "$name: Exited" );
  is_deeply( $trap->return, undef, "$name: Trapped return: none" );
  is( $trap->die, undef, "$name: No exception trapped" );
}

my @x = qw( Example text );

$name = 'Return 2 in scalar context';
my $r = trap { @x };
is_scalar;
is_return;
is( $r, 2, "$name: Return: 2" );
is_deeply( $trap->return, [2], "$name: Trapped return: [2]" );

$name = "Return qw( @x ) in list context";
my @r = trap { @x };
is_list;
is_return;
is_deeply( \@r, \@x, "$name: Return: qw( @x )" );
is_deeply( $trap->return, \@x, "$name: Trapped return: [ qw( @x ) ]" );

$name = 'Return in void context';
trap { $r = defined wantarray ? 'non-void' : 'void' };
is_void;
is_return;
is_deeply( $trap->return, [], "$name: Trapped return: none" );
is( $r, 'void', "$name: Extra test -- side effect" );

$name = 'Die in scalar context';
$r = trap { die "My bad 1\n" };
is_scalar;
is_die;
is( $trap->die, "My bad 1\n", "$name: Trapped exception" );
is( $r, undef, "$name: Return: undef" );

$name = 'Die in list context';
@r = trap { die "My bad 2\n" };
is_list;
is_die;
is( $trap->die, "My bad 2\n", "$name: Trapped exception" );
is_deeply( \@r, [], "$name: Return: ()" );

$name = 'Die in void context';
trap { $r = defined wantarray ? 'non-void' : 'still void'; die "My bad 3\n" };
is_void;
is_die;
is( $trap->die, "My bad 3\n", "$name: Trapped exception" );
is( $r, 'still void', "$name: Extra test -- side effect" );

$name = 'Exit in scalar context';
$r = trap { exit 42 };
is_scalar;
is_exit;
is( $trap->exit, 42, "$name: Trapped exit 42" );
is( $r, undef, "$name: Return: undef" );

$name = 'Exit in list context';
@r = trap { exit };
is_list;
is_exit;
is( $trap->exit, 0, "$name: Trapped exit 0" );
is_deeply( \@r, [], "$name: Return: ()" );

$name = 'Exit in void context';
trap { $r = defined wantarray ? 'non-void' : 'and still void'; my @x = qw( a b c d ); exit @x };
is_void;
is_exit;
is( $trap->exit, 4, "$name: Trapped exit 4" );
is( $r, 'and still void', "$name: Extra test -- side effect" );

exit 0;

my $tricky = 1;

END {
  is($tricky, undef, ' --==-- END block past exit --==-- ');
}
