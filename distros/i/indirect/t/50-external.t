#!perl

use strict;
use warnings;

use Config;

use Test::More tests => 8;

use lib 't/lib';
use VPIT::TestHelpers 'run_perl';

BEGIN { delete $ENV{PERL_INDIRECT_PM_DISABLE} }

SKIP: {
 my $status = run_perl 'no indirect; qq{a\x{100}b} =~ /\A[\x00-\x7f]*\z/;';
 skip RUN_PERL_FAILED() => 1 unless defined $status;
 is $status, 0, 'RT #47866';
}

SKIP: {
 skip 'Fixed in core only since 5.12' => 1 unless "$]" >= 5.012;

 my $status = run_perl 'no indirect hook => sub { exit 2 }; new X';
 skip RUN_PERL_FAILED() => 1 unless defined $status;
 is $status, 2 << 8, 'no semicolon at the end of -e';
}

SKIP: {
 load_or_skip('Devel::CallParser', undef, undef, 1);

 my $status = run_perl "use Devel::CallParser (); no indirect; sub ok { } ok 1";
 skip RUN_PERL_FAILED() => 1 unless defined $status;
 is $status, 0, 'indirect is not getting upset by Devel::CallParser';
}

SKIP: {
 my $has_package_empty = do {
  local $@;
  eval 'no warnings "deprecated"; package; 1'
 };
 skip 'Empty package only available on perl 5.8.x and below' => 1
                                                      unless $has_package_empty;

 my $status = run_perl 'no indirect hook => sub { }; exit 0; package; new X;';
 skip RUN_PERL_FAILED() => 1 unless defined $status;
 is $status, 0, 'indirect does not croak while package empty is in use';
}

my $fork_status;
if ($Config::Config{d_fork} or $Config::Config{d_pseudofork}) {
 $fork_status = run_perl 'my $pid = fork; exit 1 unless defined $pid; if ($pid) { waitpid $pid, 0; my $status = $?; exit(($status >> 8) || $status) } else { exit 0 }';
}

SKIP: {
 my $tests = 2;
 skip 'fork() or pseudo-forks are required to check END blocks in subprocesses'
                                          => $tests unless defined $fork_status;
 skip "Could not even fork a simple process (sample returned $fork_status)"
                                          => $tests unless $fork_status == 0;

 my $status = run_perl 'require indirect; END { eval q[1] } my $pid = fork; exit 0 unless defined $pid; if ($pid) { waitpid $pid, 0; my $status = $?; exit(($status >> 8) || $status) } else { exit 0 }';
 skip RUN_PERL_FAILED() => $tests unless defined $status;
 is $status, 0, 'indirect and global END blocks executed at the end of a forked process (RT #99083)';

 $status = run_perl 'require indirect; my $pid = fork; exit 0 unless defined $pid; if ($pid) { waitpid $pid, 0; my $status = $?; exit(($status >> 8) || $status) } else { eval q[END { eval q(1) }]; exit 0 }';
 skip RUN_PERL_FAILED() => ($tests - 1) unless defined $status;
 is $status, 0, 'indirect and local END blocks executed at the end of a forked process';
}

SKIP: {
 my $status;
 for my $run (1 .. 10) {
  $status = run_perl_file 't/testcases/rt115392.pl';
  skip RUN_PERL_FAILED() => 1 unless defined $status;
  last if $status;
 }
 is $status, 0, 'RT #115392';
}

SKIP: {
 my $status = run_perl_file 't/testcases/babycart_in_heredoc.pl';
 skip RUN_PERL_FAILED() => 1 unless defined $status;
 is $status, 0, 'babycart in heredoc';
}
