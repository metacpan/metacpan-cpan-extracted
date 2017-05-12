use strict;
use Module::Build;

my $build = Module::Build->new(
    create_makefile_pl	=> 'small',
    license		=> 'perl',
    module_name		=> 'Win32::Security::EFS',
    requires		=> {
        'Encode' => 0,
        'Win32'			=> 0.24,
        'Win32::API::Interface'	=> 0.01,
        'File::Spec'	=> 3.05,
        'Module::Build' => 0.2,
    },
    reccomends => {
    },
    create_readme => 1,
    sign          => 0,
);
$build->create_build_script;