use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'WWW::Sucksub::Vostfree',
    license             => 'perl',
    dist_author         => 'Timothée Foucart <timothee.foucart@apinc.org>',
    dist_version_from   => 'lib/WWW/Sucksub/Vostfree.pm',
    requires => {
         'Test::More' => '>=0.5',
         'WWW::Mechanize' => '>= 1.02',
         'DB_File'=> '>= 1.8',
         'Carp' => '>= 1.0',
         'HTML::Parser' => '>=1.0',
         'Alias' => '>=2.3',
    },
    add_to_cleanup      => [ 'WWW-Sucksub-Vostfree-*' ],
);

$builder->create_build_script();
