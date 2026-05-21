# Generated from Makefile.PL using makefilepl2cpanfile

requires 'perl', '5.008';

requires 'Carp';
requires 'Getopt::Long';
requires 'Params::Get', '0.13';
requires 'Pod::Usage';
requires 'Return::Set';
requires 'Scalar::Util';

on 'configure' => sub {
	requires 'ExtUtils::MakeMaker', '6.64';
};

on 'test' => sub {
	requires 'Data::Dumper';
	requires 'Readonly';
	requires 'Test::DescribeMe';
	requires 'Test::Mockingbird', '0.08';
	requires 'Test::Most';
	requires 'Test::Needs';
	requires 'Test::Returns';
};

on 'develop' => sub {
	requires 'Devel::Cover';
	requires 'Perl::Critic';
	requires 'Test::Pod';
	requires 'Test::Pod::Coverage';
};
