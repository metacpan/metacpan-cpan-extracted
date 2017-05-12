use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Tree::R',
    VERSION_FROM      => 'lib/Tree/R.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/Tree/R.pm', # retrieve abstract from module
    AUTHOR            => 'Ari Jolma <https://github.com/ajolma>',
    LICENSE           => 'perl_5',
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/ajolma/Tree-R.git',
                web  => 'https://github.com/ajolma/Tree-R',
            },
        },
    },
);
