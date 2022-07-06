use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::Spec();

my $dev_null = File::Spec->devnull();

my $binary = 'rsyslogd';
system("$binary -v 2>$dev_null >$dev_null") and die "Please install the $binary executable\n";

WriteMakefile(
    NAME             => 'Test::Rsyslog',
    AUTHOR           => q{David Dick <ddick@cpan.org>},
    VERSION_FROM     => 'lib/Test/Rsyslog.pm',
    ABSTRACT_FROM    => 'lib/Test/Rsyslog.pm',
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002
        ? ( 'LICENSE' => 'perl' )
        : () ),
    (
        $ExtUtils::MakeMaker::VERSION >= 6.48
        ? ( 'MIN_PERL_VERSION' => '5.006' )
        : ()
    ),
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                url  => 'https://github.com/david-dick/test-rsyslog',
                web  => 'https://github.com/david-dick/test-rsyslog',
                type => 'git',
            },
            bugtracker => {
                web => 'https://github.com/david-dick/test-rsyslog/issues'
            },
        },
    },
    LICENSE          => 'perl_5',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
        'File::Spec' => 0,
        'strict' => 0,
        'warnings' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
	'Sys::Syslog' => 0,
    },
    PREREQ_PM => {
        'Carp' => 0,
        'Config' => 0,
        'English' => 0,
        'FileHandle' => 0,
	'File::Temp' => 0,
	'Fcntl' => 0,
        'File::Spec' => 0,
        'POSIX' => 0,
        'strict' => 0,
        'warnings' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Test-Rsyslog-*' },
);
