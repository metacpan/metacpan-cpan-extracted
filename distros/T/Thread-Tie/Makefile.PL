require 5.008;
use threads (); # just to force breakage if threads are not available
use ExtUtils::MakeMaker;
use Module::Metadata;
eval "use Devel::Required";

WriteMakefile (
	NAME		=> "Thread::Tie",
	AUTHOR		=> 'Elizabeth Mattijsen (liz@dijkmat.nl)',
	ABSTRACT	=> 'tie variables into a thread of their own',
	VERSION_FROM	=> 'lib/Thread/Tie.pm',
	LICENSE  	=> 'perl_5',
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => '0',
		'Module::Metadata' => '1.000033',
		'Devel::Required' => '0',
		'threads' => '0'
	},
	BUILD_REQUIRES => {
		'Test::More' => '0',
	},
	PREREQ_PM	=> {qw(
		load			0.11
		Thread::Serialize	0.07
	)},
	dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean => { FILES => 'Thread-Tie-*' },
	META_MERGE => {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url  => 'https://github.com/ThisUsedToBeAnEmail/Thread-Tie.git',
				web  => 'https://github.com/ThisUsedToBeAnEmail/Thread-Tie',
			}
		}
	},
	META_ADD => {
		provides => Module::Metadata->provides(version => '2', dir => 'lib')
	}
);
