# Generated from Makefile.PL using makefilepl2cpanfile

requires 'perl', '5.026';

requires 'Carp';
requires 'Cwd';
requires 'Errno';
requires 'Exporter';
requires 'File::Path', '2.07';   # remove_tree
requires 'File::Spec';
requires 'File::Temp';
requires 'IPC::System::Simple';   # needed by autodie qw(:all)
requires 'Params::Get', '0.17';
requires 'Params::Validate::Strict';
requires 'Readonly';
requires 'Return::Set';
requires 'Test::More';   # skip_unless_can_revoke calls Test::More::skip
requires 'autodie';

on 'configure' => sub {
	requires 'ExtUtils::MakeMaker', '6.64';   # Minimum version for TEST_REQUIRES
};

on 'test' => sub {
	requires 'Test::DescribeMe';
	requires 'Test::Mockingbird', '0.13';   # around, mock_scoped, spy, unmock, restore
	requires 'Test::Most';
	requires 'Test::Returns', '0.04';
	requires 'Test::Warnings';
};

on 'develop' => sub {
	requires 'Devel::Cover';
	requires 'Perl::Critic';
	requires 'Test::DescribeMe';   # gates the author tests
	requires 'Test::EOF';   # t/eof.t (author test)
	requires 'Test::EOL';   # t/eol.t (author test)
	requires 'Test::Kwalitee';   # t/kwalitee.t (author test)
	requires 'Test::Needs';
	requires 'Test::Pod';
	requires 'Test::Pod::Coverage';
};
