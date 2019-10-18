#!perl
use 5.10.0;
use strict;
use warnings;
use Module::Build;
Module::Build->VERSION('0.4004');

if ($^O =~ /MSWin32/) {
    say "Windows is not supported";
    exit 0;
}

my $builder = Module::Build->new(
    module_name        => 'Unix::ScriptUtil',
    license            => 'bsd',
    dist_author        => q{Jeremy Mates <jeremy.mates@gmail.com>},
    dist_version_from  => 'lib/Unix/ScriptUtil.pm',
    release_status     => 'stable',
    configure_requires => { 'Module::Build' => '0.4004', },
    test_requires      => {
        'perl'       => '5.10.0',
        'strict'     => '0',
        'Cwd'        => '0',
        'Test::Most' => '0',
    },
    requires => {
        'perl'   => '5.10.0',
        'Carp'   => '0',
        'POSIX'  => '0',
        'strict' => '0',
    },
    sign           => 1,
    add_to_cleanup => [ 'Unix-ScriptUtil-*', 't/*.out' ],
    auto_features  => {
        dist_authoring => {
            description => "Create new distributions",
            requires    => {
                'Archive::Tar'      => 1.09,
                'Module::Signature' => 0.21,
            },
        },
    },
    meta_merge =>
      { resources => { repository => 'https://github.com/thrig/Unix-ScriptUtil' } },
);

$builder->create_build_script();
