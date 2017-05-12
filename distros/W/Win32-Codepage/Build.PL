use Module::Build;
Module::Build->new(
   module_name => 'Win32::Codepage',
   dist_author => 'Clotho Advanced Media, Inc. <cpan@clotho.com>',
   license => 'perl',
   requires => {
      'Win32::Locale' => '0.04',
   },
   build_requires => {
      'Test::More' => 0,
   },
   add_to_cleanup => [ 'Win32-Codepage-*' ],
)->create_build_script;
