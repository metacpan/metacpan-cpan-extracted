#!/usr/bin/perl
use strict;
use warnings;
use Test2::Tools::Basic;
use Test2::Tools::Compare;

plan(2);

my $one_liners = [
  ['skip_all_until "skip_all_until", "2037-01-01"; die "did not skip all!"', 0, '2037 - skip all'],
  ['skip_all_until "skip_all_until", "1995-01-01"; die "did not skip all!"', 255, '1995 - do not skip all'],
];

for (@$one_liners) {
  my ($program, $expected, $reason) = @$_;

  my ($oldout, $olderr) = redirect_output();
  system $^X, '-Ilib', '-MTest2::Tools::SkipUntil','-e', $program;
  restore_output($oldout, $olderr);

  is $? >> 8, $expected, $reason;
}

sub redirect_output {
  open my $oldout, ">&", \*STDOUT or die "Can't preserve STDOUT $!";
  close STDOUT;
  open STDOUT, ">", '/dev/null' or die "Can't redirect STDOUT $!";
  open my $olderr, ">&", \*STDERR or die "Can't preserve STDERR $!";
  close STDERR;
  open STDERR, ">", '/dev/null' or die "Can't redirect STDOUT $!";
  return $oldout, $olderr;;
}

sub restore_output {
  my ($oldout, $olderr) = @_;
  open STDOUT, ">&", \*$oldout or die "Can't restore STDOUT $!";
  close $oldout;
  open STDERR, ">&", \*$olderr or die "Can't restore STDERR $!";
  close $olderr;
}

# NB. tests skip_all_until by running one liners in sub processes
# closes & restores stdout, stderr to avoid TAP parse errors
