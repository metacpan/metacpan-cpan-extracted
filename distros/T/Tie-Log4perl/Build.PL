use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    license       => 'perl',
    module_name   => 'Tie::Log4perl',
    dist_abstract => 'Tie a filehandle to log via Log4perl',

    requires => {
        'Log::Log4perl' => 0,
    },

    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
