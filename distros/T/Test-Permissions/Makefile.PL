use strict;
use warnings;
use ExtUtils::MakeMaker;

my $dist = {
	COMPRESS => 'gzip -9f',	# Compress tarball using gzip
	SUFFIX => 'gz',	# File suffix for tarball
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

# This module is a test dependency of other distributions, so everything in
# PREREQ_PM is pulled into all of them.  Keep the list short.
WriteMakefile(
	NAME		=> 'Test::Permissions',
	AUTHOR		=> q{Nigel Horne <njh@nigelhorne.com>},
	VERSION_FROM	=> 'lib/Test/Permissions.pm',
	ABSTRACT_FROM	=> 'lib/Test/Permissions.pm',
	((defined($ExtUtils::MakeMaker::VERSION) && ($ExtUtils::MakeMaker::VERSION >= 6.3002))
		? ('LICENSE'=> 'gpl_2')
		: ()),
	'LIBS' => [''],	# e.g., '-lm'
	'DEFINE' => '',	# e.g., '-DHAVE_SOMETHING'
	'INC' => '',	# e.g., '-I/usr/include/other'
	PL_FILES	=> {},
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES
	}, TEST_REQUIRES => {
		'Test::DescribeMe' => 0,
		'Test::Mockingbird' => '0.13',	# around, mock_scoped, spy, unmock, restore
		'Test::Most' => 0,
		'Test::Returns' => 0.04,
		'Test::Warnings' => 0,
	}, PREREQ_PM => {
		'autodie' => 0,
		'Carp' => 0,
		'Cwd' => 0,
		'Errno' => 0,
		'Exporter' => 0,
		'File::Path' => '2.07',	# remove_tree
		'File::Spec' => 0,
		'File::Temp' => 0,
		'IPC::System::Simple' => 0,	# needed by autodie qw(:all)
		'Params::Get' => 0.17,
		'Params::Validate::Strict' => '0.40',	# rejects undef for a required string with min
		'Readonly' => 0,
		'Return::Set' => 0,
		'Test::More' => 0,	# skip_unless_can_revoke calls Test::More::skip
	}, dist => $dist,
	clean		=> { FILES => 'Test-Permissions-*' },
	META_MERGE => {	# https://perldoc.perl.org/CPAN::Meta::Spec
		'meta-spec' => { version => 2 },
		prereqs => {
			develop => {
				requires => {
					'Test::DescribeMe' => 0,	# gates the author tests
					'Test::EOF'   => 0,	# t/eof.t (author test)
					'Test::EOL'   => 0,	# t/eol.t (author test)
					'Test::Kwalitee' => 0,	# t/kwalitee.t (author test)
					'Test::Needs' => 0,
				},
			},
		},
		resources => {
			homepage => 'https://metacpan.org/pod/Test::Permissions',
			repository => {
				repository => 'https://github.com/nigelhorne/Test-Permissions',
				type => 'git',
				url => 'git://github.com/nigelhorne/Test-Permissions.git',
				web => 'https://github.com/nigelhorne/Test-Permissions',
			}, bugtracker => {
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Test-Permissions',
				url => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Test-Permissions',
				# web => 'https://github.com/nigelhorne/Test-Permissions/issues',
				# url => 'https://github.com/nigelhorne/Test-Permissions/issues',
				mailto => 'bug-Test-Permissions@rt.cpan.org'
			}
		},
	},
	# Params::Validate::Strict (and so Return::Set) needs 5.026.  The module
	# itself needs only 5.010 (//=), and Test::Mockingbird needs 5.016.
	MIN_PERL_VERSION	=> '5.026'
);
