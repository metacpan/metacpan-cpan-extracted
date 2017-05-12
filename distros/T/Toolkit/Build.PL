use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Toolkit',
    license             => 'perl',
    dist_author         => 'Damian Conway <DCONWAY@cpan.org>',
    dist_version_from   => 'lib/Toolkit.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
        'File::Spec::Functions' => 0,
        'Filter::Simple' => 0,
    },
    add_to_cleanup      => [ 'Toolkit-*' ],
);

$builder->create_build_script();
