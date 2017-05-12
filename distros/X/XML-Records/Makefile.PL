use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'XML::Records',
    'VERSION_FROM' => 'Records.pm', # finds $VERSION
    'PREREQ_PM' => {XML::TokeParser => '0.03'},
);
