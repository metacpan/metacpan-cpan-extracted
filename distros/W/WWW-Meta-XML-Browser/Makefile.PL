use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'WWW::Meta::XML::Browser',
    'VERSION_FROM'	=> 'Browser.pm', # finds $VERSION
    'PREREQ_PM'		=> {
        'Digest::MD5'		=> '0',
        'HTTP::Cookies'		=> '0',
        'HTTP::Request'		=> '0',
        'LWP::UserAgent'	=> '0',
        'Time::HiRes'		=> '0',
        'URI::Escape'		=> '0',
        'XML::LibXML'		=> '0',
        'XML::LibXSLT'
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Browser.pm', # retrieve abstract from module
       AUTHOR     => 'Benjamin Boksa <benjamin@boksa.de>') : ()),
);
