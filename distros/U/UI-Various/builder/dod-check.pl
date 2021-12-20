#!/usr/bin/perl
#
# Author, Copyright and License: see end of file

=head1 NAME

dod-check.pl - check Definition of Done

=head1 SYNOPSIS

    dod-check.pl
    dod-check.pl 1 2 3 4 5 8 9

=head1 ABSTRACT

This helper script checks if the current snapshot of C<UI::Various>
satisfies the Definition of Done and therefore is ready for distribution.

With one or more numbers given on the command-line it only runs the
specified tests.

=head1 DESCRIPTION

The script checks the following Definition of Done:

=over

=item The build must run without any error.

=item C<L<update-language.pl> --check> must produce an empty report.

=item All tests must run without any error.

=item All tests must have real plans (no C<done_testing>).

=item All regular expressions in the tests must match fully.

=item Test coverage must be 100% except for the list of uncoverable items in
C<confess-uncoverable.lst> and those marked as C<>.

=item All POD tests must run without any error.

=item All POD coverage tests must run without any error.

=item All cross-reference links in the generated HTML pages must be correct.

=item to be continued (TODO)

=back

That the script can be run from anywhere, it knows the relative path to the
C<UI::Various>'s root directory.

=cut

#########################################################################

##################
# load packages: #
##################

use v5.12;
use strictures;
no indirect 'fatal';
no multidimensional;
use warnings 'once';

use Cwd 'abs_path';
use File::Find;
use File::Remove;

#########################
# predefined constants: #
#########################

# path to package and some of its files / paths:
use constant ROOT_PATH => map { s|/[^/]+/[^/]+$||; $_ } abs_path($0);
use constant EGREP_CLEAN_CODE =>
    "grep --recursive --extended-regexp --line-number '[ \t]+\$' " .
    'examples lib t';
use constant UNCOVERABLE => ROOT_PATH . '/builder/confess-uncoverable.lst';
use constant FGREP_UNCOVERABLE =>
    ('grep', '--recursive', '--fixed-strings', '--after=1', '--include=*.pm',
     'uncoverable', 'lib');
use constant HTML_ROOT => ROOT_PATH . '/blib/libhtml/site/lib';

use constant BOLD_RED	=> "\e[1;31m";
use constant RESET	=> "\e[0m";

########################
# function prototypes: #
########################

sub _error(@);
sub _warn(@);
sub _info(@);
sub run_and_check($$$@);
sub check_fixmes_todos();
sub check_own_links();
sub check_uncoverable();
sub check_unit_tests();

###############
# run checks: #
###############

my $tests;
BEGIN  {  $tests = 14;  }
use Test::More tests => $tests;

my $test_default = 0 == @ARGV ? 1 : 0;
my %test = map { ($_ => $test_default) } 1..$tests;
foreach (@ARGV)
{
    m/^[1-9][0-9]*$/  or  die "bad non-numeric argument '$_'\n";
    $test{$_} = 1;
}
my $n = 0;

chdir ROOT_PATH  or  die "couldn't chdir to ", ROOT_PATH, ': ', $!, "\n";

File::Remove::remove(\1, 'blib', 'cover_db', 'pod2htmd.tmp');

