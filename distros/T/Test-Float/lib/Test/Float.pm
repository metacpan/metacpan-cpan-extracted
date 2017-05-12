
package Test::Float;

BEGIN { $Devel::Trace::TRACE = 0; };
use strict;
use warnings;

our $VERSION = '0.3';

use IO::Handle;
# use Code::Splice;
# use B::Deparse;

# Usage:
# 
#   perl -MTest::Float -e 'Test::Float::test_harness(1, "blib/lib", "blib/arch")' t/Test-Float.t
#   perl -MTest::Float -e 'Test::Float::learn_perl("/path/");'
# 
# Use float.pl instead.
# 
# Todo:
# 
# * Test arena
#   * Start with making a small program do something
#   * Try to modify a large program
#   * Too bad I left the cluster root at home...
# 
# * Tek presentation software!
# 
# * One fitness test should be who.int indexes.
# 
# * Eventually, the tests should be busted back out, eg back into FrozenPerl-Scrottie,
#   along with the code to be hacked up.
# 
# * Figure out how to get ExtUtils::MakeMaker to generate a makefile that uses this module 
#   automatically when invoking the test harness.
# 
# Done:
# 
# * Just monkey patch the test harness.  Rewrite the stupid code.
# 
# * Train a Markov Chains bot with a bunch of Perl -- good perl, bad perl, whatever.
# 
# * Create pools of random code and run generations.
#   * Too bad Code::Splice isn't up to the task... or is it?  Single mod to each function?
# 
# Slides:
# 
# * Part of my agit series, which has included:
#   * Acme::ObjectRightSide out -- fixing inside out objects
#   * Perl stole everything from SNOBOL
# 
# * What do you do when you have no time to read through side-effect #   laden code to figure out what it does, no time to refactor it,
#   and no docs to read explaining what's going on?
# 
# * Get GumbyBrain to write your code for you.
# 
# * You're going in naive, he's going in naive, what's the difference?
# 
# * First messed with a Markov Chains bot when my cell phone broke.  I put my SIM card
#   into my data card and scraped textsfromlastnight with Text::Scraper.
# 
# * What you can do that GumbyBrain can't currently is make iteratively
#   better guesses.
# 
# * Fixed!
# 
# * perl -MTest::Float -e 'print "final: $_\n", Test::Float::test_harness(1, "blib/lib", "blib/arch")' t/Test-Float.t
# 
# * perl float.pl eval 'my $fc = float::Chain->new->init(50); for my $i (0..3) { print $fc->to_string, "\n\n"; $fc->mutate; }'
# 
# * Now you can make the code worse without having to look at the mess.
# 
# * Applied Genetic Programming techniques to Markov Chains state
#   transition probabilities.
# 
# * [Point of this experiment:  the way people try to write Perl, you
#   might as well have a chatterbot working for you; "naive" is bad
#   for algorithms and for programmers; what's the point in being an
#   expert in Perl if the codebase is going to be an eternal mystery?
#   Also, formulating hypotheses is the real trick; creating fitness
#   metrics for *code* is hard.]
# 
# Rant:
# 
# this code doesn't lend itself well to being read and understood -- no comments, no explanation of why things are done
# nor does it lend itself well to being used without having been read and understood -- side effects galore, library style interface than OO
# 
# I don't know what's going on in there if I don't read the code;
# if I read the code, I don't understand the intention and point of the sideffects and which apply to this case and which I need to
# actively work around;
# 
# Notes:
# 
# * Code::Splice causing coredumps with two patches to the same sub.
#   not sure why.
#   C::S also wedges the CPU with one patch.  Feeding it garbage would be interesting.
# 
# * Backhanded swipe at robo-coding.
# 
# Tests:
# 
# * not too much whitespace
# * not too many blank lines
# * not too many comments
# * discourage pointless whitespace to pad out lines before errors
# * runtime errors?
# 
# Usage:
# 
#   perl -MTest::Float -MExtUtils::Command::MM -e 'test_harness(1, "blib/lib", "blib/arch")' t/FrozenPerl-Scrottie.t 
#   perl -MTest::Float -e 'print "final: $_\n", Test::Float::test_harness(1, "blib/lib", "blib/arch")' t/Test-Float.t 
#   perl -MTest::Float -e 'Test::Float::test_harness(1, "blib/lib", "blib/arch")' t/FrozenPerl-Scrottie.t 
# 
# 

