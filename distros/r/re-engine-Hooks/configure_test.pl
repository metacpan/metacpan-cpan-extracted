#!perl

use strict;
use warnings;

use POSIX qw/WIFEXITED WEXITSTATUS EXIT_FAILURE/;

BEGIN {
 no warnings 'redefine';
 local $@;
 *WIFEXITED   = sub { 1 }             unless eval { WIFEXITED(0);   1 };
 *WEXITSTATUS = sub { shift() >> 8 }  unless eval { WEXITSTATUS(0); 1 };
}

my @args;
{
 my $args_dat = './args.dat';

 open my $fh, '<', $args_dat or die "open(<$args_dat): $!";

 {
  local $/ = "\n";
  @args = <$fh>;
 }
 for (@args) {
  1 while chomp;
  s{\[([0-9]+)\]}{chr $1}ge;
 }
}

my $ret = EXIT_FAILURE;
{
 sub CwdSaver::DESTROY {
  my $cwd = $_[0]->{cwd};
  chdir $cwd or die "chdir('$cwd'): $!";
 }

 my $guard = bless { cwd => do { require Cwd; Cwd::cwd() } }, 'CwdSaver';

 chdir 't/re-engine-Hooks-TestDist'
                               or die "chdir('t/re-engine-Hooks-TestDist'): $!";

 system { $^X } $^X, 'Makefile.PL', @args;
 if ($? == -1) {
  die "$^X Makefile.PL @args: $!";
 } elsif (WIFEXITED($?)) {
  $ret = WEXITSTATUS($?);
 }
}

exit $ret;
