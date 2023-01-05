#! /usr/bin/perl

use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

if ( -e '/usr/share/zoneinfo' ) {
}
elsif ( -e '/usr/lib/zoneinfo' ) {
}
elsif ( -e '/etc/zoneinfo' ) {
}
elsif ( -e '/usr/share/lib/zoneinfo' ) {    # solaris
}
elsif ( ( $ENV{TZDIR} ) && ( -e $ENV{TZDIR} ) ) {
}
elsif ( $^O eq 'MSWin32' ) {
}
else {
    die "Olson database could not be detected";
}

my $pack_q_ok = 0;

eval { my $q = pack 'q>', 2**33; my $p = unpack 'q>', $q; $pack_q_ok = 1; };

WriteMakefile(
    NAME               => 'Time::Zone::Olson',
    AUTHOR             => q{David Dick <ddick@cpan.org>},
    VERSION_FROM       => 'lib/Time/Zone/Olson.pm',
    ABSTRACT_FROM      => 'lib/Time/Zone/Olson.pm',
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
                url  => 'https://github.com/david-dick/time-zone-olson',
                web  => 'https://github.com/david-dick/time-zone-olson',
                type => 'git',
            },
            bugtracker => {
                web => 'https://github.com/david-dick/time-zone-olson/issues'
            },
        },
    },
    PL_FILES           => {},
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    TEST_REQUIRES => {
        'Test::More'  => 0,
        'Time::Local' => 0,
        $^O eq 'MSWin32' ? ( 'Win32::API' => 0.84 ) : (),
        'XML::LibXML'          => 0,
        'LWP::UserAgent'       => 0,
        'LWP::Protocol::https' => 6.06,
        'HTTP::Request'        => 0,
        $ENV{RELEASE_TESTING} ? ( 'Taint::Util' => 0 ) : (),
        'Fcntl'                => 0,
        'File::Temp'           => 0,
        $^O eq 'MSWin32' ? ( 'Win32' => 0 ) : (),
    },
    PREREQ_PM => {
        'Carp'        => 0,
        'Config'      => 0,
        'Digest::SHA' => 0,
        'DirHandle'   => 0,
        'Encode'      => 0,
        'English'     => 0,
        'FileHandle'  => 0,
        'File::Find'  => 0,
        'File::Spec'  => 0,
        $pack_q_ok == 0 ? ( 'Math::Int64' => 0 ) : (),
        'POSIX'    => 0,
        'strict'   => 0,
        'warnings' => 0,
        $^O eq 'MSWin32' ? ( 'Win32API::Registry' => 0 ) : (),
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Time-Zone-Olson-*' },
);