# sub test_harness {
#     ExtUtils::Command::MM::test_harness(@_);
# }

sub test_harness {
    # our test_harness() runs their test_harness(); no, masquarading as Test::Harness is kinda cranky, let's just copy and paste that too
    require ExtUtils::Command::MM;
    require File::Spec;

    $Test::Harness::verbose = shift;

    # Because Windows doesn't do this for us and listing all the *.t files
    # out on the command line can blow over its exec limit.
    require ExtUtils::Command;
    my @argv = ExtUtils::Command::expand_wildcards(@ARGV);

    local @INC = @INC;
    unshift @INC, map { File::Spec->rel2abs($_) } @_;
    runtests(sort { lc $a cmp lc $b } @argv);
}

# modified Test::Harness code

use Test::Float::Straps;
use Test::Float::Assert;
use Exporter;
use Benchmark;
use Config;
use strict;


use vars qw(
    $VERSION 
    @ISA @EXPORT @EXPORT_OK 
    $Verbose $Switches $Debug
    $verbose $switches $debug
    $Curtest
    $Columns 
    $Timer
    $ML $Last_ML_Print
    $Strap
    $has_time_hires
);

BEGIN {
    eval "use Time::HiRes 'time'";
    $has_time_hires = !$@;
}

# Backwards compatibility for exportable variable names.
*verbose  = *Verbose;
*switches = *Switches;
*debug    = *Debug;

$ENV{HARNESS_ACTIVE} = 1;
$ENV{HARNESS_VERSION} = $VERSION;

END {
    # For VMS.
    delete $ENV{HARNESS_ACTIVE};
    delete $ENV{HARNESS_VERSION};
}

# Some experimental versions of OS/2 build have broken $?
my $Ignore_Exitcode = $ENV{HARNESS_IGNORE_EXITCODE};

my $Files_In_Dir = $ENV{HARNESS_FILELEAK_IN_DIR};

$Strap = Test::Float::Straps->new;

sub strap { return $Strap };

@ISA = ('Exporter');
@EXPORT    = qw(&runtests);
@EXPORT_OK = qw($verbose $switches);

$Verbose  = $ENV{HARNESS_VERBOSE} || 0;
$Debug    = $ENV{HARNESS_DEBUG} || 0;
$Switches = "-w";
$Columns  = $ENV{HARNESS_COLUMNS} || $ENV{COLUMNS} || 80;
$Columns--;             # Some shells have trouble with a full line of text.
$Timer    = $ENV{HARNESS_TIMER} || 0;

# The F<prove> utility is a thin wrapper around Test::Float.

sub runtests {
    my(@tests) = @_;

    local ($\, $,);

    my($tot, $failedtests) = _run_all_tests(@tests);
    _show_results($tot, $failedtests);

    my $ok = _all_ok($tot);

    assert(($ok xor keys %$failedtests), 
           q{ok status jives with $failedtests});

    return $ok;
}

# sub _all_ok {
#     my($tot) = shift;
# 
#     return $tot->{bad} == 0 && ($tot->{max} || $tot->{skipped}) ? 1 : 0;
# }

sub _all_ok {
    my($tot) = shift;
    # return $tot->{bad} == 0 && ($tot->{max} || $tot->{skipped}) ? 1 : 0;
    return 0 if $tot->{bad} && ($tot->{max} || $tot->{skipped});
    return 0 if ! $tot->{max};
    # use Data::Dumper;  print Data::Dumper::Dumper($tot); return 1;
    #      'files' => 1,
    #      'max' => 2,
    #      'bonus' => 0,
    #      'skipped' => 0,
    #      'sub_skipped' => 0,
    #      'ok' => 2,
    #      'bad' => 0,
    #      'good' => 1,
    #      'tests' => 1,
    #      'todo' => 0
    return $tot->{ok} / $tot->{max};
};

sub _globdir { 
    opendir DIRH, shift; 
    my @f = readdir DIRH; 
    closedir DIRH; 

    return @f;
}

