use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Router::LG::Cisco',
    'VERSION_FROM' => 'Cisco.pm', # finds $VERSION
);
