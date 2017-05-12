use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'XML::Filter::Hekeln',
    'VERSION_FROM' => 'Hekeln.pm', # finds $VERSION
    'EXE_FILES'    => [ 'hekeln' ],
    'PREREQ_PM'    => {
    	'XML::Parser::PerlSAX' => 0.06,
	'XML::Handler::YAWriter' => 0.1,
	'IO::File' => 1
	}
);
