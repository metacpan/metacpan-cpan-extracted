use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile( NAME => 'barewords',
	       VERSION_FROM => 'lib/barewords.pm',
	       PREREQ_PM => { Test::More => 0 },
	       ABSTRACT_FROM => 'lib/barewords.pm',
	       AUTHOR => 'Salvador Fandino <sfandino@yahoo.com>' );

