#!/usr/bin/env -S perl -w   # -*- cperl; cperl-indent-level: 4 -*-
use 5.006;
use strict;
use warnings;
use Module::Build;

our $VERSION = v1.0.5;

Module::Build->new(
    'module_name' => q{WWW::NOS::Open},
    'license'     => q{perl},
    'dist_author' => q{Roland van Ipenburg <roland@rolandvanipenburg.com>},
    'requires'    => {
        'Date::Calc'                   => 0,
        'Date::Format'                 => 0,
        'Date::Parse'                  => 0,
        'DateTime'                     => 0,
        'Exception::Class'             => 0,
        'HTTP::Headers'                => 0,
        'HTTP::Request'                => 0,
        'HTTP::Status'                 => 0,
        'JSON'                         => 0,
        'LWP::UserAgent'               => 0,
        'Log::Log4perl'                => 0,
        'Moose'                        => 0,
        'Moose::Role'                  => 0,
        'Moose::Util::TypeConstraints' => 0,
        'MooseX::Types'                => 0,
        'MooseX::Types::Moose'         => 0,
        'Readonly'                     => 0,
        'URI'                          => 1.62,
        'URI::Escape'                  => 1.62,
        'XML::Simple'                  => 0,
        'namespace::autoclean'         => 0,
        'perl'                         => '5.14.0',
        'strict'                       => 0,
        'utf8'                         => 0,
        'warnings'                     => 0,
    },
    'configure_requires' => { 'Module::Build' => 0.40, },
    'build_requires'     => { 'Module::Build' => 0.40, },
    'test_requires'      => {
        'Perl::Critic::Bangs'        => 0,
        'Perl::Critic::Itch'         => 0,
        'Perl::Critic::More'         => 0,
        'Perl::Critic::Nits'         => 0,
        'Perl::Critic::Pulp'         => 0,
        'Perl::Critic::StricterSubs' => 0,
        'Perl::Critic::Tics'         => 0,
        'Test::CheckManifest'        => 1.01,
        'Test::Kwalitee'             => 0,
        'Test::More'                 => 0.81,
        'Test::NoWarnings'           => 0.81,
        'Test::Perl::Critic'         => 0,
        'Test::Pod'                  => 1.41,
        'Test::Pod::Coverage'        => 1.00,
        'Test::Spelling'             => 0,
        'Test::TestCoverage'         => 0.08,
    },
    'recommends' => {
        'CGI'                     => 0,
        'Dancer2'                 => 0,
        'Getopt::Long'            => 0,
        'HTTP::Status'            => 0,
        'Pod::Usage'              => 0,
        'Pod::Usage::CommandLine' => 0,
    },
    'meta_merge' => {
        'resources' => {
            'repository' =>
              q{https://bitbucket.org/rolandvanipenburg/www-nos-open},
            'bugtracker' =>
              q{https://bitbucket.org/rolandvanipenburg/www-nos-open/issues},
        },
    },
    'sign' => 1,
)->create_build_script;
