use ExtUtils::MakeMaker 6.65;

require 5.012;

eval "use Test::Manifest 1.21";

WriteMakefile(
	'NAME'	        => 'Tie::StringArray',
	'ABSTRACT_FROM' => 'lib/Tie/StringArray.pm',
	'VERSION_FROM'  => 'lib/Tie/StringArray.pm',
	'LICENSE'       => 'perl',
	'AUTHOR'        => 'brian d foy <bdfoy@cpan.org>',
	
	'PREREQ_PM'    => { 
		'Test::More' => '0',
		},

	clean  => { FILES    => q|Tie-StringArray-*| },

	);
