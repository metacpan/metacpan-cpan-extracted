use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Text::AsciiTeX',
    dist_version_from => 'lib/Text/AsciiTeX.pm',
    dist_abstract     => 'Convert (La)TeX formulas to ASCII art',
    dist_author       => 'Joel Berger <joel.a.berger@gmail.com>',
    license           => 'perl',
    requires          => {
      'perl' => '5.008',
      parent => 0,
    },
    configure_requires => {
      'Module::Build' => 0.38,
    },
    build_requires    => {
      'ExtUtils::CBuilder' => 0,
    },
    c_source => 'src',
    extra_compiler_flags => '-Isrc/asciitex -Isrc/perl',
);

$builder->create_build_script;
