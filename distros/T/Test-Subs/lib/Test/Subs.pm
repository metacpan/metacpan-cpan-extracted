package Test::Subs;
our $VERSION = '0.08';
use strict;
use warnings;
use feature 'switch';
use parent 'Exporter';
use Filter::Simple;
use Carp;
use Pod::Checker;
use File::Basename;
use File::Spec::Functions;
use List::MoreUtils 'any';


our @EXPORT = ('test', 'todo', 'not_ok', 'match', 'fail', 'failwith', 'comment',
		'debug', 'test_pod', 'skip'
	);

my (@tests, @todo, @comments,@pods);
my ($has_run, $is_running);

my $debug_mode = 0;
my $pod_warn_level = 1;
my $path_to_lib = './lib';

sub debug_mode (;$) {
	my $r = $debug_mode;
	$debug_mode = ($_[0] ? 1 : 0) if @_;
	return $r;
}

sub path_to_lib (;$) {
	my $r = $path_to_lib;
	return $r if not @_;
	if (defined $_[0]) {
		if (file_name_is_absolute($_[0])) {
			$path_to_lib = $_[0];
		} else {
			$path_to_lib = catdir(dirname($0), $_[0]);
		}
		if (not -d $path_to_lib) {
			my $v = $path_to_lib;
			$path_to_lib = $r;
			croak "Cannot find directory '${v}'" ;
		}
	} else {
		undef $path_to_lib;
	}
	return $r;
}

sub pod_warn_level (;$) {
	my $r = $pod_warn_level;
	return $r if not @_;
	if (defined $_[0] && $_[0] =~ m/^\s*(\d+)\s*$/) {
		$pod_warn_level = $1;
	} else {
		$pod_warn_level = $_[0] ? 1 : 0;
	}
	return $r;
}

sub check_text {
	my ($t) = @_;

	if ($t) {
		$t =~ m/^(?: - )?([^\n]*)/;
		return " - $1";
	} elsif (not defined $t) {
		my ($package, $filename, $line) = caller(1);
		return " - $filename at line $line";
	} else {
		return '';
	}
}

sub check_run {
	my @c = caller(0);

	if ($is_running) {
		croak "You cannot call '$c[3]' inside of an other test"
	} elsif (any { m/__BAD_MARKER__/ } @_) {
		croak "Improper syntax, you may have forgotten a ';'"
	}
}

sub debug (&;$) {
	my ($v, $t) = @_;
	&check_run;

	push @tests, {
			code => sub {
					my $r = eval { $v->() };
					print STDERR $@ if $@;
					$r
				},
			text => check_text($t)
		};

	return '__BAD_MARKER__';
}

sub test (&;$) {
	my ($v, $t) = @_;
	&check_run;
	goto &debug if debug_mode;

	push @tests, {
			code => sub { eval { $v->() } },
			text => check_text($t)
		};

	return '__BAD_MARKER__';
}

sub match (&$;$) {
	my ($v, $re, $t) = @_;

	&check_run;

	$re = qr/$re/ if not ref $re;
	push @tests, {
			code => sub {
					my $r = eval { $v->() };
					if ($@) {
						print STDERR $@ if debug_mode;
						return;
					} elsif (not defined $r) {
						print STDERR "test sub returned 'undef'\n" if debug_mode;
						return;	
					} elsif ($r =~ m/$re/) {
						return 1;
					} else {
						print STDERR "'$r' does not match '$re'\n" if debug_mode;
						return;
					}
				},
			text => check_text($t)
		};

	return '__BAD_MARKER__';
}

sub todo (&;$) {
	&check_run;
	push @todo, (scalar(@tests) + 1);
	goto &test;

	return '__BAD_MARKER__';
}

sub not_ok (&;$) {
	my $v = $_[0];

	&check_run;

	push @tests, {
			code => sub {
					my $r = eval { $v->() };
					if ($@) {
						print STDERR $@ if debug_mode;
						return;
					} elsif ($r) {
						print STDERR "Test sub returned '$r', expected a false value\n" if debug_mode;
						return;
					} else {
						return 1;
					}
				},
			text => check_text($_[1])
		};

	return '__BAD_MARKER__';
}

