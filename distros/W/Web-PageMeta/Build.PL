use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name        => 'Web::PageMeta',
    license            => 'perl',
    dist_author        => 'Jozef Kutej <jkutej@cpan.org>',
    dist_version_from  => 'lib/Web/PageMeta.pm',
    configure_requires => {'Module::Build' => '0.3607',},
    requires           => {
        'perl'                   => '5.022',    # because of Future::AsyncAwait
        'Moose'                  => 0,
        'MooseX::Types::URI'     => 0,
        'URI'                    => 0,
        'URI::QueryParam'        => 0,
        'Log::Any'               => 0,
        'Future'                 => 0,
        'Future::AsyncAwait'     => 0,
        'Future::HTTP::AnyEvent' => 0,
        'AnyEvent::HTTP'         => 0,          # because of Future::HTTP::AnyEvent
        'Web::Scraper'           => 0,
        'Encode'                 => 0,
        'Time::HiRes'            => 0,
        'namespace::autoclean'   => 0,
        'HTTP::Exception'        => 0,
    },
    build_requires => {
        'Test::Most'       => 0,
        'URI::Escape'      => 0,
        'Path::Class'      => 0,
        'AnyEvent'         => 0,
        'AnyEvent::Future' => 0,
    },
    add_to_cleanup => ['Web-PageMeta-*'],
    create_readme  => 1,
    meta_merge     => {
        resources => {
            repository => 'https://github.com/jozef/Web-PageMeta',
            bugtracker => 'https://github.com/jozef/Web-PageMeta/issues',
        },
        keywords => [qw/ open graph opengraph web page meta title preview /],
    },
);

$builder->create_build_script();
