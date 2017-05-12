package Test::Snapshots;
use strict;
use warnings;

use 5.008005;

our $VERSION = '0.02';

=head1 NAME

Test::Snapshots - for testing stand alone scripts and executables

=head1 SYNOPSIS

 use Test::More;
 use Test::Snapshots;

 test_all_snapshots('eg');

Will go over all the .pl files in the eg/ directory, run them using
with the content of the SCRIPT.out and SCRIPT.err files


Optional configurations before calling test_all_snapshots:

 Test::Snapshots::debug(1);

Get some extra diag messages

 Test::Snapshots::combine(1);

Combines the stdout and stderr and compares them to the SCRIPT.out file


 Test::Snapshots::set_glob('*.t');

Change the way we locate the scripts to be executed.


 Test::Snapshots::set_accessories_dir('path/to/dir');

Change the place where TS looks for .out files.

=head1 WARNING

This is alpha software. The API will most certainly change as 
the requirements get clearer.

=head1 Examples

Many of the unit test of this module are actually simple use cases
with the files to be tested located in the eg/ subdirectory of the
distribution. Check them out.

=head1 TODO

=over 4

=item *

Add more test this module. Especially, we don't yet have failing tests.

=item *

Change the API to look more OO. Probably sg. like:

Test::Snapshots->set_glob()
    ->combine()
    ->set_accessories_dir()
    ->set_directories('eg')
    ->test_all_snapshots();

=item *

Allow subclassing or extending the module in some other way.

=item *

Deal with command line arguments. (.argv ?)

=item *

Deal with single file asseccories: A single file that holds the contents of 
the .in , .our, .err etc... file in sections. 

E.g. the PHP core testing has .phpt files with sections:

 --TEST--
 Name of the test
 --FILE--
 The code that needs to be saved in a file and executed
 --EXPECT--
 The expected output

Test::Snapshots should be able to support that with the code
to be executed inside as in the case of php or being outside
as when testing executables.

=item *

Allow to pass several directories to traverse

=item *

