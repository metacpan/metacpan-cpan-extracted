use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'         => 'Tk::MinMaxScale',
    'VERSION_FROM' => 'MinMaxScale.pm', # finds $VERSION
    depend => { '$(FIRST_MAKEFILE)' => '$(VERSION_FROM)' },
    'PREREQ_PM'    => {'Tk' => '0'}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
        (ABSTRACT_FROM => 'MinMaxScale.pm', # retrieve abstract from module
        AUTHOR         => 'Jean-Pierre Vidal <jeanpierre.vidal@free.fr>') : ()),
);
