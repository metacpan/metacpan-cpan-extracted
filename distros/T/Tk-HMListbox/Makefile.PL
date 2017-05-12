use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'AUTHOR'        => 'Jim Turner',
    'VERSION_FROM'  => 'lib/Tk/HMListbox.pm', 
    'ABSTRACT_FROM' => 'lib/Tk/HMListbox.pm', 
    'NAME'	         => 'Tk::HMListbox',
    'PREREQ_PM'     => {
        'Tk'           => 0,
        'Tk::HListbox' => 0,
        'Test::More'   => 0,
    },
    dist             => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean            => { FILES => 'Tk-HMListbox-*' },
);
