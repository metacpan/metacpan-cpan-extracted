use Module::Build;

Module::Build->new
  (
   module_name => 'VCS::Rcs::Parser',
   license => 'perl',
  )->create_build_script;
