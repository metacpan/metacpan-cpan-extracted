use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Tk::Win32RotLabel',
    'VERSION_FROM'	=> 'Win32RotLabel.pm', # finds $VERSION
    'PREREQ_PM'		=> {Win32::API => 0.41}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Win32RotLabel.pm', # retrieve abstract from module
       AUTHOR     => 'Ala Qumsieh <aqumsieh@cpan.org>') : ()),
);
