package autovivification::TestCases;

use strict;
use warnings;

use Test::Leaner;

sub import {
 no strict 'refs';
 *{caller().'::testcase_ok'} = \&testcase_ok;
}

sub in_strict { (caller 0)[8] & (eval { strict::bits(@_) } || 0) };

sub do_nothing { }

sub set_arg { $_[0] = 1 }

sub generate {
 my ($var, $init, $code, $exp, $use, $opts, $global) = @_;
 my $decl = $global ? "our $var; local $var;" : "my $var;";
 my $test = $var =~ /^[@%]/ ? "\\$var" : $var;
 my $desc = join('; ', map { my $x = $_; $x=~ s,;\s*$,,; $x }
                                   grep /\S/, $decl, $init, $code) . " <$opts>";
 return <<TESTCASE, $desc;
$decl
$init
my \$strict = autovivification::TestCases::in_strict('refs');
my \@exp = ($exp);
my \$res = eval {
 local \$SIG{__WARN__} = sub { die join '', 'warn:', \@_ };
 $use
 $code
};
if (ref \$exp[0]) {
 like \$@, \$exp[0], \$desc . ' [exception]';
} else {
 is   \$@, \$exp[0], \$desc . ' [exception]';
}
is_deeply \$res, \$exp[1], \$desc . ' [return]';
is_deeply $test, \$exp[2], \$desc . ' [variable]';
TESTCASE
}

sub testcase_ok {
 local $_  = shift;
 my $sigil = shift;

 my @chunks = split /#+/, "$_ ";
 s/^\s+//, s/\s+$// for @chunks;
 my ($init, $code, $exp, $opts) = @chunks;

 (my $var = $init) =~ s/[^\$@%\w].*//;
 $init = $var eq $init ? '' : "$init;";
 my $use;
 if ($opts) {
  for (split ' ', $opts) {
   my $no = 1;
   $no = 0 if s/^([-+])// and $1 eq '-';
   $use .= ($no ? 'no' : 'use') . " autovivification '$_';"
  }
 } elsif (defined $opts) {
  $opts = 'empty';
  $use  = 'no autovivification;';
 } else {
  $opts = 'default';
  $use  = '';
 }

 my @base = ([ $var, $init, $code, $exp, $use ]);
 if ($var =~ /\$/) {
  my ($name) = $var =~ /^\$(.*)/;

  my @oldderef = @{$base[0]};
  $oldderef[2] =~ s/\Q$var\E\->/\$$var/g;
  push @base, \@oldderef;

  my @nonref = @{$base[0]};
  $nonref[0] = $sigil . $name;
  for ($nonref[1], $nonref[2]) {
   s/\@\Q$var\E([\[\{])/\@$name$1/g;
   s/\Q$sigil$var\E/$nonref[0]/g;
   s/\Q$var\E\->/$var/g;
  }
  my $simple      = $nonref[2] !~ /->/;
  my $plain_deref = $nonref[2] =~ /\Q$nonref[0]\E/;
  my $empty  = { '@' => '[ ]', '%' => '{ }' }->{$sigil};
  if (($simple
       and (   $nonref[3] =~ m!qr/\^Reference vivification forbidden.*?/!
            or $nonref[3] =~ m!qr/\^Can't vivify reference.*?/!))
  or ($plain_deref
       and $nonref[3] =~ m!qr/\^Can't use an undefined value as a.*?/!)) {
   $nonref[1] = '';
   $nonref[2] = 1;
   $nonref[3] = "'', 1, $empty";
  }
  $nonref[3] =~ s/,\s*undef\s*$/, $empty/;
  push @base, \@nonref;
 }

 my @testcases = map {
  my ($var, $init, $code, $exp, $use) = @$_;
  [ $var, $init,               $code, $exp, $use, $opts, 0 ],
  [ $var, "use strict; $init", $code, $exp, $use, $opts, 1 ],
  [ $var, "no strict;  $init", $code, $exp, $use, $opts, 1 ],
 } @base;

 for (@testcases) {
  my ($testcase, $desc) = generate(@$_);
  my @N = (0 .. 9);
  eval $testcase;
  diag "== This testcase failed to compile ==\n$testcase\n## Reason: $@" if $@;
 }
}

1;
