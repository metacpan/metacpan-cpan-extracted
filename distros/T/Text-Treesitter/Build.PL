use v5;
use strict;
use warnings;

use Module::Build::Using::PkgConfig;

my $build = Module::Build::Using::PkgConfig->new(
   module_name => 'Text::Treesitter',
   requires => {
      'perl' => '5.026',
      'Object::Pad' => 0,

      'ExtUtils::CppGuess' => 0,
      'JSON::MaybeUTF8' => 0,
      'List::Util' => '1.29',
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
      'Module::Build::Using::PkgConfig' => 0,
   },
   test_requires => {
      'File::Slurper' => 0,
      'Test::More' => '0.88', # done_testing
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->use_pkgconfig( "tree-sitter",
   atleast_version => "0.6.3",  ## TODO - minimise
);

$build->create_build_script;
