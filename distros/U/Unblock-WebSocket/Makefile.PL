use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Unblock::WebSocket',
    VERSION_FROM     => 'lib/Unblock/WebSocket.pm',
    ABSTRACT_FROM    => 'lib/Unblock/WebSocket.pm',
    AUTHOR           => 'Joshua S. Day <hax@cpan.org>',
    LICENSE          => 'mit',
    MIN_PERL_VERSION => '5.016000',
    XS => {
        'WebSocket.xs' => 'WebSocket.c',
    },
    INC => '-Iinclude',
    LIBS => $^O eq 'MSWin32' ? ['-lbcrypt'] : [''],
    clean => {
        FILES => 'WebSocket.c',
    },
    PREREQ_PM => {
        'Compress::Raw::Zlib'   => '2.017',
        'Crypt::SysRandom'      => '0.006',
        'Digest::SHA'           => 0,
        'MIME::Base64'          => 0,
        'URI'                   => 0,
        'Uniform::HTTP'         => '0.05',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        no_index => {
            package => [qw(
                Unblock::WebSocket::_Deflate
                Unblock::WebSocket::_Engine
                Unblock::WebSocket::_Frame
                Unblock::WebSocket::_Frame::Parser
                Unblock::WebSocket::_Native
                Unblock::WebSocket::_Random
                Unblock::WebSocket::_UTF8
            )],
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/haxmeister/perl-Unblock-WebSocket.git',
                web  => 'https://github.com/haxmeister/perl-Unblock-WebSocket',
            },
            bugtracker => {
                web => 'https://github.com/haxmeister/perl-Unblock-WebSocket/issues',
            },
        },
    },
);
