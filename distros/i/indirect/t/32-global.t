#!perl

use strict;
use warnings;

my $tests;
BEGIN { $tests = 9 }

use Test::More tests => (1 + $tests + 1) + 3 + 5 + 2 + 4;

BEGIN { delete $ENV{PERL_INDIRECT_PM_DISABLE} }

use lib 't/lib';

my %wrong = map { $_ => 1 } 2, 3, 5, 6, 7, 9;

sub expect {
 my ($pkg, $file, $prefix) = @_;
 $file   = defined $file   ? quotemeta $file   : '\(eval \d+\)';
 $prefix = defined $prefix ? quotemeta $prefix : 'warn:';
 qr/^${prefix}Indirect call of method "new" on object "$pkg" at $file line \d+/;
}

{
 my $code = do { local $/; <DATA> };
 my (%res, $num, @left);

 {
  local $SIG{__WARN__} = sub {
   ++$num;
   my $w = join '', 'warn:', @_;
   if ($w =~ /"P(\d+)"/ and not exists $res{$1}) {
    $res{$1} = $w;
   } else {
    push @left, "[$num] $w";
   }
  };
  eval "return; $code";
 }
 is $@, '', 'DATA compiled fine';

 for (1 .. $tests) {
  my $w = $res{$_};
  if ($wrong{$_}) {
   like $w, expect("P$_"), "$_ should warn";
  } else {
   is   $w, undef,         "$_ shouldn't warn";
  }
 }

 is @left, 0, 'nothing left';
 diag "Extraneous warnings:\n", @left if @left;
}

{
 my @w;
 {
  local $SIG{__WARN__} = sub { push @w, join '', 'warn:', @_ };
  eval 'return; { no indirect "global" }; BEGIN { eval q[return; new XYZ] }';
 }
 is   $@, '', 'eval test did not croak prematurely';
 is   @w, 1,  'eval test threw one warning';
 diag join "\n", 'All warnings:', @w if @w > 1;
 like $w[0], expect('XYZ'), 'eval test threw the correct warning';
}

{
 my @w;
 {
  local $SIG{__WARN__} = sub { push @w, join '', 'warn:', @_ };
  eval 'return; { no indirect "global" }; use indirect::TestRequiredGlobal';
 }
 is   $@, '', 'require test did not croak prematurely';
 is   @w, 3,  'require test threw three warnings';
 diag join "\n", 'All warnings:', @w if @w > 3;
 like $w[0], expect('ABC', 't/lib/indirect/TestRequiredGlobal.pm'),
                            'require test first warning is correct';
 like $w[1], expect('DEF'), 'require test second warning is correct';
 like $w[2], expect('GHI'), 'require test third warning is correct';
}

{
 my @w;
 {
  local $SIG{__WARN__} = sub { push @w, join '', 'warn:', @_ };
  eval 'return; { no indirect qw<global fatal> }; new MNO';
 }
 like $@, expect('MNO', undef, ''), 'fatal test throw the correct exception';
 is   @w, 0,                        'fatal test did not throw any warning';
 diag join "\n", 'All warnings:', @w if @w;
}

{
 my @w;
 my @h;
 my $hook = sub { push @h, join '', 'hook:', indirect::msg(@_) };
 {
  local $SIG{__WARN__} = sub { push @w, join '', 'warn:', @_ };
  eval 'return; { no indirect hook => $hook, "global" }; new PQR';
 }
 is   $@, '', 'hook test did not croak prematurely';
 is   @w, 0,  'hook test did not throw any warning';
 diag join "\n", 'All warnings:', @w if @w;
 is   @h, 1,  'hook test hooked up three violations';
 diag join "\n", 'All captured violations:', @h if @h > 1;
 like $h[0], expect('PQR', undef, 'hook:'),
              'hook test captured the correct error';
}

__DATA__
my $a = new P1;

{
 no indirect 'global';
 my $b = new P2;
 {
  my $c = new P3;
 }
 {
  use indirect;
  my $d = new P4;
 }
 my $e = new P5;
}

my $f = new P6;

no indirect;

my $g = new P7;

use indirect;

my $h = new P8;

{
 no indirect;
 eval { my $i = new P9 };
}
