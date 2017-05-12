#!perl -T

use strict;
use warnings;

use Test::More tests => 3 * 4;

BEGIN { delete $ENV{PERL_INDIRECT_PM_DISABLE} }

sub expect {
 my ($pkg, $line) = @_;
 return qr/^Indirect\s+call\s+of\s+method\s+"new"\s+on\s+object\s+"$pkg"\s+at\s+\(eval\s+\d+\)\s+line\s+$line/;
}

{
 local $/ = "####";
 while (<DATA>) {
  chomp;
  s/^\s+//;

  my ($code, $lines) = split /#+/, $_, 2;
  $lines = eval "[ sort ($lines) ]";
  if ($@) {
   diag "Couldn't parse line numbers: $@";
   next;
  }

  my (@warns, @lines);
  {
   local $SIG{__WARN__} = sub { push @warns, "@_" };
   eval "return; no indirect hook => sub { push \@lines, \$_[3] }; $code";
  }

  is        $@,              '',     'did\'t croak';
  is_deeply \@warns,         [ ],    'didn\'t warn';
  is_deeply [ sort @lines ], $lines, 'correct line numbers';
 }
}

__DATA__
my $x = new X;             # 1
####
my $x = new
  X;                       # 1
####
my $x = new X; $x = new X; # 1, 1
####
my $x = new
 X new
    X;                     # 1, 2
