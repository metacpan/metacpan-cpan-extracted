use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Text::FixEOL',
    VERSION_FROM      => 'lib/Text/FixEOL.pm', 
    MIN_PERL_VERSION  => '5.006',
    PREREQ_PM         => {
                         'warnings'           => 0,
                         'Carp'               => 0,
                         'Test::More'         => 0,
                         'Test::NoWarnings'   => '1.04',
                        }, 
    META_MERGE => {
       'meta-spec' => { version => 2 },
        resources => {
           bugtracker => {
                web  => 'https://github.com/JerilynFranz/perl-Text-FixEOL/issues',
            },
            homepage => 'https://github.com/JerilynFranz/perl-Text-FixEOL',
            repository => {
                type => 'git',
                url  => 'https://github.com/JerilynFranz/perl-Text-FixEOL.git',
                web  => 'https://github.com/JerilynFranz/perl-Text-FixEOL',
            },
        },
    },

    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Text/FixEOL.pod', # retrieve abstract from module
       AUTHOR         => 'Jerilyn Franz <cpan@jerilyn.info>') : ()),

    PL_FILES       => {},
);
