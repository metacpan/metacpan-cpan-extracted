use strict;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'WWW::ColiPoste',
    license             => 'perl',
    dist_author         => 'Sebastien Aperghis-Tramoni <sebastien@aperghis.net>',
    dist_version_from   => 'lib/WWW/ColiPoste.pm',
    script_files        => [ 'bin/coliposte' ],
    requires => {
        'perl'              => 5,
        'Carp'              => 0,
        'File::Slurp'       => 0,
        'LWP::UserAgent'    => 0,
        'HTML::Entities'    => 0,
        'HTML::TreeBuilder' => 0,
        'URI'               => 0,
    },
    build_requires => {
        'Test::More'        => 0,
    },
    add_to_cleanup      => [ 'WWW-ColiPoste-*' ],
);

$builder->create_build_script();
