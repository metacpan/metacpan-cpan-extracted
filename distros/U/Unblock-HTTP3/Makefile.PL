use strict;
use warnings;

use Alien::nghttp3 0.01 ();
use ExtUtils::MakeMaker;
use File::Find ();
use Uniform::HTTP::FastPath 0.06 ();

my $cflags = Alien::nghttp3->cflags;
my $uniform_http_include = Uniform::HTTP::FastPath::native_include_dir();

sub _makemaker_libs {
    my ($flags) = @_;

    my @out;

    for my $token (split /\s+/, $flags) {
        next if !length $token;

        if ($token =~ m{\A(.+)/([^/]+)\.(a|lib)\z}i) {
            my ($dir, $name) = ($1, $2);

            $name =~ s/\Alib//;

            push @out, "-L$dir", "-l$name";
            next;
        }

        push @out, $token;
    }

    return join ' ', @out;
}

my $libs = _makemaker_libs(Alien::nghttp3->libs);

my %install_files;
File::Find::find(sub {
    return unless /\.(?:pm|h)\z/ && -f $_;
    my $path = $File::Find::name;
    (my $installed = $path) =~ s{^lib/}{};
    $install_files{$path} = '$(INST_LIB)/' . $installed;
}, 'lib');

WriteMakefile(
    NAME             => 'Unblock::HTTP3',
    VERSION_FROM     => 'lib/Unblock/HTTP3.pm',
    ABSTRACT_FROM    => 'lib/Unblock/HTTP3.pm',
    AUTHOR           => 'Joshua S. Day <haxmeister@hotmail.com>',
    LICENSE          => 'mit',
    MIN_PERL_VERSION => '5.020',
    PM               => \%install_files,

    CONFIGURE_REQUIRES => {
        'Alien::nghttp3'       => '0.01',
        'ExtUtils::MakeMaker'  => 0,
        'File::Find'            => 0,
        'Uniform::HTTP'         => '0.06',
    },

    PREREQ_PM => {
        'Alien::nghttp3' => '0.01',
        'Carp'           => 0,
        'File::Basename' => 0,
        'File::Spec'     => 0,
        'Net::QUIC'      => '0.04',
        'Scalar::Util'    => 0,
        'Time::HiRes'     => 0,
        'Uniform::HTTP'    => '0.06',
        'XSLoader'        => 0,
        'parent'          => 0,
    },

    TEST_REQUIRES => {
        'FindBin'          => 0,
        'IO::Select'       => 0,
        'IO::Socket::INET' => 0,
        'Socket'           => 0,
        'Test2::V0'        => 0,
    },

    INC  => join(' ', $cflags, qq(-I"$uniform_http_include")),
    LIBS => [$libs],

    META_MERGE => {
        'meta-spec' => {
            version => 2,
        },
        no_index => {
            package => [
                'Unblock::HTTP3::_Bytes',
                'Unblock::HTTP3::_Native',
            ],
        },
        provides => {
            'Unblock::HTTP3' => {
                file    => 'lib/Unblock/HTTP3.pm',
                version => MM->parse_version('lib/Unblock/HTTP3.pm'),
            },
            'Unblock::HTTP3::Body::Reader' => {
                file    => 'lib/Unblock/HTTP3/Body/Reader.pm',
                version => MM->parse_version('lib/Unblock/HTTP3/Body/Reader.pm'),
            },
            'Unblock::HTTP3::Body::Stream' => {
                file    => 'lib/Unblock/HTTP3/Body/Stream.pm',
                version => MM->parse_version('lib/Unblock/HTTP3/Body/Stream.pm'),
            },
            'Unblock::HTTP3::Capsule' => {
                file    => 'lib/Unblock/HTTP3/Capsule.pm',
                version => MM->parse_version('lib/Unblock/HTTP3/Capsule.pm'),
            },
            'Unblock::HTTP3::Capsule::Parser' => {
                file    => 'lib/Unblock/HTTP3/Capsule/Parser.pm',
                version => MM->parse_version('lib/Unblock/HTTP3/Capsule/Parser.pm'),
            },
            'Unblock::HTTP3::Capsule::Stream' => {
                file    => 'lib/Unblock/HTTP3/Capsule/Stream.pm',
                version => MM->parse_version('lib/Unblock/HTTP3/Capsule/Stream.pm'),
            },
            'Unblock::HTTP3::Extension::Stream' => {
                file    => 'lib/Unblock/HTTP3/Extension/Stream.pm',
                version => MM->parse_version('lib/Unblock/HTTP3/Extension/Stream.pm'),
            },
            'Unblock::HTTP3::Connection' => {
                file    => 'lib/Unblock/HTTP3/Connection.pm',
                version => MM->parse_version('lib/Unblock/HTTP3/Connection.pm'),
            },
            'Unblock::HTTP3::NativeABI' => {
                file    => 'lib/Unblock/HTTP3/NativeABI.pm',
                version => MM->parse_version('lib/Unblock/HTTP3/NativeABI.pm'),
            },
            'Unblock::HTTP3::Transaction' => {
                file    => 'lib/Unblock/HTTP3/Transaction.pm',
                version => MM->parse_version('lib/Unblock/HTTP3/Transaction.pm'),
            },
        },
        resources => {
            homepage => 'https://github.com/haxmeister/perl-Unblock-HTTP3',
            repository => {
                type => 'git',
                url  => 'https://github.com/haxmeister/perl-Unblock-HTTP3.git',
                web  => 'https://github.com/haxmeister/perl-Unblock-HTTP3',
            },
            bugtracker => {
                web => 'https://github.com/haxmeister/perl-Unblock-HTTP3/issues',
            },
        },
    },
);