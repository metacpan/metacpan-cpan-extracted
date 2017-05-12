#!perl -T

use strict;
use warnings;

use Variable::Magic qw<wizard cast getdata dispell MGf_LOCAL VMG_UVAR>;

use Test::More;

BEGIN {
 my $tests = 11;
 $tests += 4 * (4 + (MGf_LOCAL ? 1 : 0) + (VMG_UVAR ? 4 : 0));
 plan tests => $tests;
}

our $destroyed;

{
 package Variable::Magic::TestDestructor;

 sub new { bless { }, shift }

 sub DESTROY { ++$::destroyed }
}

sub D () { 'Variable::Magic::TestDestructor' }

{
 local $destroyed = 0;

 my $w = wizard data => sub { $_[1] };

 {
  my $obj = D->new;

  {
   my $x = 1;
   cast $x, $w, $obj;
   is $destroyed, 0;
  }

  is $destroyed, 0;
 }

 is $destroyed, 1;
}

{
 local $destroyed = 0;

 my $w = wizard data => sub { $_[1] };

 {
  my $copy;

  {
   my $obj = D->new;

   {
    my $x = 1;
    cast $x, $w, $obj;
    is $destroyed, 0;
    $copy = getdata $x, $w;
   }

   is $destroyed, 0;
  }

  is $destroyed, 0;
 }

 is $destroyed, 1;
}

{
 local $destroyed = 0;

 {
  my $obj = D->new;

  {
   my $w  = wizard set => $obj;

   {
    my $x = 1;
    cast $x, $w;
    is $destroyed, 0;
   }

   is $destroyed, 0;
  }

  is $destroyed, 0;
 }

 is $destroyed, 1;
}

# Test destruction of returned values

my @methods = qw<get set clear free>;
push @methods, 'local' if MGf_LOCAL;
push @methods, qw<fetch store exists delete> if VMG_UVAR;

my %init = (
 scalar_lexical => 'my $x = 1; cast $x, $w',
 scalar_global  => 'our $X; local $X = 1; cast $X, $w',
 array          => 'my @a = (1); cast @a, $w',
 hash           => 'my %h = (a => 1); cast %h, $w',
);

my %type;
$type{$_} = 'scalar_lexical' for qw<get set free>;
$type{$_} = 'scalar_global'  for qw<local>;
$type{$_} = 'array'          for qw<clear>;
$type{$_} = 'hash'           for qw<fetch store exists delete>;

sub void { }

my %trigger = (
 get    => 'my $y = $x',
 set    => '$x = 2',
 clear  => '@a = ()',
 free   => 'void()',
 local  => 'local $X = 2',
 fetch  => 'my $v = $h{a}',
 store  => '$h{a} = 2',
 exists => 'my $e = exists $h{a}',
 delete => 'my $d = delete $h{a}',
);

for my $meth (@methods) {
 local $destroyed = 0;

 {
  my $w = wizard $meth => sub { return D->new };

  my $init    = $init{$type{$meth}};
  my $trigger = $trigger{$meth};
  my $deinit  = '';

  if ($meth eq 'free') {
   $init   = "{\n$init";
   $deinit = '}';
  }

  my $code = join ";\n", grep length, (
   $init,
   'is $destroyed, 0, "return from $meth, before trigger"',
   $trigger . ', is($destroyed, 0, "return from $meth, after trigger")',
   $deinit,
   'is $destroyed, 1, "return from $meth, after trigger"',
  );

  {
   local $@;
   eval $code;
   die $@ if $@;
  }

  is $destroyed, 1, "return from $meth, end";
 }
}
