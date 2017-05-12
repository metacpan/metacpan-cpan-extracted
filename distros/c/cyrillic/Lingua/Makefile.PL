use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'	=> 'Lingua::DetectCharset',
    'VERSION_FROM' => 'DetectCharset.pm', # finds $VERSION
    'PREREQ_PM' => { Unicode::Map8 => 0, Unicode::String => 0 }
);
