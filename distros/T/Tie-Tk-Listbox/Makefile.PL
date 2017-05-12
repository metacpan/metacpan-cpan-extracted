use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Tie::Tk::Listbox',
    'VERSION_FROM'	=> 'lib/Tie/Tk/Listbox.pm', # finds $VERSION
    'PREREQ_PM'		=> {
                             Tk => 0,
                             Test::More => 0,
                           }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Tie/Tk/Listbox.pm', # retrieve abstract from module
       AUTHOR     => 'Steffen Mueller <tklistbox-module@steffen-mueller.net') : ()),
);


