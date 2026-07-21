use strict;
use warnings;
use ExtUtils::MakeMaker;

my $dist = {
	COMPRESS => 'gzip -9f', # Compress tarball using gzip
	SUFFIX => 'gz',	# File suffix for tarball
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile(
	NAME => 'Test::Mockingbird',
	VERSION_FROM => 'lib/Test/Mockingbird.pm', # finds $VERSION in the module
	AUTHOR => 'Nigel Horne <njh@nigelhorne.com>',
	ABSTRACT => 'Advanced mocking library for Perl with support for dependency injection and spies',
	((defined($ExtUtils::MakeMaker::VERSION) && ($ExtUtils::MakeMaker::VERSION >= 6.3002))
		? ('LICENSE'=> 'gpl_2')
		: ()),
	META_MERGE => {	# https://perldoc.perl.org/CPAN::Meta::Spec
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				repository => 'https://github.com/nigelhorne/Test-Mockingbird',
				type => 'git',
				url => 'git://github.com/nigelhorne/Test-Mockingbird.git',
				web => 'https://github.com/nigelhorne/Test-Mockingbird'
			}, bugtracker => {
				mailto => 'bug-Test-Mockingbird@rt.cpan.org',
				url => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Test-Mockingbird',
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Test-Mockingbird',
			}
		}, prereqs => {
			runtime => {
				recommends => {
					Future => '0.33',
				},
			},
		},
	}, PREREQ_PM => {
		'Carp'                => 0,
		'Exporter'            => 0,
		'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES
		'Test::Deep'          => 0,
		'Test::More'          => 0,
	}, TEST_REQUIRES => {
		'Class::Simple' => 0,
		'IPC::System::Simple' => 0,
		'Readonly' => 0,
		'Test::DescribeMe' => 0,
		'Test::Memory::Cycle' => 0,
		'Test::Most' => 0,
		'Test::Needs' => 0,
		'Test::Returns' => 0.03,
		'Test::Strict' => 0,
		'Test::Vars' => 0,
		'Test::Warnings' => 0,
	}, dist => $dist,
		clean	 => {
		FILES => 'Test-Mockingbird-*',
	},
	MIN_PERL_VERSION	=> '5.016003'
);
