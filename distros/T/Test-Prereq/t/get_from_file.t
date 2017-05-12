use Test::More 0.95;

use Test::Prereq;

my @prereq_files = sort qw(
	Carp
	ExtUtils::MakeMaker
	File::Find
	Module::Extract::Use
	Test::Builder::Module
	feature
	parent
	strict
	vars
	warnings
	utf8
	);

my @tests = (
	[ 't/pod.t',            [ qw(Test::More) ]  ],
	[ 'lib/Test/Prereq.pm', [ @prereq_files ]   ],
	);

foreach my $test ( @tests ) {
	my( $file, $expected ) = @$test;

	@$expected = sort @$expected;

	subtest pod => sub {
		my @modules = sort @{ from_file( $file ) };

		diag "Did not find right modules for $file!\nFound <@modules>\n"
			unless is_deeply( \@modules, $expected,
					"Found the expected modules for $file"
					);
		};
	}

sub from_file {
	my( $file ) = @_;

	my $modules = Test::Prereq->_get_from_file( $file );

	return $modules;
	}

done_testing();
