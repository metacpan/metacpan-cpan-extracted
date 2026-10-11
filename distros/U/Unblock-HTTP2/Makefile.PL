use strict;
use warnings;
use Config;
use ExtUtils::MakeMaker;
use File::Find ();

require Alien::nghttp2;
require Uniform::HTTP::FastPath;

my $nghttp2_cflags = Alien::nghttp2->cflags;
my $nghttp2_libs   = Alien::nghttp2->libs;
my $nghttp2_define = $^O eq 'MSWin32' ? ' -DNGHTTP2_STATICLIB' : '';
my $uniform_include = Uniform::HTTP::FastPath::native_include_dir();
my $native_abi_include = 'lib/Unblock/HTTP2/NativeABI';

my $dist_version = MM->parse_version('lib/Unblock/HTTP2.pm');

my @public_modules = qw(
    Unblock::HTTP2
    Unblock::HTTP2::Client
    Unblock::HTTP2::Integration
    Unblock::HTTP2::NativeABI
    Unblock::HTTP2::Server
    Unblock::HTTP2::Transaction
);

my %provides = map {
    my $file = "lib/$_.pm";
    $file =~ s{::}{/}g;
    $_ => {
        file    => $file,
        version => $dist_version,
    };
} @public_modules;

my %install_files;
File::Find::find(sub {
    return unless /\.(?:pm|h)\z/ && -f $_;
    my $path = $File::Find::name;
    (my $installed = $path) =~ s{^lib/}{};
    $install_files{$path} = '$(INST_LIB)/' . $installed;
}, 'lib');

WriteMakefile(
    NAME             => 'Unblock::HTTP2',
    VERSION_FROM     => 'lib/Unblock/HTTP2.pm',
    ABSTRACT_FROM    => 'lib/Unblock/HTTP2.pm',
    AUTHOR           => 'Joshua S. Day <hax@cpan.org>',
    LICENSE          => 'mit',
    MIN_PERL_VERSION => '5.016',
    PM               => \%install_files,

    CONFIGURE_REQUIRES => {
        'Alien::nghttp2'       => '0.003',
        'ExtUtils::MakeMaker'  => '6.64',
        'File::Find'             => 0,
        'Uniform::HTTP'        => '0.06',
    },

    PREREQ_PM => {
        'Carp'          => 0,
        'File::Basename' => 0,
        'File::Spec'     => 0,
        'Scalar::Util'  => 0,
        'Uniform::HTTP' => '0.06',
        'XSLoader'      => 0,
    },

    TEST_REQUIRES => {
        'Test::More' => 0,
    },

    XS      => { 'nghttp2.xs' => 'nghttp2.c' },
    OBJECT  => '$(O_FILES)',
    CCFLAGS => "$Config{ccflags} $nghttp2_cflags$nghttp2_define",
    INC     => qq(-I"$uniform_include" -I"$native_abi_include"),
    LIBS    => [ $nghttp2_libs ],

    META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => \%provides,
        resources   => {
            homepage => 'https://github.com/haxmeister/perl-Unblock-HTTP2',
            repository => {
                type => 'git',
                url  => 'https://github.com/haxmeister/perl-Unblock-HTTP2.git',
                web  => 'https://github.com/haxmeister/perl-Unblock-HTTP2',
            },
            bugtracker => {
                web => 'https://github.com/haxmeister/perl-Unblock-HTTP2/issues',
            },
        },
        no_index => {
            package => [qw(
                Unblock::HTTP2::_Connection
                Unblock::HTTP2::_Headers
                Unblock::HTTP2::_nghttp2
                Unblock::HTTP2::_nghttp2::Session
                Unblock::HTTP2::_nghttp2::NativeDriver
            )],
        },
    },

    clean => {
        FILES => 'Unblock-HTTP2-* nghttp2.c nghttp2.o nghttp2.obj HTTP2.bs',
    },
);
