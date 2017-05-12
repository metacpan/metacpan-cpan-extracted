use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Test::MonitorSites',
    license             => 'gpl',
    dist_author         => 'Hugh Esco <hesco@greens.org>',
    dist_version_from   => 'lib/Test/MonitorSites.pm',
    requires => {
        'version'               => 0,
        'Cwd'                   => 0,
        'Carp'                  => 0,
        'Data::Dumper'          => 0,
        'Test::More'            => 0,
        'Test::Pod'             => 1.14,
        'Test::Pod::Coverage'   => 1.04,
        'Test::Builder'         => 0,
        'Mail::Mailer'          => 0,
        'Config::Simple'        => 0,
        'WWW::Mechanize'        => 0,
        'Test::WWW::Mechanize'  => 0,
        'Test::HTML::Tidy'      => 0,
        'HTTP::Request::Common' => 0,
        'Test::Builder::Tester' => 0,
    },
    add_to_cleanup      => [ 'Test-MonitorSites-*' ],
);

$builder->create_build_script();
