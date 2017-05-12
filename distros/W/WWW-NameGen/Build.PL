use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'WWW::NameGen',
    license             => 'perl',
    dist_author         => 'Nick Gerakines <nick@socklabs.com>',
    dist_version_from   => 'lib/WWW/NameGen.pm',
    build_requires => {
		'LWP::UserAgent' => 0,
		'Test::Deep' => 0,
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'WWW-NameGen-*' ],
);

$builder->create_build_script();
