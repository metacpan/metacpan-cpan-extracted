# Generated from Makefile.PL using makefilepl2cpanfile

requires 'perl', '5.016003';

requires 'Carp';
requires 'Exporter';
requires 'ExtUtils::MakeMaker', '6.64';   # Minimum version for TEST_REQUIRES
requires 'Test::Deep';
requires 'Test::More';

# Optional: Test::Mockingbird::Async needs it; t/async.t and
# t/mutant_killers.t are skipped without it.
recommends 'Future', '0.33';

on 'test' => sub {
	requires 'Class::Simple';
	requires 'IPC::System::Simple';
	requires 'Readonly';
	requires 'Test::DescribeMe';
	requires 'Test::Memory::Cycle';
	requires 'Test::Most';
	requires 'Test::Needs';
	requires 'Test::Strict';
	requires 'Test::Vars';
	requires 'Test::Warnings';
};

on 'develop' => sub {
	requires 'Devel::Cover';
	requires 'Perl::Critic';
	requires 'Test::Pod';
	requires 'Test::Pod::Coverage';
};
