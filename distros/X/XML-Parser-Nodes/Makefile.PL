use 5.008009;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
	NAME              => 'XML::Parser::Nodes',
	VERSION_FROM      => 'lib/XML/Parser/Nodes.pm', # finds $VERSION
	PREREQ_PM         => &requiredmodules,
	&newkeywords,
	) ;

sub newkeywords {
	return () if $] < 5.005 ;
	return (
		ABSTRACT_FROM  => 'lib/XML/Parser/Nodes.pm',
		# retrieve abstract from module
		AUTHOR => 'Jim Schueler <jim@tqis.com>',
		) ;
	}

sub requiredmodules {
	# e.g., Module::Name => 1.1
	return {
		XML::Dumper => 0.81,
		XML::Parser => 2.41,
		} ;
	}

1