#  my($total, $failed) = _run_all_tests(@test_files);
# 
# Runs all the given C<@test_files> (as C<runtests()>) but does it
# quietly (no report).  $total is a hash ref summary of all the tests
# run.  Its keys and values are this:
# 
#     bonus           Number of individual todo tests unexpectedly passed
#     max             Number of individual tests ran
#     ok              Number of individual tests passed
#     sub_skipped     Number of individual tests skipped
#     todo            Number of individual todo tests
# 
#     files           Number of test files ran
#     good            Number of test files passed
#     bad             Number of test files failed
#     tests           Number of test files originally given
#     skipped         Number of test files skipped
# 
# If C<< $total->{bad} == 0 >> and C<< $total->{max} > 0 >>, you've
# got a successful test.
# 
# $failed is a hash ref of all the test scripts which failed.  Each key
# is the name of a test script, each value is another hash representing
# how that script failed.  Its keys are these:
# 
#     name        Name of the test which failed
#     estat       Script's exit value
#     wstat       Script's wait status
#     max         Number of individual tests
#     failed      Number which failed
#     percent     Percentage of tests which failed
#     canon       List of tests which failed (as string).
# 
# C<$failed> should be empty if everything passed.

# Turns on autoflush for the handle passed
sub _autoflush {
    my $flushy_fh = shift;
    my $old_fh = select $flushy_fh;
    $| = 1;
    select $old_fh;
}

sub _run_all_tests {
    my @tests = @_;

    _autoflush(\*STDOUT);
    _autoflush(\*STDERR);

    my(%failedtests);

    # Test-wide totals.
    my(%tot) = (
                bonus    => 0,
                max      => 0,
                ok       => 0,
                files    => 0,
                bad      => 0,
                good     => 0,
                tests    => scalar @tests,
                sub_skipped  => 0,
                todo     => 0,
                skipped  => 0,
                bench    => 0,
               );

    my @dir_files = _globdir $Files_In_Dir if defined $Files_In_Dir;
    my $run_start_time = new Benchmark;

    my $width = _leader_width(@tests);
    foreach my $tfile (@tests) {
        $Last_ML_Print = 0;  # so each test prints at least once
        my($leader, $ml) = _mk_leader($tfile, $width);
        local $ML = $ml;

        print $leader;

        $tot{files}++;

        $Strap->{_seen_header} = 0;
        if ( $Test::Float::Debug ) {
            print "# Running: ", $Strap->_command_line($tfile), "\n";
        }
        my $test_start_time = $Timer ? time : 0;
$Devel::Trace::TRACE = 1;
        my $results = $Strap->analyze_file($tfile) or
          do { warn $Strap->{error}, "\n";  next };
# use Data::Dumper; warn Dumper $results; exit;
$Devel::Trace::TRACE = 0;

        my $elapsed;
        if ( $Timer ) {
            $elapsed = time - $test_start_time;
            if ( $has_time_hires ) {
                $elapsed = sprintf( " %8.3fs", $elapsed );
            }
            else {
                $elapsed = sprintf( " %8ss", $elapsed ? $elapsed : "<1" );
            }
        }
        else {
            $elapsed = "";
        }

        # state of the current test.

        my @failed = grep { !$results->{details}[$_-1]{ok} }
                     1..@{$results->{details}};
        my %test = (
                    ok          => $results->ok,
                    'next'      => $Strap->{'next'},
                    max         => $results->max,
                    failed      => \@failed,
                    bonus       => $results->bonus,
                    skipped     => $results->skip,
                    skip_reason => $results->skip_reason,
                    skip_all    => $Strap->{skip_all},
                    ml          => $ml,
                   );

        $tot{bonus}       += $results->bonus;
        $tot{max}         += $results->max;
        $tot{ok}          += $results->ok;
        $tot{todo}        += $results->todo;
        $tot{sub_skipped} += $results->skip;

        my($estatus, $wstatus) = ($results->exit, $results->wait);

        if ($results->passing) {
            # XXX Combine these first two
            if ($test{max} and $test{skipped} + $test{bonus}) {
                my @msg;
                push(@msg, "$test{skipped}/$test{max} skipped: $test{skip_reason}")
                    if $test{skipped};
                push(@msg, "$test{bonus}/$test{max} unexpectedly succeeded")
                    if $test{bonus};
                print "$test{ml}ok$elapsed\n        ".join(', ', @msg)."\n";
            }
            elsif ( $test{max} ) {
                print "$test{ml}ok$elapsed\n";
            }
            elsif ( defined $test{skip_all} and length $test{skip_all} ) {
                print "skipped\n        all skipped: $test{skip_all}\n";
                $tot{skipped}++;
            }
            else {
                print "skipped\n        all skipped: no reason given\n";
                $tot{skipped}++;
            }
            $tot{good}++;
        }
        else {
            # List unrun tests as failures.
            if ($test{'next'} <= $test{max}) {
                push @{$test{failed}}, $test{'next'}..$test{max};
            }
            # List overruns as failures.
            else {
                my $details = $results->details;
                foreach my $overrun ($test{max}+1..@$details) {
                    next unless ref $details->[$overrun-1];
                    push @{$test{failed}}, $overrun
                }
            }

            if ($wstatus) {
                $failedtests{$tfile} = _dubious_return(\%test, \%tot, 
                                                       $estatus, $wstatus);
                $failedtests{$tfile}{name} = $tfile;
            }
            elsif($results->seen) {
                if (@{$test{failed}} and $test{max}) {
                    my ($txt, $canon) = _canonfailed($test{max},$test{skipped},
                                                    @{$test{failed}});
                    print "$test{ml}$txt";
                    $failedtests{$tfile} = { canon   => $canon,
                                             max     => $test{max},
                                             failed  => scalar @{$test{failed}},
                                             name    => $tfile, 
                                             percent => 100*(scalar @{$test{failed}})/$test{max},
                                             estat   => '',
                                             wstat   => '',
                                           };
                }
                else {
                    print "Don't know which tests failed: got $test{ok} ok, ".
                          "expected $test{max}\n";
                    $failedtests{$tfile} = { canon   => '??',
                                             max     => $test{max},
                                             failed  => '??',
                                             name    => $tfile, 
                                             percent => undef,
                                             estat   => '', 
                                             wstat   => '',
                                           };
                }
                $tot{bad}++;
            }
            else {
                print "FAILED before any test output arrived\n";
                $tot{bad}++;
                $failedtests{$tfile} = { canon       => '??',
                                         max         => '??',
                                         failed      => '??',
                                         name        => $tfile,
                                         percent     => undef,
                                         estat       => '', 
                                         wstat       => '',
                                       };
            }
        }

        if (defined $Files_In_Dir) {
            my @new_dir_files = _globdir $Files_In_Dir;
            if (@new_dir_files != @dir_files) {
                my %f;
                @f{@new_dir_files} = (1) x @new_dir_files;
                delete @f{@dir_files};
                my @f = sort keys %f;
                print "LEAKED FILES: @f\n";
                @dir_files = @new_dir_files;
            }
        }
    } # foreach test
    $tot{bench} = timediff(new Benchmark, $run_start_time);

    $Strap->_restore_PERL5LIB;

    return(\%tot, \%failedtests);
}

