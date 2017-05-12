use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'WebService::GoogleHack',
    'VERSION_FROM'	=> 'GoogleHack.pm', # finds $VERSION
    'PREREQ_PM'		=> {'SOAP::Lite' => '0', 'HTML::TokeParser'  => '0', 'Text::English' => '0', 
'LWP::Simple' => '0','URI::URL' => '0','LWP::UserAgent' => '0','HTML::LinkExtor' => '0'}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (  AUTHOR     => 'Pratheepan Raveendranathan <rave0029@d.umn.edu>') : ()),
);
