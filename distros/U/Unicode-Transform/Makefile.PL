use ExtUtils::MakeMaker;

require 5.006001;

WriteMakefile(
    'NAME'		=> 'Unicode::Transform',
    'VERSION_FROM'	=> 'Transform.pm',
    'ABSTRACT_FROM'	=> 'Transform.pm',
    'AUTHOR'		=> 'SADAHIRO Tomoyuki <SADAHIRO@cpan.org>',
    'LICENSE'		=> 'perl',
    'PREREQ_PM'	  	=> {
	DynaLoader	=> 0,
	Exporter	=> 0,
	strict		=> 0,
	warnings	=> 0,
    },
);
