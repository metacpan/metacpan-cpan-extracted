use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'AUTHOR'         => 'Jim Turner',
    'VERSION_FROM'   => 'lib/Tk/HListbox.pm', 
    'ABSTRACT_FROM'  => 'lib/Tk/HListbox.pm',
    'NAME'	          => 'Tk::HListbox',
    'PREREQ_PM' => {
        'Tk' => 0,
        'Test::More' => 0,
    },
    dist             => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean            => { FILES => 'Tk-HListbox-*' },
);
