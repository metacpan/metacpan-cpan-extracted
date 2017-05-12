use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    create_makefile_pl => 'traditional',
    license            => 'perl',
    module_name        => 'Win32::EmailSend',
    dist_author        => 'Gernot Havranek <havi@cpan.org>',
    requires => {
        perl => '5.10.0',
    },
    build_requires => {
        'Test::More' => 0,
        'Win32::OLE' => 0
    },
    recommends         => {
    },
    create_readme      => 1,
);
$build->create_build_script;
