use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'YAMLScript',
  VERSION_FROM => 'lib/YAMLScript.pm',
  ABSTRACT => 'Program in YAML - Code is Data',
  AUTHOR => 'Ingy dot Net <ingy@ingy.net>',
  LICENSE => 'mit',
  MIN_PERL_VERSION => '5.016',
  PREREQ_PM => {
    'Alien::YAMLScript' => '0.2.12',
    'Cpanel::JSON::XS' => '4.37',
    'FFI::CheckLib' => '0.31',
    'FFI::Platypus' => '2.08',
  },
  TEST_REQUIRES => {
    'Test2::V0' => '0.000159',
  },
  META_MERGE => {
    'meta-spec' => { version => 2 },
    resources => {
      bugtracker => {
        web => 'https://github.com/yaml/yamlscript/issues',
      },
      homepage => 'https://yamlscript.org',
      repository => {
        type => 'git',
        url => 'https://github.com/yaml/yamlscript.git',
        web => 'https://github.com/yaml/yamlscript',
      },
    },
  },
);
