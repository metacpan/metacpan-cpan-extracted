
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'Module::Build' => '0.3601',
    'Test::More' => '0'
  },
  'configure_requires' => {
    'ExtUtils::MakeMaker' => '6.31',
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'Atom feed for web',
  'dist_author' => [
    'Gea-Suan Lin <gslin@gslin.org>'
  ],
  'dist_name' => 'Web-Atom',
  'dist_version' => '0.1.0',
  'license' => 'bsd',
  'module_name' => 'Web::Atom',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Any::Moose' => '0',
    'Carp' => '0',
    'Encode' => '0',
    'LWP::UserAgent' => '0',
    'XML::Atom::Entry' => '0',
    'XML::Atom::Feed' => '0',
    'XML::Atom::Link' => '0',
    'XML::Atom::Person' => '0',
    'namespace::autoclean' => '0'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
