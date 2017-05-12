#!/usr/bin/env perl

use strict;
use warnings;
use constant TESTS   => 4;
use Test::More tests => TESTS;

BEGIN { use_ok('WWW::Wordnik::API'); }
require_ok('WWW::Wordnik::API');

my $wn = Test::More::new_ok('WWW::Wordnik::API');

{
    my $VAR1;
    eval join q{}, <DATA>;

    # need to delete code refs, since is_deeply only checks referents
    # also delete _json, which value depends on JSON being installed
    delete @{$VAR1}{qw/_user_agent _json/};
    delete @{$wn}{qw/_user_agent _json/};

    is_deeply( $wn, $VAR1, 'Object creation' );
}

done_testing(TESTS);

__DATA__
$VAR1 = bless( {
                 '_formats' => {
                                 'perl' => 1,
                                 'xml' => 1,
                                 'json' => 1
                               },
                 '_cache' => {
                               'data'     => [],
                               'requests' => {},
                               'max' => 10
                             },
                 'server_uri' => 'http://api.wordnik.com/v4',
                 '_json' => 'available',
                 'version' => 4,
                 '_versions' => {
                                  '1' => 0,
                                  '3' => 1,
                                  '4' => 1,
                                  '2' => 0
                                },
                 'api_key' => 'YOUR KEY HERE',
                 '_user_agent' => bless( {
                                           'max_redirect' => 7,
                                           'protocols_forbidden' => undef,
                                           'show_progress' => undef,
                                           'handlers' => {
                                                           'response_header' => bless( [
                                                                                         {
                                                                                           'owner' => 'LWP::UserAgent::parse_head',
                                                                                           'callback' => sub { "DUMMY" },
                                                                                           'm_media_type' => 'html',
                                                                                           'line' => '/usr/share/perl5/LWP/UserAgent.pm:612'
                                                                                         }
                                                                                       ], 'HTTP::Config' )
                                                         },
                                           'no_proxy' => [],
                                           'protocols_allowed' => undef,
                                           'local_address' => undef,
                                           'use_eval' => 1,
                                           'requests_redirectable' => [
                                                                        'GET',
                                                                        'HEAD'
                                                                      ],
                                           'timeout' => 180,
                                           'def_headers' => bless( {
                                                                     'user-agent' => 'Perl-WWW::Wordnik::API/0.0.1',
                                                                     ':api_key' => 'YOUR KEY HERE'
                                                                   }, 'HTTP::Headers' ),
                                           'proxy' => {},
                                           'max_size' => undef
                                         }, 'LWP::UserAgent' ),
                 'debug' => 0,
                 'format' => 'json',
                 'cache' => 10
               }, 'WWW::Wordnik::API' );