Allow multiple runs in the same test script. (This will probably
mean the test counting needs to be done separately or we will have 
to use the new "add plan" feature of Test::More.

=item *

Allow definiton of expected exit code for each file in some 
centralized form maybe similar to the way skip is defined.

=item *

Do we need a TODO test capability here?

=item *

Use L<Capture::Tiny> ?

=back

=head1 DESCRIPTION

Test::Snapshots was created especially to be able to test a 
large number of command line oriented executables. It does not
matter if the executable is something compiled from C, a Perl, 
Python or PHP script.

Test::Snapshot can be seen as a very simple replacement of L<Expect>.
It will go over the designated direcory and run every execute like this:

  executable arguments < input_file > output_file 2> error_file
  
It will then check if the output_file is the same as the exepcted output file
and if the error_file is the sameas the expected error file.

If an input file is not supplied then the < input_file part will be
omitted.

The input file, the list of arguments and the expected output and 
error files all have the same name as the executable. So if you have
an executable called C<fabricate.exe> then you'd create the following
files:

  fabricate.exe.in
  fabricate.exe.argv
  
  fabricate.exe.out
  fabricate.exe.err
  fabricate.exe.exit
  
If .in is omitted we assume there is no input

If .argv is omitted then no arguments are provided

If .err or .out is omitted then it is assumed to be empty.

If .exit is omitted then it is expected that the exit code will be
equal to the default exit code which is 0.

=head2 Multiple test cases

Sometime a single executable file should have multiple test cases. That is
we might want to provide different .in and .argv files and expect different
.out/.err/.exit values.

In order to allow such mode the files need to have a number in their name.
So if you are testing I<xyz> the files need to be

 xyz.01.in
 xyz.01.out
 
 xyz.02.in
 xyz.02.out
 xyz.02.err

The expected number of test is the number of different numbers so if you have
two files xyz.01.in and xyz.27.err then Test::Snapshots will run two test. One
of them has no input and some expected error while the other has only input 
and not expected output or error.

=head2 Timeout

In order to avoid stuck test cases (e.g. waiting on STDIN)
by default every test case can run up to 10 secs.

=head1 METHODS

=cut

use Carp             ();
use File::Temp       qw(tempdir);
use Text::Diff       qw(diff);
use File::Find::Rule;
use List::Util       qw(sum);

use base 'Test::Builder::Module';
use base 'Exporter';

our @EXPORT = qw(test_all_snapshots);

my $debug;
my $combine;
my $glob     = '*.pl';
my $command  = $^X;
my $skip     = {};
my $accessories_dir;
my $default_expected_exit = 0;
my $multiple;
my $timeout = 10;

=head2 timeout

Set timeout for the executions so if one of them gets stuck 
(e.g. waiting on STDIN) the whole test suit won't suffer.

Default 10 secs.

=head2 combine

Set to 1 if you'd like to combine the STDOUT and STDERR and compare the
combined output to the .out file.

Default is 0 meaning they will be captured separatelly and compared 
separatelly to the .out and .err files.

=cut

sub combine {
	$combine = shift;
}

=head2 set_glob

Set what glob to use to fine the files to be executed. Currently it 
defaults to '*.pl' but maybe it should have no default forcing the user
to set one.

=cut

sub set_glob {
	$glob = shift;
}

=head2 skip

Pass to it a hash ref of     path => 'explanation' pairs
for all the files that need to be skipped.

  skip({
    path => 'good reason',
    path2 => 'some excuse',
  });

=cut

sub skip {
	$skip = shift;
}

=head2 set_accessories_dir

We are calling the .out, .err etc files accessories.
	
In some cases you don't want them to be next to the script that 
are being tested. In such cases you can use the above function 
to tell Test::Snapshots where those files can be found.

=cut

sub set_accessories_dir {
	$accessories_dir = shift;
}


sub multiple {
	$multiple = shift;
}

=head2 command

By default Test::Snapshots will assume the files to be tested 
are stand alone executables or that at least they know where their
interpreter is. So they will be executed directly.

In most of the cases you will want to run them with some 
specific command. e.g. You might want to make sure they run with the
same perl interpreter as your test script runs. In that case call the following:

 command($^X)

In other cases the files need to be executed with some other tool, eg. 
the perl 6 or python interpreter which is in the path:

 command("perl6");

or

 command("python");

=cut

sub command {
	$command = shift;
}

=head2 default_expected_exit_code

The exepceted exit code can be defined on a perl case basis
in the .exit file. If the .exit file does not exist
then there is a default expected exit code. Which is 0 by default.

Use this method to chane the default.

=cut

sub default_expected_exit_code {
	$default_expected_exit = shift;
}

=head2 debug

You can turn on the debug flag by calling debug(1).
If it is set Test::Snippets will call diag() with all kinds of 
information during the test execution.

=cut

sub debug {
	$debug = shift;
}

=head2 test_all_snapshots

This is the call that actually goes out, locates all the
files to be tested, sets the C<plan> and executes all the test.
Currently one should give a directory as a paramter to it but 
I plan to move that parameter to a separate method and to allow
the setting of multiple directories.

=cut

sub test_all_snapshots {
	my ($dir) = @_;

	Carp::croak("Need to supply directory name") if not defined $dir;
	
	my @files = sort File::Find::Rule->file()->name($glob)->in($dir);
	my $prefix_length = length $dir;
	
	# go over all the files and count the different .in, .out, .err, .exit files
	my %tests;
	if ($multiple) {
		foreach my $file (@files) {
			my %seen;
			my @extras = grep { !$seen{$_}++ } 
				map {$_ =~ /\.(\d+)\.(out|err|in|exit)$/; $1}  
				glob "$file.*";
			$tests{$file} = \@extras;
		}
	}

	my $T = Test::Builder->new;
	
	my $cnt = $combine ? 1 : 2;
	$cnt++; # for exit codes
	my $test_count = @files * $cnt;

	#use Data::Dumper;
	#$T->diag(Dumper \@files);
	#$T->diag(Dumper \%tests);
	if ($multiple) {
		#$T->diag(sum (map { scalar @{ $tests{$_} } } @files));
		$test_count = $cnt * sum (map { scalar @{ $tests{$_} } } @files);
	}
	$T->plan(tests => $test_count );

	foreach my $file (@files) {
		if ($skip->{$file}) {
			my $count = $cnt * ($multiple ? scalar(@{ $tests{$file} }) : 1);
			$T->skip($skip->{$file}) for 1..$count;
			next;
		}
		if ($multiple) {
			foreach my $case (@{ $tests{$file} }) {
				test_single_file($file, $prefix_length, ".$case");
			}
		} else {
			test_single_file($file, $prefix_length,);
		}
	}
}

=head2 test_single_file

Testing a single file. It gets the path to the file to be tested.
The length of the prefix and optionally a case which is the 01, 02 etc.
name of the test case for the multple-test-cases.

Currently this is considered an internal method.

=cut


sub test_single_file {
	my ($file, $prefix_length, $case) = @_;
	$case ||= '';

	my $tempdir = tempdir( CLEANUP => 1 );
	my $T = Test::Builder->new;

	my $accessories_path = $accessories_dir ? $accessories_dir . substr($file, $prefix_length) : $file;
	#$T->diag($accessories_path);
	my $in_file = "$accessories_path$case.in";

	my %std;
	$std{out} = "$tempdir/out";
	$std{err} = "$tempdir/err";

	my $cmd = "$command $file";
	if ($combine) {
		$cmd .= " >$std{out} 2>&1";
	} else {
		$cmd .= " >$std{out} 2>$std{err}";
	}
	if (-e $in_file) {
		$cmd .= " < $in_file";
	}
	if ($debug) {
		$T->diag($cmd);
	}

	my @stds = $combine ? qw(out) : qw(err out);


	my $exit;
	#$T->diag($file);
	$SIG{ALRM} = sub { die "TIMEOUT\n" };
	alarm($timeout);
	eval {
		system $cmd;
		$exit = $?;
		1;

	} or do {
		alarm(0);
		if ($@ eq "TIMEOUT\n") {
			$T->ok(0, "Timeout. No result") for 1..@stds+1;
			return;
		} else {
			die $@; # unknown exception
		}
	};
	alarm(0);
	#$T->diag("Exit '$exit'");


	foreach my $ext (@stds) {
		my $expected = "$accessories_path$case.$ext";
		if (-e $expected) {
			my $diff = diff($expected, "$std{$ext}");
			$T->ok(!$diff, "$ext of $file") or $T->diag($diff);
		} else {
			my $data = _slurp($std{$ext});
			$T->ok($data eq '', "$ext of $file")
				or $T->diag("Expected nothing.\nReceived\n\n$data");
		}
	}
	# exit code
	{
		my $expected_exit = $default_expected_exit;
		my $expected_file = "$accessories_path$case.exit";
		if (-e $expected_file) {
			$expected_exit = _slurp($expected_file);
			chomp $expected_exit;
		}
		$T->is_eq($exit >> 8, $expected_exit, "Exit code of $file");
	}

	return;
}


# a private slurp method.
sub _slurp {
	my $file = shift;
	open my $fh, '<', $file or die $!;
	local $/ = undef;
	return <$fh>;
}

=head1 See Also

L<Test::Simple>, L<Test::More> and L<Test::Most>.

L<Test::Output>, L<Capture::Tiny>, L<Test::Cmd>,

=head1 COPYRIGHT

Copyright 2009 Gabor Szabo gabor@szabgab.com http://szabgab.com/

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.


=cut


1;
