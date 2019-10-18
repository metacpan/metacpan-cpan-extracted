#!perl

use strict;
use warnings;
use Cwd qw(getcwd);
use Test::Most tests => 25;
use Unix::ScriptUtil
  qw(cd brun diropen fileopen pipe_close pipe_from pipe_to solitary timeout);

my $startdir = getcwd();
lives_ok { cd 't' } 'should not croak';
dies_ok { cd "/var/empty/$$/$$/$$/$$" } 'should croak';
my $testdir = getcwd();
ok $startdir ne $testdir;

unlink('brun.out');
lives_ok { brun $^X, '-e', 'open $f,">","brun.out"or die $!;print $f "blah"' };
my $fh;
lives_ok { $fh = fileopen "brun.out" };
is do { local $/; readline $fh }, "blah";
close $fh;

# must use fopen(3) form, not the shellish ones
dies_ok { fileopen "brun.out", '<' };

lives_ok { my $dh = diropen '.'; readdir $dh };

diag "this next should fail:";
dies_ok { pipe_to "/var/empty/nosuchcommand.$$" };

my $pipe;
lives_ok { $pipe = pipe_to $^X, '-e', 'exit 1' };
dies_ok { pipe_close $pipe };

lives_ok { $fh = pipe_from $^X, '-e', "print qq{blah.$$}" };
is do { local $/; readline $fh }, "blah.$$";
close $fh;

unlink 'pipe.out';
lives_ok {
    $fh = pipe_to $^X, '-e', 'open $f,">","pipe.out"or die $!;print $f readline'
};
print $fh "$$.blah";
close $fh;

# NOTE there may be race condition here if previous close has not gotten
# done by time this here tries to read that output
lives_ok { $fh = fileopen qw[pipe.out r] };
is do { local $/; readline $fh }, "$$.blah";
close $fh;

unlink 'rw.out';
$fh = fileopen 'rw.out', 'w+';
print $fh "wplus.$$";
seek $fh, 0, 0;
is do { local $/; readline $fh }, "wplus.$$";
close $fh;

$fh = fileopen 'rw.out', 'r+';
seek $fh, 0, 0;
print $fh "rplus.$$\n";
seek $fh, 0, 0;
is do { local $/; readline $fh }, "rplus.$$\n";
close $fh;

$fh = fileopen 'rw.out', 'a';
print $fh "a\n";
close $fh;

$fh = fileopen 'rw.out', 'a+';
print $fh "a+\n";
seek $fh, 0, 0;
is do { local $/; readline $fh }, "rplus.$$\na\na+\n";

unlink 'soli.out';
lives_ok {
    solitary '..', $^X, '-e',
      'open $f,">","t/soli.out";print $f "soli";die "unseen"';
};
# NOTE the race condition here; it may take some (or a lot) of time for
# the solitary call to complete its work
diag "waiting for forked process to complete work...";
# NOTE the timeout may be too low if the system is just very very busy
# (as opposed to the above having failed somehow so the output will
# never be created)
lives_ok {
    timeout 31, sub {
        while (1) { last if -e 'soli.out'; sleep 1 }
    };
};
lives_ok { $fh = fileopen qw[soli.out r] };
is do { local $/; readline $fh }, "soli";
close $fh;

dies_ok {
    timeout 1, sub { sleep 7 }
};

# TODO throws_ok/eval confuse the test framework with various errors:
#    Parse errors: Tests out of sequence.  Found (19) but expected (20)
#                  Bad plan.  You planned 19 tests but ran 20.
# or by normally exiting. maybe it needs a Capture::Tiny around it to
# prevent the child process output from reaching the test system? hmm
#throws_ok {
#eval {
#solitary("/var/empty/$$/$$/$$/$$", $^X, '-e', 'exit');
#};
#} qr/chdir.+failed: /;

# that solitary did not chdir this process
my $newdir = getcwd();
ok $testdir eq $newdir;