# function to skip or run code and - in case of errors - skip rest / exit:
sub skip_or_run($$$)
{
    my ($test, $resolve, $action) = @_;
    my $exit = 0;
 SKIP: {
	if ($test{++$n})
	{
	    unless (&$action)
	    {
		if ($resolve =~ s/^-//)
		{   _warn $resolve;   }
		else
		{   $exit = 1;   skip $resolve, $tests - $n;   }
	    }
	}
	else
	{   skip $test, 1;   }
    }
    0 == $exit  or  exit $exit;
}

skip_or_run('check clean code', '1st check code for cleanliness',
	    sub {
		# return code 1 == no match:
		run_and_check('check clean code', EGREP_CLEAN_CODE, 1 << 8);
	    });

skip_or_run('Build.PL', 'check this weird error',
	    sub {
		run_and_check
		    ('Build.PL', 'perl Build.PL', 0,
		     'Created MYMETA.yml and MYMETA.json',
		     "Creating new 'Build' script for 'UI-Various' version .*");
	    });

skip_or_run('build', 'repair build 1st',
	    sub {
		run_and_check('build', './Build', 0, 'Building UI-Various');
	    });

skip_or_run('check EN messages', 'fix EN language source 1st',
	    sub {
		run_and_check('check EN messages',
			      './builder/update-language.pl --check',
			      0);
	    });

skip_or_run('tests', 'repair tests 1st',
	    sub {
		run_and_check('tests', './Build test', 0,
			      '# Testing UI::Various .* Perl v5\..*',
			      't/\d\d-.*\.t \.+ ok *$+',
			      'All tests successful\.',
			      'Files=\d+, Tests=\d+, .*',
			      'Result: PASS');
	    });

skip_or_run('check unit tests', 'finish tests 1st',
	    sub {   check_unit_tests();   });

skip_or_run('update Minilla', 'repair tests 1st',
	    sub {
		run_and_check
		    ('update Minilla', 'minil test', 0,
		     '[^C].*$+',
		     'Creating working directory: .*',
		     '[^C].*$+',
		     'Created MYMETA.yml and MYMETA.json',
		     "Creating new 'Build' script for 'UI-Various' version .*",
		     '[^B].*$+',
		     'Building UI-Various',
		     '[^t][^/].*$+',
		     't/\d\d-.*\.t \.+ ok *$+',
		     'All tests successful\.',
		     'Files=\d+, Tests=\d+, .*',
		     'Result: PASS',
		     'Removing .*');
	    });

skip_or_run('Build.PL again', 'check this even weirder error',
	    sub {
		run_and_check
		    ('Build.PL again', 'perl Build.PL', 0,
		     'Created MYMETA.yml and MYMETA.json',
		     "Creating new 'Build' script for 'UI-Various' version .*");
	    });

skip_or_run('cross-check uncoverable',
	    "don't cheat test coverage (or update " . UNCOVERABLE . ')',
	    sub { check_uncoverable(); });

# disabled due to a probable bug in Devel::Cover:
skip_or_run('test coverage', '-improve test coverage',
	    sub {
		run_and_check('test coverage', './Build testcover', 0,
			      '# Testing UI::Various .* Perl v5\..*',
			      't/\d\d-.*\.t \.+ ok *$+',
			      'All tests successful.',
			      'Files=\d+, Tests=\d+, .*',
			      'Result: PASS',
			      'Reading database from .*',
			      '^$+',
			      '^-----.*',
			      '^File .*',
			      '^-----.*',
			      '.* 100.0$+',
			      '^-----.*',
			      '^$+',
			      '^HTML output written to .*',
			      'done\.');
	    });

skip_or_run('POD tests', 'fix documentation',
	    sub {
		run_and_check('POD tests', './Build testpod', 0,
			      '1\.\.\d+',
			      'ok \d+ - POD test for blib/lib/UI/Various.*$+');
	    });

skip_or_run('POD coverage', 'improve documentation',
	    sub {
		run_and_check('POD coverage', './Build testpodcoverage', 0,
			      '1\.\.\d+',
			      'ok \d+ - Pod coverage on UI::Various.*$+');
	    });

# Module::Build::Base (0.4231) sets an incomplete (missing vendor / arch)
# and partly wrong (there is an additional "lib" under "libhtml/site")
# podpath in htmlify_pods.  So we ignore all errors here and check our own
# links later.  (Note that this only works correctly with a patched
# Module/Build/Base.pm!)
skip_or_run('build HTML', 'repair generation of HTML pages',
	    sub {
		run_and_check('build HTML', './Build html', 0,
			      'Cannot find .* in podpath: .*$+');
	    });

skip_or_run('check HTML', 'fix broken links',
	    sub {   check_own_links();   });

check_fixmes_todos();

# relax strict ulimit:
system(qw(chmod --recursive --changes a+rX
	  Build.PL Changes LICENSE META.json README.md
	  builder cpanfile examples lib minil.toml t));


#########################################################################
#########################################################################
########		internal functions following		#########
#########################################################################
#########################################################################

=head1 INTERNAL FUNCTIONS

=cut

#########################################################################

=head2 _error / _warn / _info - print error or warning

    _error(@text);
    _warn(@text);

=head3 parameters:

    @text       main text of error / warning / information

=head3 description:

This function prints the given text in  with a corresponding prefix and
followed by a newline using the standard Perl error / warning
functions otherwise.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub _error(@)
{   print STDERR BOLD_RED, "*******\t", @_, RESET, " *******\n";   }
sub _warn(@)
{   print STDERR BOLD_RED, @_, RESET, "!\n";   }
sub _info(@)
{   print STDERR map { "\t".$_ } @_;   }

#########################################################################

=head2 run_and_check - run command and check return code / output

    run_and_check($description, $command, $return_code, @re_expected_output);

=head3 example:

    run_and_check('building', './Build', 0, '^Building UI-Various$');

=head3 parameters:

    $description        a (unique!) short text describing the test
    $command            the command that is run (usually C<./Build ...>>)
    $return_code        the expected return code (usually C<0>>)
    @re_expected_output the expected output (combined STDOUT/STDERR),
                        must match whole line

=head3 description:

This function runs the command and checks both return code and its output
against the expected output.  The tests are run as sub-tests of one major
test.

Note that lines in the expected output (C<@re_expected_output>) can be
marked as optional by ending the regular expression with C<$?>.  In addition
they can be marked as repeatedly by ending the regular expression with
C<$+>.

=head3 returns:

1 if no problem could been found, 0 otherwise

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub run_and_check($$$@)
{
    my ($description, $command, $return_code, @re_expected_output) = @_;
    my $return = 0;
    local $_;

    sub upcoming_match($@)
    {
	my ($line, @re_expected_rest) = @_;
	local $_;
	my $i = 0;
	while (defined $re_expected_rest[$i])
	{
	    $_ = $re_expected_rest[$i];
	    if (s/\$([?+])$//  and  $line !~ m/$_/n)
	    {
		$i++;
		next;
	    }
	    return $line =~ m/$_/n ? $i : undef;
	}
	return undef;
    }

    0 == @re_expected_output  and  @re_expected_output = ('^$');
    subtest $description => sub{
	my @output = `$command 2>&1`;
	is($?, $return_code, '"' . $command . '" runs without error');
	unless ($? == $return_code)
	{
	    _error(($? & 0x7f) ? 'SIGNAL ' . $? & 0x7f . ' ' : '',
		   ($? & 0x80) ? 'COREDUMP ' : '',
		   'RC ', ($? >> 8 == 255 ? -1 : $? >> 8));
	    _info @output;
	    return;
	}
	my $errors = 0;
	my $ie = 0;			# index for expected output
	foreach my $io (0..$#output)	# index for real output
	{
	    $_ = $re_expected_output[$ie];
	    unless (defined $_)
	    {
		fail('running out of expected output');
		$errors++;
		last;
	    }
	    s/\$([?+])$//;
	    my $offset = $1;
	    s/^\^//;
	    $_ = '^(?:' . $_ . ')$';
	    my $message = 'line ' . ($io + 1) . ' OK';
	    my $line = $output[$io];
	    if ($line =~ m/$_/n)
	    {
		like($line, qr/$_/n, $message);
		$ie++ unless defined $offset  and  $offset eq '+';
	    }
	    elsif (defined $offset  and  $offset eq '+')
	    {
		my $next =
		    upcoming_match
		    ($line,
		     @re_expected_output[ $ie + 1  ..  $#re_expected_output ]);
		if (defined $next)
		{
		    $ie += $next + 1;
		    redo;
		}
		like($line, qr/$_/n, $message);
		$line =~ m/$_/n  or  $errors++;
	    }
	    elsif (defined $offset  and  $offset eq '?')
	    {
		die 'TODO';
	    }
	    else
	    {
		like($line, qr/$_/n, $message);
		$line =~ m/$_/n  or  $errors++;
	    }
	}
	$errors == 0  and  $return = 1;
    };
    return $return;
}

#########################################################################

=head2 check_fixmes_todos - check (count) FIXMEs and TODOs

    check_fixmes_todos();

=head3 description:

This function checks the Perl sources for FIXMEs and TODOs (uppercase and
whole words!) and counts and reports them.

=head3 returns:

1 if none could be found, 0 otherwise

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub check_fixmes_todos()
{
    my ($fixmes, $todos) = (0, 0);
    local $_;

    find(sub {
	     return unless m/\.(p[lm]|t)$/n;
	     open SRC, '<', $File::Find::name  or  die "can't open $_: $!\n";
	     while (<SRC>)
	     {
		 $fixmes++ while s/\bFIXME\b//;
		 $todos++ while s/\bTODO\b//;
	     }
	     close SRC  or  die "can't close $File::Find::name: $!\n";
	 },
	 ROOT_PATH . '/examples',
	 ROOT_PATH . '/lib',
	 ROOT_PATH . '/t',
	);

    if ($fixmes > 0  or  $todos > 0)
    {
	print(STDERR
	      "\n", 'In addition there are ', $fixmes, ' FIXMEs and ', $todos,
	      ' TODOs left, check them in ', ROOT_PATH, " with:\n",
	      'egrep --recursive --include=*.p[lm] --include=*.t ',
	      "'\\<(FIXME|TODO)\\>' examples lib t\n\n");
	return 0;
    }
    return 1;
}

#########################################################################

=head2 check_own_links - check links between own HTML pages

    check_own_links();

=head3 description:

This function checks the HTML pages generated by L<pod2html> (using the
command C<./Build html>).  All links within or between the pages of the
package itself are checked for (approximate) correctness.  (The file path is
still wrong, but we ignore that for now.)

=head3 returns:

1 if no clear error could be found, 0 otherwise

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub check_own_links()
{
    my $return = 1;
    local $_;

    my $html_root = HTML_ROOT;
    my %name = ();
    my %href = ();
    # step 1: find all links and possible targets:
    find(sub {
	     return unless m/\.html$/;
	     open H, '<', $File::Find::name  or  die "can't open $_: $!\n";
	     (my $name = $File::Find::name) =~ s|^$html_root/||o;
	     while (<H>)
	     {
		 $name{"$name#$1"} = $.
		     while s/<(?:body|dt|h[1-4]) id="([^"]+)">//;
		 while (s/<a href="([^"]+)"//)
		 {
		     my $url = $1;
		     if ($url =~ m/^#/)
			 {
			     $url = "$name$url";
			 }
		     elsif (not $url =~ s|^.*$html_root/||)
			 {
			     next;
			 }
		     defined $href{$url}  or  $href{$url} = [];
		     push @{$href{$url}}, "$name:$.";
		 }
	     }
	     close H  or  die "can't close $File::Find::name: $!\n";
	 },
	 $html_root);
    # step 2: find links not having a corresponding target:
    my ($urls, $errors) = (0, 0);
    foreach my $url (sort keys %href)
    {
	$urls += @{$href{$url}};
	next if defined $name{$url};
	$errors++;
	_error 'bad link';
	_info @{$href{$url}}, '=> ' . $url;
	$return = 0;
    }
    subtest 'check HTML' => sub{
	ok($urls > 150, 'found >> 150 URLs');
	is($errors, 0, 'no errors in ' . $urls . ' URLs');
    };
    return $errors == 0;
}

#########################################################################

=head2 check_uncoverable - check that all tests are correctly planned

    check_uncoverable();

=head3 description:

This function checks the Perl test sources for the following ... and reports

 missing test plans and
reports them.

=head3 returns:

1 if all tests are planned, 0 otherwise

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub check_uncoverable()
{
    local $_;
    my %uncoverable = ();
    open UC, '<', UNCOVERABLE
	or  die "can't open ", UNCOVERABLE, ': ', $!, "\n";
    my $location = '';
    while (<UC>)
    {
	s/\r//;
	if (m/^--$/  or  eof UC)
	{   $uncoverable{$location} = 0;   $location = '';   }
	else
	{   $location .= $_;   }
    }
    close UC  or  die "can't close ", UNCOVERABLE, ': ', $!, "\n";
    $location eq ''  or  die 'internal error';

    my $errors = 0;
    subtest 'cross-check uncoverable' => sub{
	open UC, '-|', FGREP_UNCOVERABLE
	    or  die "can't run ", FGREP_UNCOVERABLE, ': ', $!, "\n";
	while (<UC>)
	{
	    s/\r//;
	    if (m/^--$/  or  eof UC)
	    {
		if ($location =~ m/ uncoverable .* # TODO/)
		{}
		elsif (defined $uncoverable{$location})
		{
		    ok(1, "found expected location");
		    $uncoverable{$location}++;
		}
		else
		{
		    fail("found unexpected uncoverable location:\n" . $location);
		    $errors++;
		}
		$location = '';
	    }
	    else
	    {   $location .= $_;   }
	}
	foreach (sort keys %uncoverable)
	{
	    1 == $uncoverable{$_}  and  next;
	    if (0 == $uncoverable{$_})
	    {
		fail("didn't found expected uncoverable location:\n" . $_);
		$errors++;
	    }
	    else
	    {
		fail('found expected uncoverable location ' . $uncoverable{$_} .
		     " times:\n" . $_);
		$errors++;
	    }
	}
	close UC  or  die "can't close ", FGREP_UNCOVERABLE, ': ', $!, "\n";
    };
    return $errors == 0;
}

#########################################################################

=head2 check_unit_tests - check that all tests are correctly planned

    check_unit_tests();

=head3 description:

This function checks the Perl test sources for the following ... and reports

 missing test plans and
reports them.

=head3 returns:

1 if all tests are planned, 0 otherwise

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub check_unit_tests()
{
    local $_;
    my $errors = 0;

    subtest 'check unit tests' => sub{
	my @tests = glob(ROOT_PATH . '/t/*.t');
	foreach my $test (@tests)
	{
	    my ($test_plan, $done_testing) = (0, 0);
	    open SRC, '<', $test  or  die "can't open ", $test, ': ', $!, "\n";
	     while (<SRC>)
	     {
		 $test_plan++
		     if  m/^\s*use\s+Test::More\s+tests\s*=>\s*\d+\d*;/
		     or  m/^\s*plan\s+tests\s*=>\s*\d+\d*;/;
		 $done_testing++  if  m/^\s*done_testing\b/;
		 if (m|\bqr/|)
		 {
		     my $tl = $test . ', line ' . $.;
		     unless (m|^\s*my \$re_msg_tail|)
		     {
			 unlike($_, qr|\bqr/[^^]|,
				"regular expression starts with '^' $tl");
		     }
		     unless (m|\$re_msg_tail(_\w+)?/|n)
		     {
			 unlike($_, qr|[^\$]\/[;,]$|,
				"regular expression ends with '\$' $tl");
		     }
		 }
	     }
	    close SRC  or  die "can't close ", $test, ': ', $!, "\n";
	    is($test_plan, 1, 'tests are planned (exactly once) in ' . $test);
	    is($done_testing, 0, 'no "done_testing" in ' . $test);
	    $errors++  unless  $test_plan == 1  and  $done_testing == 0;
	}
    };
    return $errors == 0;
}

#########################################################################
#########################################################################

=head1 SEE ALSO

C<L<UI::Various::language::en>>

=head1 LICENSE

Copyright (C) Thomas Dorner.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.  See LICENSE file for more details.

=head1 AUTHOR

Thomas Dorner E<lt>dorner@cpan.orgE<gt>

=cut
