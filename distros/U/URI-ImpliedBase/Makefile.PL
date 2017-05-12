use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'URI::ImpliedBase',
    VERSION_FROM => 'lib/URI/ImpliedBase.pm', # finds $VERSION
    AUTHOR       => 'Joe McMahon (mcmahon@ibiblio.org)',
    ABSTRACT     => 'URIs that magically set a default base',
    LICENSE      => 'artistic',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                     'URI' => 0,
                     'Cwd' => 0,
                    },
);
