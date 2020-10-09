use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME	     => 'Tie::ListKeyedHash',
    VERSION_FROM     => 'lib/Tie/ListKeyedHash.pm',
    MIN_PERL_VERSION => '5.006',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002 ? ('LICENSE'  => 'mit', ) : ()),
    'PREREQ_PM'      => {
                          'Carp'              => 0,
                          'warnings'          => 0,
                          'Test::More'        => 0,
    }, 
    META_MERGE => {
       'meta-spec' => { version => 2 },
        resources => {
           bugtracker => {
                web  => 'https://github.com/JerilynFranz/perl-Tie-ListKeyedHash/issues',
            },
            homepage => 'https://github.com/JerilynFranz/perl-Tie-ListKeyedHash',
            repository => {
                type => 'git',
                url  => 'https://github.com/JerilynFranz/perl-Tie-ListKeyedHash.git',
                web  => 'https://github.com/JerilynFranz/perl-Tie-ListKeyedHash',
            },
        },
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Tie/ListKeyedHash.pod', # retrieve abstract from module
       AUTHOR         => 'Jerilyn Franz <cpan@jerilyn.info>') : ()),

       PL_FILES       => {},
);




