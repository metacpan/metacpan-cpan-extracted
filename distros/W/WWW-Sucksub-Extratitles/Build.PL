use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'WWW::Sucksub::Extratitles',
    license             => 'perl',
    dist_author         => 'Timothée foucart <timothee.foucart@apinc.org>',
    dist_version_from   => 'lib/WWW/Sucksub/Extratitles.pm',
    build_requires => {
        'Test::More' => '>=0.5',
        'WWW::Mechanize' => '>= 1.2',
        'DB_File'=> '>= 1.8',
        'HTTP::Cookies' => '>= 1.3',
	  'Carp' => '>= 1.0',
	  'Alias' => '>=2.3',
    },
    add_to_cleanup      => [ 'WWW-Sucksub-Extratitles-*' ],
);

$builder->create_build_script();
