use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'          => 'Tie::DBI',
    'AUTHOR'        => 'Lincoln D. Stein <lds@cpan.org>',
    'VERSION_FROM'  => 'lib/Tie/DBI.pm',                    # finds $VERSION
    'ABSTRACT_FROM' => 'lib/Tie/DBI.pm',
    'PREREQ_PM'     => {
        'Test::More'  => 0,
        'DBI'         => 0,
        'DBD::SQLite' => 0,
    },
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002 ? ( 'LICENSE' => 'perl', ) : () ),
    'DISTNAME' => 'Tie-DBI',
    'linkext'  => { LINKTYPE => '' },                       # no link needed
    'dist'     => {
        'COMPRESS' => 'gzip -9f',     'SUFFIX'   => 'gz',
        'ZIP'      => '/usr/bin/zip', 'ZIPFLAGS' => '-rl'
    },
    'clean'      => { FILES => 'Tie-DBI-* test:* depth_test' },
    'META_MERGE' => {
        build_requires => {
            'Test::More'  => 0,                             # For testing
            'DBD::SQLite' => 0,                             # Make sure at least one DBD is there for automated testing
        },
        resources => {
            license  => 'http://dev.perl.org/licenses/',
            homepage => 'http://wiki.github.com/toddr/Tie-DBI/',

            #            bugtracker => 'http://code.google.com/p/Tie-DBI/issues/list',
            repository => 'http://github.com/toddr/Tie-DBI',

            #            MailingList => 'http://groups.google.com/group/Tie-DBI',
        },
    },
  )
