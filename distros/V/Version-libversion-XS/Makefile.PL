#!perl

use strict;
use warnings;
use ExtUtils::MakeMaker;

require DynaLoader;

eval "use Alien::Base::Wrapper qw(Alien::libversion !export)";
my $have_alien = $@ ? 0 : 1;

if (!DynaLoader::dl_findfile('-lversion') && !$have_alien) {
    print STDERR qq{ERROR: 'libversion' must be installed to compile 'Version::libversion::XS'!\n};
    print STDERR qq{       See https://github.com/repology/libversion#building for installation instructions\n};
    print STDERR qq{       or install "Alien::libversion" module.\n};
    exit 1;
}

my %args = (
    NAME               => 'Version::libversion::XS',
    AUTHOR             => q{Giuseppe Di Terlizzi <gdt@cpan.org>},
    VERSION_FROM       => 'lib/Version/libversion/XS.pm',
    ABSTRACT_FROM      => 'lib/Version/libversion/XS.pm',
    LICENSE            => 'artistic_2',
    LIBS               => ['-lversion'],
    INC                => '-I.',
    MIN_PERL_VERSION   => 5.010,
    CONFIGURE_REQUIRES => {'ExtUtils::MakeMaker' => '0'},
    TEST_REQUIRES      => {'Test::More'          => '0'},
    PREREQ_PM          => {},
    META_MERGE         => {
        'meta-spec' => {version => 2},
        'resources' => {
            bugtracker => {web => 'https://github.com/giterlizzi/perl-Version-libversion-XS/issues'},
            repository => {
                type => 'git',
                url  => 'git://github.com/giterlizzi/perl-Version-libversion-XS',
                web  => 'https://github.com/giterlizzi/perl-Version-libversion-XS'
            },
        },
        x_purl => 'pkg:cpan/GDT/Version-libversion-XS'
    },
    dist  => {COMPRESS => 'gzip -9f', SUFFIX => 'gz',},
    clean => {FILES    => 'Version-libversion-XS-*'},
);


if ($have_alien) {
    %args = (%args, Alien::Base::Wrapper->mm_args);
}

WriteMakefile(%args);
