require 5.008;
use ExtUtils::MakeMaker;
use Module::Metadata;
eval "use Devel::Required";

WriteMakefile (
	NAME		=> "persona",
	AUTHOR		=> 'Elizabeth Mattijsen (liz@dijkmat.nl)',
	ABSTRACT	=> 'persona - control which code will be loaded for an execution context',
	VERSION_FROM	=> 'lib/persona.pm',
	LICENSE  	=> 'perl_5',
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => '0',
		'Module::Metadata' => '1.000033',
	},
	BUILD_REQUIRES => {
		'Test::More' => '0',
	},
	PREREQ_PM => {
		'List::Util' => '0',
		'strict' => '0',
		'warnings' => '0'
	},
	dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean => { FILES => 'persona-*' },
 	META_MERGE => {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url  => 'https://github.com/ThisUsedToBeAnEmail/persona.git',
				web  => 'https://github.com/ThisUsedToBeAnEmail/persona',
			}
		}
	},
	META_ADD => {
		provides => Module::Metadata->provides(version => '2', dir => 'lib')
	}
);
