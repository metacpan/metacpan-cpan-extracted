use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME             => 'Tie::DB_File::SplitHash',
    VERSION_FROM     => 'lib/Tie/DB_File/SplitHash.pm',
    MIN_PERL_VERSION => '5.006',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002 ? ('LICENSE'  => 'mit', ) : ()),
    'PREREQ_PM'      => {
                          'Digest::SHA1' => 0,
                          'DB_File'      => 0,
                          'File::Path'   => 0,
                          'File::Spec'   => 0,
                          'File::Temp'   => 0,
                          'Fcntl'        => 0,
                          'Carp' => 0,
    }, 
    META_MERGE => {
       'meta-spec' => { version => 2 },
        resources => {
           bugtracker => {
                web  => 'https://github.com/JerilynFranz/perl-Tie-DB_File-SplitHash/issues',
            },
            homepage => 'https://github.com/JerilynFranz/perl-Tie-DB_File-SplitHash',
            repository => {
                type => 'git',
                url  => 'https://github.com/JerilynFranz/perl-Tie-DB_File-SplitHash.git',
                web  => 'https://github.com/JerilynFranz/perl-Tie-DB_File-SplitHash',
            },
        },
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Tie/DB_File/SplitHash.pod', # retrieve abstract from module
       AUTHOR         => 'Jerilyn Franz <cpan@jerilyn.info>') : ()),

       PL_FILES       => {},
);

