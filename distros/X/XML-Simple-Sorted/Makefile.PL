#
# XML::Simple::Sorted - Version of XML::Simple with user defined tag and attribute sort order.
#

use strict;

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME			=> 'XML::Simple::Sorted',
	VERSION_FROM	=> 'lib/XML/Simple/Sorted.pm',
	PREREQ_PM		=> { 'XML::Simple' => 0, 'Config::IniFiles' => 0, 'Tie::File' => 0 },
	($] >= 5.005 ?
		(ABSTRACT_FROM	=> 'lib/XML/Simple/Sorted.pm',
		 AUTHOR			=> 'Sinisa Susnjar (sini@cpan.org)') : ())
);
