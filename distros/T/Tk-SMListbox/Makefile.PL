use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'AUTHOR'    => 'Jim Turner',
    'ABSTRACT'  => 'Multi-Listbox Widget with Sort Indicators',
    'NAME'	=> 'Tk::SMListbox',
    'VERSION_FROM' => 'lib/Tk/SMListbox.pm', 
    'PREREQ_PM'  => {Tk=>0}
);
