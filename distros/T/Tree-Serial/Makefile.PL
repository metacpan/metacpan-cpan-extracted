use warnings;
use v5.12;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Tree::Serial',
    VERSION_FROM     => 'lib/Tree/Serial.pm',
    ABSTRACT_FROM    => 'lib/Tree/Serial.pm',
    AUTHOR           => 'stuart-little',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.12.0',
    PREREQ_PM        => {	
	'warnings' => 0,
	    'List::Util' => 1.56,
    },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
	'meta-spec' => { version => 2 },
	    resources => {
		repository => {
		    type => 'git',
		    url  => 'https://github.com/stuart-little/tree-serial.git',
		    web  => 'https://github.com/stuart-little/tree-serial',
		},
	}})
     : ()
    ),
    );
