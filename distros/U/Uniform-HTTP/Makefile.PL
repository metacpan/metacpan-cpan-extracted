use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Uniform::HTTP',
    VERSION_FROM => 'lib/Uniform/HTTP.pm',
    ABSTRACT     => 'Framework-neutral HTTP messages and authentication',
    AUTHOR       => 'Joshua S. Day <HAX@cpan.org>',
    LICENSE      => 'mit',
    MIN_PERL_VERSION => '5.016',
    PREREQ_PM => {
        'Carp'               => 0,
        'Crypt::SysRandom'   => '0.006',
        'Digest::MD5'        => 0,
        'Digest::SHA'        => '5.60',
        'Encode'             => 0,
        'MIME::Base64'       => 0,
        'Unicode::Normalize' => 0,
        'parent'             => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/haxmeister/perl-Uniform-HTTP.git',
                web  => 'https://github.com/haxmeister/perl-Uniform-HTTP',
            },
            bugtracker => {
                web => 'https://github.com/haxmeister/perl-Uniform-HTTP/issues',
            },
        },
    },
    clean => {
        FILES => 'Uniform-HTTP-*',
    },
);
