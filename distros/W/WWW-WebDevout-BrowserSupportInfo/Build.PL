use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'WWW::WebDevout::BrowserSupportInfo',
    license             => 'perl',
    dist_author         => 'Zoffix Znet <zoffix@cpan.org>',
    dist_version_from   => 'lib/WWW/WebDevout/BrowserSupportInfo.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Carp'           => 1.04,
        'URI'            => 1.35,
        'LWP::UserAgent' => 2.036,
        'overload'       => 1.04,
        perl             => '5.006',
    },
    configure_requires => { 'Module::Build' => 0 },
    add_to_cleanup      => [ 'WWW-WebDevout-BrowserSupportInfo-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