sub failwith (&$;$) {
	my ($v, $re, $t) = @_;

	&check_run;

	$re = qr/$re/ if not ref $re;
	push @tests, {
			code => sub {
					eval { $v->() };
					if ($@ && $@ =~ m/$re/) {
						return 1;
					} elsif ($@) {
						print STDERR "'$@' does not match '$re'\n" if debug_mode;
						return;
					} else {
						print STDERR "Test sub did not return any exception\n" if debug_mode;
						return;					
					}
				}, 
			text => check_text($t)
		};

	return '__BAD_MARKER__';
}

sub fail (&;$) {
	my ($v, $t) = @_;
	&failwith($v, qr//, check_text($t), @_); # @_ est là juste pour le test du marqueur

	return '__BAD_MARKER__';
}

sub test_pod (@) {
	push @pods, @_;

	return '__BAD_MARKER__';
}

sub comment (&) {
	my ($c) = @_;
	if ($is_running) { # undocumented feature
		my $r = eval { $c->() };
		chomp($r);
		print STDERR $r."\n";
	} else {
		push @comments, {
				comment => $c,
				after => scalar(@tests)
			};
	}

	return '__BAD_MARKER__';
}

my $count = 0;

sub print_comment {
	while (@comments and $comments[0]->{after} == $count) {
		my $c = shift @comments;
		my $r = eval { $c->{comment}->() };
		chomp($r);
		print STDERR $r."\n";
	}
}

sub print_res {
	my ($ok, $m) = @_;
	printf STDOUT "%sok %d%s\n",  ($ok ? '' : 'not '), ++$count, $m;
}

sub skip {
	my ($reason) = @_;
	&check_run;
	
	if ($reason) {
		print STDOUT "1..0 # skip $reason\n";
	} else {
		print STDOUT "1..0\n";
	}
	
	$has_run = 1;

	exit 0;
}

sub run_test {
	$is_running = 1;

	printf STDERR "Running tests in DEBUG mode\n" if $debug_mode;

	my $nb_test = @tests + @pods;
	my $todo_str =  @todo ? ' todo '.join(' ', @todo).';' : '';
	
	printf STDOUT "1..%d%s\n", $nb_test, $todo_str;
	
	print_comment();
	for my $t (@tests) {
		my $r = $t->{code}->();
		chomp(my $cr = $r // ''); # //
		my $m = sprintf $t->{text}, $cr;
		print_res($r, $m);
		print_comment();
	}

	for my $m (@pods) {
		my $checker = Pod::Checker->new(-warnings => pod_warn_level(), -quiet => (not debug_mode()));
		my $f = $m;
		$f =~ s{::}{/}g;
		$f = catfile(path_to_lib(), "${f}.pm");
		if (-e $f and -r _) {
			eval { $checker->parse_from_file($f, \*STDERR) };
			if ($@) {
				print STDERR $@ if debug_mode;
				print_res(0, " - error while checking POD for $m");
			} else {
				print_res(!$checker->num_errors(), " - POD check for $m");
			}
		} else {
			print_res(0, " - Cannot read $f");
		}
	}

	$has_run = 1;

	return 1; # pour le mécanisme de 'do' utilisé dans CLI-Args/t/magic.t
}

BEGIN {
	$| = 1;
	select(STDERR);
	$| = 1;
}

END {
	if (not $has_run) {
		printf STDOUT "1..1\nnot ok 1 - compilation of file '$0' failed.\n";
	}
}

FILTER {
	$_ .= ';Test::Subs::run_test()'
};


sub import {
	my ($class, @args) = @_;

	while (my $o = shift @args) {
		given ($o) {
			when('debug') {
				croak "Missing argument to the '$o' option" unless @args;
				debug_mode(shift @args);
			}
			when('lib') {
				croak "Missing argument to the '$o' option" unless @args;
				path_to_lib(shift @args);			
			}
			when('pod_warn') {
				croak "Missing argument to the '$o' option" unless @args;
				pod_warn_level(shift @args);			
			}
			default {
				croak "Unknown argument '$o'";
			}
		}
	}
	
	#@_ = ($class);
	#goto &Exporter::import;
	__PACKAGE__->export_to_level(1, $class, @EXPORT);
}

1;

=encoding utf-8

=head1 NAME

Test::Subs - Test your modules with a lightweight syntax based on anonymous block

=head1 SYNOPSIS

  use SomeModule;
  use Test::Subs;
  
  test { 1 == 2 };

=head1 DESCRIPTION

This module provide a very lightweight syntax to run C<Test::Harness> or
C<Tap::Harness> compliant test on your code.

As opposed to other similar packages, the two main functionnalities of C<Test::Subs>
are that the tests are anonymous code block (rather than list of values), which
are (subjectively) cleaner and easier to read, and that you do not need to
pre-declare the number of tests that are going to be run (so all modifications in
a test file are local).

Using this module is just a matter of C<use Test::Subs> followed by the
declaration of your tests with the functions described below. All tests are then
run at the end of the execution of your test file.

As a protection against some error, if the compilation phase fail, the output of
the test file will be one failed pseudo-test.

=head1 FUNCTIONS

This is a list of the public function of this library. Functions not listed here
are for internal use only by this module and should not be used in any external
code unless .

All the functions described below are automatically exported into your package
except if you explicitely request to opposite with C<use Test::Subs ();>.

Finally, these function must all be called from the top-level and not inside of
the code of another test function. That is because the library must know the
number of test before their execution.

=head2 test

  test { CODE };
  test { CODE } DESCR;

This function register a code-block containing a test. During the execution of
the test, the code will be run and the test will be deemed successful if the
returned value is C<true>.

The optionnal C<DESCR> is a string (or an expression returning a string) which
will be added as a comment to the result of this test. If this string contains
a C<printf> I<conversion> (e.g. C<%s> or C<%d>) it will be replaced by the result
of the code block. If the description is omitted, it will be replaced by the
filename and line number of the test. You can use an empty string C<''> to
deactivate completely the output of a comment to the test.

=head2 todo

  todo { CODE };
  todo { CODE } DESCR;

This function is the same as the function C<test>, except that the test will be
registered as I<to-do>. So a failure of this test will be ignored when your test
is run inside a test plan by C<Test::Harness> or C<Tap::Harness>.

=head2 match

  match { CODE } REGEXP;
  match { CODE } REGEXP, DESCR;

This function declares a test which will succeed if the result of the code block
match the given regular expression.

The regexp may be given as a scalar string or as a C<qr> encoded regexp.

=head2 not_ok

  not_ok { CODE };
  not_ok { CODE } DESCR;

This function is exactly the opposite of the C<test> one. The test that it declares
will succeed if the code block return a C<false> value.

=head2 fail

  fail { CODE };
  fail { CODE } DESCR;

This function declares a test that will succeed if its code block C<die> (raise
any exception).

=head2 failwith

  failwith { CODE } REGEXP;
  failwith { CODE } REGEXP, DESCR;

As for the C<fail> function, this function declares a test which expects that its
code block C<die>. Except that the test will succeed only if the raised exception
(the content of the C<$@> variable) match the given regular expression.

The regexp may be given as a scalar string or as a C<qr> encoded regexp.

=head2 comment

  comment { CODE };

This function evaluate its code and display the resulting value on the standard
error handle. The buffering on C<STDOUT> and C<STDERR> is deactivated when
C<Test::Subs> is used and the output of this function should appear in between
the result of the test when the test file is run stand-alone.

This function must be used outside of the code of the other functions described
above. To output comment to C<STDERR> inside a test, just use the C<print> or
C<printf> function. The default output has been C<select>-ed to C<STDERR> so
the result of the test will not be altered.

=head2 skip (new in 0.07)

  skip 'reason' unless eval 'use Foo::Bar';

This function allows to skip a test file. It must be used outside of test subs
of the other functions. You will typically use it to disable a test file if the
current version of Perl is missing some required functionnalities for the tests.

The argument for the function is a string explaining the reason why the tests
have been skipped. This reasion will be reported in the output of a C<Test::Harness>
run.

=head2 test_pod (new in 0.04)

  test_pod(LIST);

This function takes a list of module name and registers one test for each given
module. The test will run the module file through C<L<Pod::Checker>> and fail if
there is errors in the POD of the file. Moreover, in debug mode, all errors and
warnings are printed to C<STDERR>.

=head2 debug

  debug { CODE } DESCR;

This function register and executes a dummy test: the CODE is executed and
error messages (if any) are written on C<STDERR>. The test will succeed under the
same condition as with the C<test> function.

Usefull when a test fail to quickly see what is going on.

=head1 OPTIONS

=head2 Debug mode (new in 0.03)

You can pass a C<debug> argument to the package when you are C<using> it:

  use Test::Subs debug => 1;

If the value supplied to this option is I<true> then all call to the C<test>
functions will behave like calls to the C<debug> function. Also, most of the
function of this library will give more output (on C<STDERR>) if their test
fails.

=head2 Path to the library files (new in 0.05)

By default, if you specify a C<'My::Module'> module as a target of the C<test_pod>
function, the file for this module will be searched in C<lib/My/Module.pm>
B<relatively to the current working directory>. This should work for standard
distribution. Yau can modify this behaviour with the C<lib> option as argument
to the package when you are C<using> it:

  use Test::Subs lib => '../lib';

The supplied path will serve as the base directory to look for the module file
(e.g. C<My/Module.pm>), B<relatively to the the test script directory> (and not
to the current working directory as in the default case).

=head2 Warning level for POD Checking (new in 0.05)

You can tune the number of warning generated by the C<test_pod> function using
a C<pod_warn> argument to the package when you are C<using> it:

  use Test::Subs pod_warn => 0;

This option expects an integer value. A value of C<'0'> will deactivates all
warnings, a value of C<'1'> will activates most warnings and a value of C<'2'>
will activates some additionnals warnings. More details on the available warnings
can be found in the L<C<POD::Checker> documentation|Pod::Checker/"Warnings">.

Note that, in any case, the warnings will only be printed in C<debug> mode.

=head1 EXAMPLE

Here is an example of a small test file using this module.

  use strict;
  use warnings;
  use Test::Subs debug => 1, lib => '../lib';
  use My::Module;
  
  test { My::Module::init() } 'This is the first test';
  
  todo { My::Module::make_coffee() };
  
  not_ok { 0 };
  
  fail { die "fail" };
  
  test_pod('My::Module', 'My::Module::Internal');

Run through C<Test::Harness> this file will pass, with only the second test failing
(but marked I<todo> so that's OK).

=head1 CAVEATS

This package does not use the C<Test::Builder> facility and as such is not compatible
with other testing modules are using C<Test::Builder>. This may be changed in a
future release.

The standard set by C<Test::Harness> is that all output to C<STDOUT> is
interpreted by the test parser. So a test file should write additional output
only to C<STDERR>. This is what will be done by the C<comment> fonction. To help
with this, during the execution of your test file, the C<STDERR> file-handle will
be C<select>-ed. So any un-qualified C<print> or C<printf> call will end in
C<STDERR>.

This package use source filtering (with C<L<Filter::Simple>>). The filter
applied is very simple, but there is a slight possibility that it is incompatible
with other source filters. If so, do not hesitate to report this as a bug.

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-subs@rt.cpan.org>, or
through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Subs>.

=head1 SEE ALSO

L<Test>, L<Test::Tiny>, L<Test::Lite>, L<Test::Simple>

=head1 AUTHOR

Mathias Kende (mathias@cpan.org)

=head1 VERSION

Version 0.08 (March 2013)

=head1 COPYRIGHT & LICENSE

Copyright 2013 © Mathias Kende.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut


