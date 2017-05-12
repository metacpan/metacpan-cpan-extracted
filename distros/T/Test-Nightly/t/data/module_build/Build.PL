use Module::Build;
my $build = Module::Build->new
(
 module_name => 'Test::Nightly::Test::Module',
 license => 'perl',
);
$build->create_build_script;
