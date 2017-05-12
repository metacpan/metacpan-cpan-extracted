use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
	NAME			=> 'X11::SendEvent',
	VERSION_FROM	=> 'SendEvent.pm', 
	AUTHOR			=> 'Erick Calder <ecalder@cpan.org>',
	ABSTRACT_FROM	=> 'SendEvent.pm',
	PREREQ_PM		=> {
		X11::Protocol => '0.04',
		},
	);
