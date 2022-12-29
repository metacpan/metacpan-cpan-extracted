#!/usr/bin/env perl

my $wasmer_version = `wasmer version` or do {
    die "no Wasmer version found (errno=$!)";
};

print "Wasmer version: $wasmer_version\n";

$wasmer_version =~ s<\A.*?([0-9]).*><$1>ms or do {
    die "Unrecognized Wasmer version: $wasmer_version\n";
};

if ($wasmer_version < 3) {
    die "Wasmer v3 or above is required.\n";
}

my $wasmer_lflags = `wasmer config --libs`;
die 'no lflags' if !$wasmer_lflags;

my $wasmer_cflags = `wasmer config --cflags`;
die 'no cflags' if !$wasmer_cflags;

my $wasmer_libdir = `wasmer config --libdir`;

chomp ($wasmer_cflags, $wasmer_lflags, $wasmer_libdir);

print "Wasmer CFLAGS: $wasmer_cflags\n";
print "Wasmer LIBS: $wasmer_lflags\n";

use ExtUtils::MakeMaker::CPANfile;
use Config;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Wasm::Wasmer',
    VERSION_FROM      => 'lib/Wasm/Wasmer.pm', # finds $VERSION
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Wasm/Wasmer.pm', # retrieve abstract from module
       AUTHOR         => [
            'Felipe Gasper (FELIPE)',
        ],
      ) : ()
    ),
    LIBS              => [$wasmer_lflags], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => "-Wall -I. --std=c11 $wasmer_cflags",
    LICENSE           => "perl_5",

    LDDLFLAGS => "$Config{'lddlflags'} -Wl,-rpath,$wasmer_libdir",

    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url => 'git://github.com/cpanel/p5-Wasm-Wasmer.git',
                web => 'https://github.com/cpanel/p5-Wasm-Wasmer',
            },
            bugtracker => {
                web => 'https://github.com/cpanel/p5-Wasm-Wasmer/issues',
            },
        },
    },
);
