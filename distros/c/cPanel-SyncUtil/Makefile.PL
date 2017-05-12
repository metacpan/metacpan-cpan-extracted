use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'cPanel::SyncUtil',
    ABSTRACT_FROM => 'lib/cPanel/SyncUtil.pm',
    AUTHOR        => 'cPanel Inc. <http://cpanel.net>',
    VERSION_FROM  => 'lib/cPanel/SyncUtil.pm',
    PREREQ_PM     => {
        'File::Slurp'       => 0,
        'File::Find'        => 0,
        'Digest::MD5::File' => 0,
        'Digest::SHA'       => 0,
        'Archive::Tar'      => 0,
        'Getopt::Std'       => 0,
    },
    META_MERGE => {
        build_requires => {
            'Test::More' => 0,    # For testing
        },
        resources => {
            license    => 'http://dev.perl.org/licenses/',
            homepage   => 'http://cpanel.net',
            repository => 'https://github.com/CpanelInc/cPanel-SyncUtil',
        },
    },
);
