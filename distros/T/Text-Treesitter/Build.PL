use v5;
use strict;
use warnings;

use Module::Build::Using::PkgConfig;

my @extra_compiler_flags = qw( -Ihax );

my $build = Module::Build::Using::PkgConfig->new(
   module_name => 'Text::Treesitter',
   requires => {
      'perl' => '5.026',
      'Object::Pad' => '0.805',
      'Sublike::Extended' => 0,
      'Syntax::Keyword::Match' => 0,

      'ExtUtils::CppGuess' => 0,
      'File::Slurper' => 0,
      'JSON::MaybeUTF8' => 0,
      'List::Util' => '1.29',
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
      'Module::Build::Using::PkgConfig' => 0,
   },
   test_requires => {
      'Test2::V0' => 0,
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
   extra_compiler_flags => \@extra_compiler_flags,
);

$build->use_pkgconfig( "tree-sitter",
   atleast_version => "0.6.3",  ## TODO - minimise
);

$build->create_build_script;
