use ExtUtils::MakeMaker;

require 5.008;

WriteMakefile(
    'NAME'		=> 'Unicode::Regex::Set',
    'VERSION_FROM'	=> 'Set.pm',
    'ABSTRACT'		=> 'Subtraction and Intersection of Character Sets '.
			   'in Unicode Regular Expressions',
    'AUTHOR'		=> 'SADAHIRO Tomoyuki <SADAHIRO@cpan.org>',
    'LICENSE'		=> 'perl',
    'PREREQ_PM'	  	=> {
	Carp		=> 0,
	constant	=> 0,
	Exporter	=> 0,
	strict		=> 0,
	warnings	=> 0,
    },
);
