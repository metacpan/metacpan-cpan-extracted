use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'          => 'XML::GXML',
    'VERSION_FROM'  => 'GXML.pm', # finds $VERSION
    'PREREQ_PM'     => {
                       'Cwd' => 1,
                       'File::Basename' => 1,
                       'File::Path' => 1,
                       'File::Spec' => .7,
                       'XML::Parser' => 2,
                       },
);