sub _mk_leader {
    my($te, $width) = @_;
    chomp($te);
    $te =~ s/\.\w+$/./;

    if ($^O eq 'VMS') {
        $te =~ s/^.*\.t\./\[.t./s;
    }
    my $leader = "$te" . '.' x ($width - length($te));
    my $ml = "";

    if ( -t STDOUT and not $ENV{HARNESS_NOTTY} and not $Verbose ) {
        $ml = "\r" . (' ' x 77) . "\r$leader"
    }

    return($leader, $ml);
}

sub _leader_width {
    my $maxlen = 0;
    my $maxsuflen = 0;
    foreach (@_) {
        my $suf    = /\.(\w+)$/ ? $1 : '';
        my $len    = length;
        my $suflen = length $suf;
        $maxlen    = $len    if $len    > $maxlen;
        $maxsuflen = $suflen if $suflen > $maxsuflen;
    }
    # + 3 : we want three dots between the test name and the "ok"
    return $maxlen + 3 - $maxsuflen;
}


sub _show_results {
    my($tot, $failedtests) = @_;

    my $pct;
    my $bonusmsg = _bonusmsg($tot);

    if (_all_ok($tot)) {
        print "All tests successful$bonusmsg.\n";
    }
    elsif (!$tot->{tests}){
        die "FAILED--no tests were run for some reason.\n";
    }
    elsif (!$tot->{max}) {
        my $blurb = $tot->{tests}==1 ? "script" : "scripts";
        die "FAILED--$tot->{tests} test $blurb could be run, ".
            "alas--no output ever seen\n";
    }
    else {
        $pct = sprintf("%.2f", $tot->{good} / $tot->{tests} * 100);
        my $percent_ok = 100*$tot->{ok}/$tot->{max};
        my $subpct = sprintf " %d/%d subtests failed, %.2f%% okay.",
                              $tot->{max} - $tot->{ok}, $tot->{max}, 
                              $percent_ok;

        my($fmt_top, $fmt) = _create_fmts($failedtests);

        # Now write to formats
        for my $script (sort keys %$failedtests) {
          $Curtest = $failedtests->{$script};
          write;
        }
        if ($tot->{bad}) {
            $bonusmsg =~ s/^,\s*//;
            print "$bonusmsg.\n" if $bonusmsg;
            die "Failed $tot->{bad}/$tot->{tests} test scripts, $pct% okay.".
                "$subpct\n";
        }
    }

    printf("Files=%d, Tests=%d, %s\n",
           $tot->{files}, $tot->{max}, timestr($tot->{bench}, 'nop'));
}


my %Handlers = (
    header => \&header_handler,
    test => \&test_handler,
    bailout => \&bailout_handler,
);

$Strap->{callback} = \&strap_callback;
sub strap_callback {
    my($self, $line, $type, $totals) = @_;
    print $line if $Verbose;

    my $meth = $Handlers{$type};
    $meth->($self, $line, $type, $totals) if $meth;
};


sub header_handler {
    my($self, $line, $type, $totals) = @_;

    warn "Test header seen more than once!\n" if $self->{_seen_header};

    $self->{_seen_header}++;

    warn "1..M can only appear at the beginning or end of tests\n"
      if $totals->{seen} && 
         $totals->{max}  < $totals->{seen};
};

sub test_handler {
    my($self, $line, $type, $totals) = @_;

    my $curr = $totals->{seen};
    my $next = $self->{'next'};
    my $max  = $totals->{max};
    my $detail = $totals->{details}[-1];

    if( $detail->{ok} ) {
        _print_ml_less("ok $curr/$max");

        if( $detail->{type} eq 'skip' ) {
            $totals->{skip_reason} = $detail->{reason}
              unless defined $totals->{skip_reason};
            $totals->{skip_reason} = 'various reasons'
              if $totals->{skip_reason} ne $detail->{reason};
        }
    }
    else {
        _print_ml("NOK $curr");
    }

    if( $curr > $next ) {
        print "Test output counter mismatch [test $curr]\n";
    }
    elsif( $curr < $next ) {
        print "Confused test output: test $curr answered after ".
              "test ", $next - 1, "\n";
    }

};

sub bailout_handler {
    my($self, $line, $type, $totals) = @_;

    die "FAILED--Further testing stopped" .
      ($self->{bailout_reason} ? ": $self->{bailout_reason}\n" : ".\n");
};


sub _print_ml {
    print join '', $ML, @_ if $ML;
}


# Print updates only once per second.
sub _print_ml_less {
    my $now = CORE::time;
    if ( $Last_ML_Print != $now ) {
        _print_ml(@_);
        $Last_ML_Print = $now;
    }
}

sub _bonusmsg {
    my($tot) = @_;

    my $bonusmsg = '';
    $bonusmsg = (" ($tot->{bonus} subtest".($tot->{bonus} > 1 ? 's' : '').
               " UNEXPECTEDLY SUCCEEDED)")
        if $tot->{bonus};

    if ($tot->{skipped}) {
        $bonusmsg .= ", $tot->{skipped} test"
                     . ($tot->{skipped} != 1 ? 's' : '');
        if ($tot->{sub_skipped}) {
            $bonusmsg .= " and $tot->{sub_skipped} subtest"
                         . ($tot->{sub_skipped} != 1 ? 's' : '');
        }
        $bonusmsg .= ' skipped';
    }
    elsif ($tot->{sub_skipped}) {
        $bonusmsg .= ", $tot->{sub_skipped} subtest"
                     . ($tot->{sub_skipped} != 1 ? 's' : '')
                     . " skipped";
    }

    return $bonusmsg;
}

# Test program go boom.
sub _dubious_return {
    my($test, $tot, $estatus, $wstatus) = @_;
    my ($failed, $canon, $percent) = ('??', '??');

    printf "$test->{ml}dubious\n\tTest returned status $estatus ".
           "(wstat %d, 0x%x)\n",
           $wstatus,$wstatus;
    print "\t\t(VMS status is $estatus)\n" if $^O eq 'VMS';

    $tot->{bad}++;

    if ($test->{max}) {
        if ($test->{'next'} == $test->{max} + 1 and not @{$test->{failed}}) {
            print "\tafter all the subtests completed successfully\n";
            $percent = 0;
            $failed = 0;        # But we do not set $canon!
        }
        else {
            push @{$test->{failed}}, $test->{'next'}..$test->{max};
            $failed = @{$test->{failed}};
            (my $txt, $canon) = _canonfailed($test->{max},$test->{skipped},@{$test->{failed}});
            $percent = 100*(scalar @{$test->{failed}})/$test->{max};
            print "DIED. ",$txt;
        }
    }

    return { canon => $canon,  max => $test->{max} || '??',
             failed => $failed, 
             percent => $percent,
             estat => $estatus, wstat => $wstatus,
           };
}


sub _create_fmts {
    my($failedtests) = @_;

    my $failed_str = "Failed Test";
    my $middle_str = " Stat Wstat Total Fail  Failed  ";
    my $list_str = "List of Failed";

    # Figure out our longest name string for formatting purposes.
    my $max_namelen = length($failed_str);
    foreach my $script (keys %$failedtests) {
        my $namelen = length $failedtests->{$script}->{name};
        $max_namelen = $namelen if $namelen > $max_namelen;
    }

    my $list_len = $Columns - length($middle_str) - $max_namelen;
    if ($list_len < length($list_str)) {
        $list_len = length($list_str);
        $max_namelen = $Columns - length($middle_str) - $list_len;
        if ($max_namelen < length($failed_str)) {
            $max_namelen = length($failed_str);
            $Columns = $max_namelen + length($middle_str) + $list_len;
        }
    }

    my $fmt_top = "format STDOUT_TOP =\n"
                  . sprintf("%-${max_namelen}s", $failed_str)
                  . $middle_str
                  . $list_str . "\n"
                  . "-" x $Columns
                  . "\n.\n";

    my $fmt = "format STDOUT =\n"
              . "@" . "<" x ($max_namelen - 1)
              . "  @>> @>>>> @>>>> @>>> ^##.##%  "
              . "^" . "<" x ($list_len - 1) . "\n"
              . '{ $Curtest->{name}, $Curtest->{estat},'
              . '  $Curtest->{wstat}, $Curtest->{max},'
              . '  $Curtest->{failed}, $Curtest->{percent},'
              . '  $Curtest->{canon}'
              . "\n}\n"
              . "~~" . " " x ($Columns - $list_len - 2) . "^"
              . "<" x ($list_len - 1) . "\n"
              . '$Curtest->{canon}'
              . "\n.\n";

    eval $fmt_top;
    die $@ if $@;
    eval $fmt;
    die $@ if $@;

    return($fmt_top, $fmt);
}

sub _canonfailed ($$@) {
    my($max,$skipped,@failed) = @_;
    my %seen;
    @failed = sort {$a <=> $b} grep !$seen{$_}++, @failed;
    my $failed = @failed;
    my @result = ();
    my @canon = ();
    my $min;
    my $last = $min = shift @failed;
    my $canon;
    if (@failed) {
        for (@failed, $failed[-1]) { # don't forget the last one
            if ($_ > $last+1 || $_ == $last) {
                push @canon, ($min == $last) ? $last : "$min-$last";
                $min = $_;
            }
            $last = $_;
        }
        local $" = ", ";
        push @result, "FAILED tests @canon\n";
        $canon = join ' ', @canon;
    }
    else {
        push @result, "FAILED test $last\n";
        $canon = $last;
    }

    push @result, "\tFailed $failed/$max tests, ";
    if ($max) {
	push @result, sprintf("%.2f",100*(1-$failed/$max)), "% okay";
    }
    else {
	push @result, "?% okay";
    }
    my $ender = 's' x ($skipped > 1);
    if ($skipped) {
        my $good = $max - $failed - $skipped;
	my $skipmsg = " (less $skipped skipped test$ender: $good okay, ";
	if ($max) {
	    my $goodper = sprintf("%.2f",100*($good/$max));
	    $skipmsg .= "$goodper%)";
        }
        else {
	    $skipmsg .= "?%)";
	}
	push @result, $skipmsg;
    }
    push @result, "\n";
    my $txt = join "", @result;
    ($txt, $canon);
}

1;

__END__

=head1 NAME

Test::Float - Test::Harness modified to accept floating point test result values

=head1 SYNOPSIS

  perl -MTest::Float -e 'Test::Float::test_harness(1, "blib/lib", "blib/arch")' t/*.t

But you probably don't want to use this module instead; instead, use C<float.pl> or create something to replace it
(after reading the docs in there).

L<Test::Float> is a minor part of some stupid code that trains a Markov engine from Perl code then uses a simple genetic programming engine
to write or modify code to pass fitness tests expressed as otherwise normal TAP style Perl tests that instead return floating point values.
L<Test::Float> is the minor part but it's the reusable part so the whole thing is named after it.

All of docs for the stupid Markov/genetic thing are in L<float.pl> -- chdir to the build directory for this module (inside C<~/.cpanm> or C<~./cpan> or whatever) 
and do C<perldoc float.pl> right now!
You need to be in that directory or need stuff from that directory anyway.

  perl float.pl learn /path/to/some/code
  perl float.pl spew 20
  perl float.pl code

=head1 DESCRIPTION

One day, it occured to me that if tests returned floating point values to indicate to
which degree the test was satisified, genetic programming could write your code for you.
L<Test::Float> implements the necessary monkey patches to L<Test::Harness> to accept
floating point values.
Okay, monkey patching fell down on the v2 to v3 L<Test::Harness> and I'm not eager to go
rooting around through there again, so I've just copied the old code in.
This is a modified version of an old L<Test::Harness>.

The included L<float.pl> script, upon different commands, programs a Markov Chains
bot from example code and then runs generations of it with the floating point
tests in C<t/*.t> as the selection criteria for which programs die and which
mutate and breed.

L<float.pl> is sort of like L<prove> in that it's a front-end to the test runner.


=head1 EXPORT

C<&runtests> is exported by Test::Float by default.

C<$verbose>, C<$switches> and C<$debug> are exported upon request.


=head1 HISTORY

0.1 was demo'd at Frozen Perl 2010.

0.2 was the first version released to CPAN.

0.3 fixes a C<die> if you don't have a C<tmp> directory in the current directory for diagnostic/debugging output.  Oops.
Also, permissions were wrong, as usual.

=head1 SEE ALSO

...

=head1 AUTHOR

Scott Walters, E<lt>scott@slowass.netE<gt>, adapted L<Test::Harness> into being
L<Test::Float>.

Preserved from the L<Test::Harness> documentation:

Either Tim Bunce or Andreas Koenig, we don't know. What we know for
sure is, that it was inspired by Larry Wall's TEST script that came
with perl distributions for ages. Numerous anonymous contributors
exist.  Andreas Koenig held the torch for many years, and then
Michael G Schwern.

Current maintainer is Andy Lester C<< <andy at petdance.com> >>.

If you're reading this and there's a bug, mail E<lt>scott@slowass.netE<gt>.

=head1 BUGS

L<float.pl> COULD VERY EASILY QUASI-RANDOMLY GENERATE CODE THAT DELETES ALL OF YOUR DATA OR DOES OTHER VERY BAD THINGS.
DO NOT USE THIS CODE WITHOUT PROPER PRECAUTIONS WHICH I CAN'T EVEN DESCRIBE.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Scott Walters

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.

Copyright 2002-2005
by Michael G Schwern C<< <schwern at pobox.com> >>,
Andy Lester C<< <andy at petdance.com> >>.

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>.

See C<perldoc float.pl> for copyright terms and conditions for the C<float.pl> portion of this package.

=cut

__END__

Code::Splice::inject(
    package => 'Test::Harness::Straps',
    method => '_analyze_line',
    #         $results->inc_ok if $point->pass;
    code => do {
        my $results;
        my $point;
        sub {
            $results->inc_ok($point->ok) if $point->pass;
        }
    },
    precondition => sub {
       my $op = shift;
       my $line = shift or return;
       warn "line: $line\n";
       return if $line =~ m/^\s*if/ or length $line > 100;
       $line =~ m/results/ and $line =~ m/inc_ok/ and $line =~ m/pass/;
    },
);

print B::Deparse->new->coderef2text(\&Test::Harness::Straps::_analyze_line);

* Markov Chains decision trees are naive.  After a couple of node transitions, the
  chance of anything useful coming out approaches nil.

* But GumbyBrain is as good off at writing code as a lot of programmers...
  no time to document side-effects, design logic, etc;
  no time to read the code and tease apart what it does and why; 
  no time to refactor it.
  You're already flying blind.

* Corporate Perl jobs want you to add features to neglected code.


------------------

our test_harness runs test_harness in ExtUtils::Command::MM
E::C::M::test_harness runs Test::Harness::runtests
