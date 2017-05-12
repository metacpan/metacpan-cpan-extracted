use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'VoiceXML::Client',
    VERSION_FROM      => 'lib/VoiceXML/Client.pm', # finds $VERSION
    PREREQ_PM         => {
    			'LWP::UserAgent'	=> 2.000,
			'XML::Mini'		=> 1.36,
			'HTTP::Cookies'		=> 1.39,
			'Hash::Util'		=> 0.05,
    
    }, 
    
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/VoiceXML/Client.pm', # retrieve abstract from module
       AUTHOR         => 'Pat Deegan <http://www.psychogenic.com>') : ()),
);
