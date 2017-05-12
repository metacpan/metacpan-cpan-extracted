use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Tk::Dressing',
    license             => 'perl',
    dist_author         => q{Djibril Ousmanou <djibel@cpan.org>},
    dist_version_from   => 'lib/Tk/Dressing.pm',
    build_requires => {
        'Test::More'  => 0,
        'Config::Std' => '0.007',
        'File::Copy'  => 0,
        'File::Basename' => 0,
        'File::Spec'     => 0,
        'Tk'             => 800,
    },
    add_to_cleanup     => [ 'Tk-Dressing-*' ],
    create_makefile_pl => 'traditional',
);

$builder->add_build_element('ini');
$builder->create_build_script();
