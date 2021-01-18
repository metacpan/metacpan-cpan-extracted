use strict;
use warnings;
use Module::Build;
Module::Build->new(
    module_name => 'WWW::Wookie',
    license     => 'perl',
    dist_author => 'Roland van Ipenburg <roland@rolandvanipenburg.com>',
    requires    => {
        'perl'                         => '5.20.0',
        'Exception::Class'             => 0,
        'HTTP::Headers'                => 0,
        'HTTP::Request'                => 0,
        'HTTP::Request::Common'        => 0,
        'HTTP::Status'                 => 0,
        'LWP::UserAgent'               => 0,
        'Moose'                        => 0,
        'Moose::Role'                  => 0,
        'Moose::Util::TypeConstraints' => 0,
        'Readonly'                     => 0,
        'Regexp::Common'               => 0,
        'URI'                          => 1.62,
        'URI::Escape'                  => 1.62,
        'XML::Simple'                  => 0,
        'namespace::autoclean'         => 0,
        'overload'                     => 0,
    },
    configure_requires => { 'Module::Build' => 0.40, },
    build_requires     => {},
    test_requires      => {
        'Test::More'       => 0.81,
        'Test::NoWarnings' => 0.81,
    },
    recommends => {
        'CGI'                        => 0,
        'Getopt::Long'               => 0,
        'Perl::Critic::Bangs'        => 0,
        'Perl::Critic::Itch'         => 0,
        'Perl::Critic::More'         => 0,
        'Perl::Critic::Nits'         => 0,
        'Perl::Critic::Pulp'         => 0,
        'Perl::Critic::StricterSubs' => 0,
        'Perl::Critic::Tics'         => 0,
        'Pod::Usage'                 => 0,
        'Pod::Usage::CommandLine'    => 0,
        'Test::Kwalitee'             => 0,
        'Test::Perl::Critic'         => 0,
        'Test::Pod'                  => 1.41,
        'Test::Pod::Coverage'        => 1.00,
        'Test::Spelling'             => 0,
        'Test::TestCoverage'         => 0.08,
        'Test::CheckManifest'        => 1.01,
    },
    script_files => [qw(scripts/TestWookieService.pl)],
    sign         => 1,
    meta_merge   => {
        resources => {
            repository => 'https://bitbucket.org/rolandvanipenburg/www-wookie',
            bugtracker => {
                web =>
                  'https://bitbucket.org/rolandvanipenburg/www-wookie/issues',
            },
        },
    },
)->create_build_script;
