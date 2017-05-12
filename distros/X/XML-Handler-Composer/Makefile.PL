use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'XML::Handler::Composer',
    'VERSION_FROM'	=> 'Composer.pm', # finds $VERSION
    'PREREQ_PM'		=> {XML::UM => 0},
);
