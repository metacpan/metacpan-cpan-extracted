use ExtUtils::MakeMaker;

WriteMakefile( NAME => 'mcoder',
	       VERSION_FROM => 'lib/mcoder.pm',
	       PREREQ_PM => { Test::More => 0 },
	       ABSTRACT_FROM => 'lib/mcoder.pm',
	       AUTHOR => 'Salvador Fandiño <sfandino@yahoo.com>');

