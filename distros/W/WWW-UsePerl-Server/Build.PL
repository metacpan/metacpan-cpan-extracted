#!perl
use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    create_license => 1,
    create_readme  => 1,
    dist_abstract  => 'WWW::UsePerl::Server - Serve use.perl.org content',
    dist_author    => 'Leon Brocard <acme@astray.com>',
    license        => 'perl',
    meta_merge     => {
        resources => {
            homepage => 'http://search.cpan.org/dist/WWW-UsePerl-Server/',
        },
    },
    'meta-spec' => {
        version => '2',
        url     => 'http://search.cpan.org/perldoc?CPAN::Meta::Spec',
    },
    module_name => 'WWW::UsePerl::Server',
    requires    => {
        'Catalyst::Action::RenderView'     => 0,
        'Catalyst::Plugin::ConfigLoader'   => 0,
        'Catalyst::Plugin::Static::Simple' => 0,
        'Catalyst::Runtime'                => 0,
        'Catalyst::View::TT'               => 0,
        'Config::General'                  => 0,
        'Data::Pageset'                    => 0,
        'DateTime::Format::MySQL'          => 0,
        'DBI'                              => 0,
        'DBD::mysql'                       => 0,
        'Moose'                            => 0,
        'namespace::autoclean'             => 0,
        'Template::Plugin::Comma'          => 0,
    },
    sign => 1,
);
$build->create_build_script;
