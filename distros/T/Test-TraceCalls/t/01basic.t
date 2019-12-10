=pod

=encoding utf-8

=head1 PURPOSE

Test that Test::TraceCalls works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2019 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More;

use Test::TraceCalls ();
use FindBin qw( $RealBin );
use File::Spec ();
use JSON::PP;

my $Bin = $RealBin;

my $dtc_libdir = 'File::Spec'->catdir($Bin, '..', 'lib');

my $projdir = 'File::Spec'->catdir($Bin, 'Local-Example');
my $libdir  = 'File::Spec'->catdir($Bin, 'Local-Example', 'lib');
my $testdir = 'File::Spec'->catdir($Bin, 'Local-Example', 't');

my @testfiles = qw( test1.t test2.t );

sub run_suite {
	$ENV{PERL_TRACE_CALLS_SUITE} = 1;
	$ENV{PERL_TRACE_CALLS} = shift;
	chdir($projdir);
	for my $test (@testfiles) {
		note $test;
		open(
			my $fh,
			'-|',
			$^X,
			"t/$test",
		);
		local $/ = undef;
		my $output = <$fh>;
		note $output;
	}
}

sub slurp_json {
	local $/;
	open my $fh, '<', shift or die;
	JSON::PP->new->decode(<$fh>);
}

note 'Running test suite with Devel::TraceCalls inactive...';
run_suite(0);
ok(!-e File::Spec->catfile($testdir, "$_\.map"), "$_\.map was not created")
	for @testfiles;

note 'Running test suite with Devel::TraceCalls active...';
run_suite(1);
ok(-e File::Spec->catfile($testdir, "$_\.map"), "$_\.map was created")
	for @testfiles;

is_deeply(
	slurp_json(File::Spec->catfile($testdir, "test1.t.map")),
	{
		"Local::Example::Module1" => { bar => 1, foo => 1 },
	},
	"test1.t.map contents correct",
);

is_deeply(
	slurp_json(File::Spec->catfile($testdir, "test2.t.map")),
	{
		"Local::Example" => { quux => 2 },
		"Local::Example::Module1" => { bar => 1 },
		"Local::Example::Module2" => { bar => 1, foo => 1 },
	},
	"test2.t.map contents correct",
);

unlink map File::Spec->catfile($testdir, "$_\.map"), @testfiles;

done_testing;

