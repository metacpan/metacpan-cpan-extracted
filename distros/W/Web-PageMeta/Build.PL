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
        'perl'                      => '5.022',    # because of Future::AsyncAwait
        'Moose'                     => '2.2014',
        'MooseX::Types::URI'        => '0.08',
        'MooseX::StrictConstructor' => '0.21',
        'URI'                       => '5.07',
        'URI::QueryParam'           => '5.07',
        'Log::Any'                  => '1.709',
        'Future'                    => '0.47',
        'Future::AsyncAwait'        => '0.48',
        'Future::HTTP::AnyEvent'    => '0.14',
        'AnyEvent::HTTP'            => '2.25',     # because of Future::HTTP::AnyEvent
        'Web::Scraper'              => '0.38',
        'Web::Scraper::LibXML'      => '0',
        'HTML::TreeBuilder::LibXML' => '0.26',
        'Encode'                    => '3.06',
        'Time::HiRes'               => '1.9764',
        'namespace::autoclean'      => '0.29',
        'HTTP::Exception'           => '0.04007',
        'List::Util'                => '1.55',
    },
    build_requires => {
        'Test::Most'       => '0.37',
        'URI::Escape'      => '5.07',
        'Path::Class'      => '0.37',
        'AnyEvent'         => '7.17',
        'AnyEvent::Future' => '0.04',
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
