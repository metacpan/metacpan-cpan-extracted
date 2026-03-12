use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'WebServer::DirIndex',
    AUTHOR           => 'Dave Cross <dave@perlhacks.com>',
    VERSION_FROM     => 'lib/WebServer/DirIndex.pm',
    ABSTRACT_FROM    => 'lib/WebServer/DirIndex.pm',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.026',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    PREREQ_PM => {
        'Path::Tiny'             => '0',
        'Feature::Compat::Class' => '0.07',
        'HTTP::Date'             => '0',
        'HTML::Escape'           => '0',
        'MIME::Types'            => '0',
        'URI::Escape'            => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
        'File::Temp' => '0',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/davorg-cpan/webserver-dirindex.git',
                web  => 'https://github.com/davorg-cpan/webserver-dirindex',
            },
            bugtracker => {
                web => 'https://github.com/davorg-cpan/webserver-dirindex/issues',
            },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'WebServer-DirIndex-*' },
);
