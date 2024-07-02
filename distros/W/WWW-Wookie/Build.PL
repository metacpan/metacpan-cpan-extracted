# -*- cperl; cperl-indent-level: 4 -*-
use 5.020;
use strict;
use warnings;
use Module::Build;
use lib 'inc';
use WWW::Wookie::Module::Build;

our $VERSION = v1.1.6;

WWW::Wookie::Module::Build->new(
    'module_name' => 'WWW::Wookie',
    'license'     => 'perl',
    'dist_author' => 'Roland van Ipenburg <roland@rolandvanipenburg.com>',
    'requires'    => {
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
        'perl'                         => '5.20.0',
        'strict'                       => 0,
        'utf8'                         => 0,
        'warnings'                     => 0,
    },
    'configure_requires' => { 'Module::Build' => 0.40, },
    'build_requires'     => { 'Module::Build' => 0.40, },
    'test_requires'      => {
        'Test::More'             => 0.81,
        'Test::NoWarnings'       => 0,
        'Test2::Require::Module' => 0,
        'Test2::Suite'           => 0,
    },
    'recommends' => {
        'CGI'                     => 0,
        'Getopt::Long'            => 0,
        'Pod::Usage'              => 0,
        'Pod::Usage::CommandLine' => 0,
    },
    'script_files' => [qw(scripts/TestWookieService.pl)],
    'sign'         => 1,
    'meta_merge'   => {
        'resources' => {
            'repository' =>
              'https://bitbucket.org/rolandvanipenburg/www-wookie',
            'bugtracker' =>
              'https://bitbucket.org/rolandvanipenburg/www-wookie/issues',
        },
        'x_authority' => 'cpan:IPENBURG',
    },
)->create_build_script;
