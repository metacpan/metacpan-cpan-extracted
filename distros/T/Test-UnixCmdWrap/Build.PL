#!perl
use 5.24.0;
use warnings;
use Module::Build;
Module::Build->VERSION('0.4004');

# there is also Devel::CheckOS but the use-devel-assertos script seems a
# bit too complicated every time I look at it. so...
if ($^O =~ /MSWin32/) {
    say "Windows is not supported";
    exit 0;
}

my $builder = Module::Build->new(
    module_name        => 'Test::UnixCmdWrap',
    license            => 'bsd',
    dist_author        => q{Jeremy Mates <jeremy.mates@gmail.com>},
    dist_version_from  => 'lib/Test/UnixCmdWrap.pm',
    release_status     => 'stable',
    create_license     => 0,
    create_readme      => 0,
    dynamic_config     => 0,
    configure_requires => { 'Module::Build' => '0.4004', },
    test_requires      => { 'Cwd' => '0', 'Test::Most' => '0', },
    requires           => {
        'perl'              => '5.24.0',
        'Carp'              => '0',
        'Cwd'               => '0',
        'File::Spec'        => '0',
        'Moo'               => '0',
        'Test::Cmd'         => '0',
        'Test::Differences' => '0',
        'Test::More'        => '0',
        'Test::UnixExit'    => '0.02',
    },
    sign           => 1,
    add_to_cleanup => ['Test-UnixCmdWrap-*'],
    auto_features  => {
        dist_authoring => {
            description => "Create new distributions",
            requires    => {
                'Archive::Tar'      => 1.09,
                'Module::Signature' => 0.21,
            },
        },
    },
    meta_merge => {
        resources => { repository => 'https://github.com/thrig/Test-UnixCmdWrap' }
    },
);

$builder->create_build_script();
