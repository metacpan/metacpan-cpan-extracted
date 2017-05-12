# -*-cperl-*-
#
# Copyright 2006-2007 Greg Sabino Mullane <greg@endpoint.com>
#
# Test::Dynamic allows somewhat automatic counting of your tests for Test::More
#

package Test::Dynamic;

use 5.008003;
use utf8;
use strict;
use warnings;

our $VERSION = '1.3.3';

sub count_tests {

	## START_SKIP_TESTCOUNTING

	## Test counting notes:
	## The script must have a __DATA__ line
	## Tests are counted up until the "end" of the script: exit, __DATA__, or __END__
	## Simple test commands are counted as a single item: is, pass, ok, etc.
	## Make sure that test subs use parens: pass("xxx") not pass "xxx"
	## We count how many tests each subroutine runs
	## Some lines are conditional on a global flag for a set of tests: foo(); ## TEST_COPY
	## Conditional blocks can be started and stopped, pure line-by-line basis only
	## Example line 10: foo(); ## START_TEST_COPY  line 20: ## STOP_TEST_COPY
	## Can also use ENV variables with START_ENV_FOO and STOP_ENV_FOO
	## Some lines have multipliers: foobar() ## TESTCOUNT * 5
	## Some have both: foobar() ## TEST_COPY TESTCOUNT + 5
	## To skip entire blocks entirely, use ## START_SKIP_TESTCOUNTING, then ## STOP_SKIP_TESTCOUNTING

	my $self = shift;
	my $arg = shift;

	ref $arg eq 'HASH' or die qq{Argument must be a hashref\n};;

	my $fh = $arg->{filehandle} || die "Need a filehandle argument\n";

	my $verbose_count = exists $arg->{verbose} ? $arg->{verbose} : 1;

	my @testwords = qw(is isnt ok cmp pass fail is_deeply isa_ok can_ok like unlike);

	## no critic
	if (exists $arg->{local}) {
		if (ref $arg->{local} eq 'ARRAY') {
			push @testwords, $_ for @{$arg->{local}};
		}
		elsif (ref $arg->{local} eq 'HASH') {
			push @testwords, $_ for keys %{$arg->{local}};
		}
	}
	## use critic
	my $testwords = join '|' => @testwords;
	$testwords = qr{$testwords};

	my @sublist;
	my %substuff;
	my %subcount;
	my %linemod;
	my %lineskip;
	my %testgroup;
	my $firstline = 0;
	my $lastline = 0;
	for my $pass (1..2) {
		seek($fh,0,0);
		if ($arg->{skipuseline}) {
			1 while <$fh> !~ /^use Test::Dynamic/;
		}
		$firstline ||= $.;
		my $line = $firstline;
		my $currentsub = 'MAIN';
		my $atend = 0;
		my $skipcounting = 0;
		my %skipgroup;
	  T: while (<$fh>) {
			$line++;
			chomp;
			if ($skipcounting) {
				if (/^\s*##\s*STOP_SKIP_TESTCOUNTING/o) {
					$skipcounting=0;
					$verbose_count >= 2 and warn "Found STOP_SKIP at line $line\n";
				}
				next T;
			}
			if (/^\s*##\s*START_SKIP_TESTCOUNTING/o) {
				$verbose_count >= 2 and warn "Found START_SKIP at line $line\n";
				$skipcounting=1;
				next T;
			}

			if (/^\s*exit;/) {
				$atend = 1;
				$lastline ||= $line;
				next T;
			}

			last T if /^__DATA__/ or /^__END__/;

			last T if /\#\#\s*TESTSTOP/;

			next T if $lineskip{$line};

			## Special our lines for test groups
			if (/^our \$(TEST_\w+)\s*=\s*(\d+)/) {
				$testgroup{$1} = $2;
			}


			if (/^}[^;]/ and ! /##/ and @sublist) {
				warn qq{May have a non-closed sub at line $line\n};
			}

			## Starting a new subroutine?
			if (/^\s*sub\s+([\w:_]+)/) {
				$currentsub = $1;
				$verbose_count >= 3 and warn "Sub start: $currentsub\n";
				if (!exists $subcount{$currentsub}) {
					$subcount{$currentsub} = 0;
					$substuff{$currentsub} = {};
				}
				push @sublist, $1;
			}

			## Ending a subroutine?
			if (/##\s+end of (\S+)/o) {
				$verbose_count >= 3 and warn "Sub stop: /$1\n";
				pop @sublist;
				$currentsub = $sublist[-1] || 'MAIN';
			}
			## Skip commented-out lines
			elsif (/^\s*#/) {
				$lineskip{$line} = 1;
				next T;
			}

			if (1 == $pass) {

				## Gather test group information
				if (/##.*?((?:START_|STOP_)?(?:NO)?(?:TEST|ENV)_\S+.*)/o) {
					my $extra = $1;
					$verbose_count >= 2 and warn "Test group: $extra at line $line\n";
					while ($extra =~ m{(START_|STOP_)?(NO)?(TEST|ENV)_(\S+)}g) {
						my ($startstop,$reverse,$type,$name) = ($1||'',$2||0,$3,$4);
						my $val;
						if ('TEST' eq $type) {
							$name = "TEST_$name";
							exists $testgroup{$name} or die qq{Unknown test group "$name" at line $line!\n};
							$val = $testgroup{$name};
						}
						else {
							$val = $ENV{$name} || 0;
						}
						if ($reverse) {
							$val = $val ? 0 : 1;
						}
						if ($startstop eq 'START_') {
							$skipgroup{$name} = $val;
						}
						if ($startstop eq 'STOP_') {
							delete $skipgroup{$name};
						}
						if (!$val) {
							$lineskip{$line} = 1;
							next T;
						}
					}
				}

				## Skip this line if we are in an active skip group
				for my $group (keys %skipgroup) {
					if (!$skipgroup{$group}) {
						$lineskip{$line} = 1;
						next T;
					}
				}

				## Gather any modifiers
				if (/##.*TESTCOUNT\s*([\+\*\-\/])\s*(\d+)/o) {
					$linemod{$line} = [$1,$2];
					## Quick test for no-op adjustments
					if (/^\s*;\s*##/o and !$lineskip{$line}) {
						my $testcount = 0;
						my ($y,$z) = @{$linemod{$line}};
						if    ($y eq '*') { $testcount *= $z; }
						elsif ($y eq '-') { $testcount -= $z; }
						elsif ($y eq '/') { $testcount /= $z; }
						else              { $testcount += $z; }
						$subcount{$currentsub} += $testcount;
						delete $linemod{$line};
					}
				}

				## Count up simple test functions and assign them to a sub
				if (/^\s*$testwords\s*\(/o) {
					## Do nothing if in MAIN and the script has ended
					next T if $currentsub eq 'MAIN' and $atend;

					my $testcount = 1;
					if (exists $linemod{$line}) {
						my ($y,$z) = @{$linemod{$line}};
						if    ($y eq '*') { $testcount *= $z; }
						elsif ($y eq '-') { $testcount -= $z; }
						elsif ($y eq '/') { $testcount /= $z; }
						else              { $testcount += $z; }
					}
					$verbose_count >= 2 and warn "Simple count for $currentsub by $testcount\n";
					$subcount{$currentsub} += $testcount;
					$lineskip{$line} = 1;
				}

				next T;
			} ## end first pass

			if (2 == $pass) {
				## At this point, we know the names of our subroutines
				## We count up the dependencies for each sub
				while ($_ =~ /\b([\w:_]+)\s*\(/g) {
					my $sub = $1;
					next if ! exists $subcount{$sub};
					$sub eq $currentsub
						and die qq{Recursive sub "$sub" at $line: perhaps you forgot "## end of $sub"?\n};
					$verbose_count >= 3 and warn "Adding $sub to $currentsub at line $line\n";
					$substuff{$currentsub}{$sub}{$line} = 1;
				}
				next T;
			}
		}
	} ## end two passes

	## Only worry about the ones called by MAIN
	my %subs = (MAIN => 0);

	my %subtrace = (0 => 'MAIN');
	for my $sub (keys %{$substuff{MAIN}}) {
		for my $line (keys %{$substuff{MAIN}{$sub}}) {
			$subtrace{$line} = $sub;
		}
	}

	my %linecount;
	my $loopy=0;
	{
		## Get a final count for each sub
		my $stilltodo = 0;
		$verbose_count >= 3 and warn "==Entering loop\n";
		for my $sub (sort keys %subs) {
			next if $subs{$sub};
			my $oldscore = $subcount{$sub};
			if (keys %{$substuff{$sub}}) {
				$stilltodo++;
				$verbose_count >= 3 and warn "Need final score for $sub (currently $oldscore)\n";
			}
			else {
				$verbose_count >= 3 and warn "Skipping $sub, has no dependencies\n";
			}
			for my $isub (keys %{$substuff{$sub}}) {
				$subs{$isub} = 0 if !exists $subs{$isub};
				## Does this inner have a raw score?
				my $subitems = keys %{$substuff{$isub}};
				$verbose_count >= 3 and warn "  Checking inner sub $isub ($subcount{$isub}) Items=$subitems\n";
				next if $subitems;
				for my $line (sort {$a<=>$b} keys %{$substuff{$sub}{$isub}}) {
					my $basescore = $subcount{$isub};
					$linecount{$line} = $basescore;
					if (exists $linemod{$line}) {
						my ($y,$z) = @{$linemod{$line}};
						if    ($y eq '*') { $basescore *= $z; }
						elsif ($y eq '-') { $basescore -= $z; }
						elsif ($y eq '/') { $basescore /= $z; }
						else              { $basescore += $z; }
					}
					if ($sub ne 'MAIN' or ($line < $lastline)) {
						$subcount{$sub} += $basescore;
						$linecount{$line} = $basescore;
						$verbose_count >= 3 and warn "    Boost count for $sub by $basescore due to line $line\n";
					}
				}
				## Remove from the list
				$verbose_count >= 3 and warn "  Finished with $isub, so removed from list for $sub\n";
				delete $substuff{$sub}{$isub};
			}
			$verbose_count >= 3 and $subcount{$sub} != $oldscore and warn "New final score for $sub: $subcount{$sub}\n";
		} ## end each sub

		if ($loopy++ > 100) {
			die "Too many loops while trying to figure out test counts";
		}
		redo if $stilltodo;
	}

	if ($verbose_count >= 1) {
		my ($maxline,$maxcount,$maxsub,$maxmod,$maxfinal) = (1,1,3,5,1);
		my @niceline;
		for my $line (sort {$a<=>$b} keys %subtrace) {
			my $sub = $subtrace{$line};
			my $mod = exists $linemod{$line} ? " $linemod{$line}[0] $linemod{$line}[1]" : '';
			my $count = exists $linemod{$line} ? $linecount{$line} : '';
			my $final = exists $linemod{$line} ? $linecount{$line} : $subcount{$sub};
			$maxline  = length($line)  if length($line)  > $maxline;
			$maxcount = length($count) if length($count) > $maxcount;
			$maxsub   = length($sub)   if length($sub)   > $maxsub;
			$maxmod   = length($mod)   if length($mod)   > $maxmod;
			$maxfinal = length($final) if length($final) > $maxfinal;
			push @niceline, [$line,$count,$mod,$final,$sub];
		}
		my $total = -$niceline[0]->[3];
		warn "TEST COUNT:\n";
		for (@niceline) {## 20 * 4 = 80
			$total += $_->[3];
			splice @$_,4,0,$total;
			my $msg = sprintf
				"Line %${maxline}d: (%${maxcount}s%-${maxmod}s = %${maxfinal}d) [%${maxfinal}d] %-${maxsub}s\n", @$_;
			warn $msg;
		}
	}

	$verbose_count >= 1 and warn "Total tests: $subcount{MAIN}\n";

	return $subcount{MAIN};

	## STOP_SKIP_TESTCOUNTING

} ## end of count_tests

1;

__END__

=pod


=head1 NAME

Test::Dynamic - Automatic test counting for Test::More

=head1 VERSION

This documents version 1.3.3 of the Test::Dynamic module

=head1 SYNOPSIS

  use Test::More;
  use Test::Dynamic;

  my $tests = Test::Dynamic::count_tests
	(
	 {
	  filehandle => \*DATA,
	  verbose    => 1,
	  local      => [qw(compare_tables)]
	  }
	 );

  plan tests => $tests;

  __DATA__



=head1 DESCRIPTION

This module helps to count your tests for you in an automatic way. When you add 
or remove tests, Test::Dynamic will attempt to keep track of the total correct 
number for you.

=head2 Methods

=over 4

=item B<count_tests>

Creates a Test::Dynamic instance and attempts to count the number of tests performed 
in the supplied code. Note that this method is I<not> exported by default.

=back

=head2 Arguments

The C<count_tests> method takes the following arguments:

=over 4

=item B<filehandle>

Mandatory argument. An open filehandle to the file that contains the tests you want to 
count. Usually, this is the same file you are already in. One way to provide your own 
file is to give the filehandle argument the value C<\*DATA>. If you do so, you must 
also ensure that your script has a C<__DATA__> section at the bottom of it.

=item B<verbose>

Optional argument, defaults to false. If true, detailed information is sent to stderr 
showing how many tests were found in each section, and generally allowing you to see how 
Test::Dynamic arrived at its final test count.

=item B<local>

Optional, empty by default. Test::Dynamic looks for simple test commands such as C<cmp_ok> 
and counts them as a single test. If you have your own tests, or subroutines that perform a test, 
you can add your own here which will be counted as a single test for purposes of counting.  
The input should be an arrayref of terms, for example:

  local => [qw/foo bar baz/]

=item B<skipuseline>

Optional, empty by default. If set, all lines until one that begins with 'use Test::Dynamic' 
are skipped.

=back

=head1 USAGE

=head2 Basic test counting

Test::Dynamic works by looking for basic test methods, such as C<cmp_ok()>, but allows you to 
define your own methods as well with the C<local> argument. Test counting stops then 
C<__DATA__>, C<__END__>, or the word C<exit;>" is found. All test methods must be called 
with parens: C<pass("xxx");> will work, but C<pass "xxx";> will not. Test methods must 
appear at the start of the line, although whitespace is allowed, of course.

=head2 Subroutines

An important part of counting the tests is keeping track of which subroutines are used and where. 
Since subroutines can be nested within each other, Test::Dynamic needs to know exactly where a 
subroutine ends. After the closing brace in a subroutine, add the following:

  ## end of subroutine_name

For example:

  sub foobar {
    my $name = shift;
    return Baz->mangle($name);
  } ## end of foobar

=head2 Adjusting the current test count

The number of tests that a subroutine within the script calls is kept track of, and each 
call to that subroutine increments the number of tests by the amount in that subroutine. 
For example:

  cmp($x, $y, "Foo and bar are equal");

  pickle();

  sub pickle {
    pass("Pickle is ok");
    is_deeply($d,$e, "Complex hashrefs look the same");
  }

In the above, Test::Dynamic will count the number of tests as three.

Comments with two hashes can be used to further control the behavior. To tell 
Test::Dynamic that a particular line of code will run more than one test, 
such as in a loop, you can use the C<TESTCOUNT> parameter:

  for my $x (1..10) {
    like($foo{$x}, qr{pickle}, "Item $x contains a pickle"); ## TESTCOUNT * 10
  }

Any of the basic math multipliers can be used: addition, subtraction, multiplication, 
or division. Addition and subtraction are handy for times when the number of tests needs 
to be adjusted on the fly without anything else on the line:

  ## TESTCOUNT + 6

=head2 Skipping sections

Entire sections of code can be skipped entirely for the purposed of test counting. 
Simply add C<## START_SKIP_TESTCOUNTING> to a line, and add C<## STOP_SKIP_TESTCOUNTING> 
when you wish the counting to pick up again.

=head2 Group modifiers

If you are working on a large test script, sometimes you may want to limit your current 
testing to not include some related groups of tests. To do this with test_counting, 
create global variables name C<$TEST_name> at the top of your script, then assign them 
either a 1 or a 0 to indicate that the sections are on or off. Then add that name as 
a comment to each line that invokes it. For example:

  our $TEST_ALPHA = 1;
  our $TEST_DELTA = 0;

  pass("red");
  pass("blue"); ## TEST_ALPHA
  pass("yellow"); ## TEST_DELTA

In the above example, the "yellow" test will not be counted, because it belongs to the 
TEST_DELTA group, which is off. 

Adding C<START_> and C<STOP_> before the group name allows you to associate a block of 
code with a named section: this is usually used in conjunction with an C<if> statement 
telling those tests not to run. For example:

  if ($TEST_DELTA) { ## START_TEST_DELTA
     cmp($x,$y, "Values are the same");
     ## Time-consuming tests here...
  } ## STOP_TEST_DELTA


Note that lines may contain more than one control comment, such as: 

foo(3,42); ## TEST_DELTA TESTCOUNT + 10

=head2 Environment groupings

A named group can also be controlled by an environment variable. The format is 
C<## ENV_name>, or C<## START_ENV_name> and C<##STOP_ENV_name>.

=head2 No-op lines

If you put a comment on a line with only a single semi-colon at the start of it, this 
line will be evaluated right away for any TESTCOUNT effects. For example, to add 24 
tests if the environment variable BUCARDO_TEST_RING is set:

  ;## ENV_BUCARDO_TEST_RING       TESTCOUNT+24

=head2 Negation

The group and environment modifiers can be negated by using NOTEST and NOENV. When combined with 
a no-op TESTCOUNT line, this can be an easy way to adjust the tests based on if, for example, 
an ENV variable is set:

  ; ## NOENV_FOOBAR TESTCOUNT - 10;

In the example above, the total number of tests is reduced by 10 unless the environment 
variable has been set.

=head1 LIMITATIONS

This module is not going to be perfect at test counting every time - a task which 
would require Artificial Intelligence - but is designed to make your task easier. 

For a small and simple test script, use of Test::Dynamic may be overkill.

=head1 BUGS

Bugs should be reported to the author.

=head1 WEBSITE

The latest information on this module can be found at:

  http://bucardo.org/test_dynamic/

=head1 DEVELOPMENT

The latest development version can be checked out via git as:

  git-clone http://bucardo.org/testdynamic.git/

=head1 AUTHOR

Greg Sabino Mullane <greg@endpoint.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2006-2007 Greg Sabino Mullane <greg@endpoint.com>.

This software is free to use: see the LICENSE file for details.

=cut
