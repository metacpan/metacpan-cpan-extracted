

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'jQuery::DataTables',
    VERSION_FROM => 'lib/jQuery/DataTables.pm', # finds \$VERSION
    AUTHOR       => 'Konstantin Tokar (konstantin@tokar.ru)',
    ABSTRACT     => 'Server-side part of DataTables',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                    },
);
