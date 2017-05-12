use 5.00503;

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	=> 'XML::Filter::Digest',
    'VERSION_FROM' => 'Digest.pm', # finds $VERSION
    'EXE_FILES'    => [ 'digest', 'survey' ],
    'PREREQ_PM'    => {
    	'XML::Parser::PerlSAX' => 0.06,
	'XML::XPath' => 0.51,
	'XML::Handler::YAWriter' => 0.1,
	'IO::File' => 1,
    	'Digest::MD5' => 2.09
	}
);
