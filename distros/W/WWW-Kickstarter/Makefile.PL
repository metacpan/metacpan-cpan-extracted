#!/usr/bin/env perl

use strict;
use warnings;

use ExtUtils::MakeMaker qw( WriteMakefile );

WriteMakefile(
   NAME           => 'WWW::Kickstarter',
   AUTHOR         => 'Eric Brine <ikegami@adaelis.com>',
   VERSION_FROM   => 'lib/WWW/Kickstarter.pm',
   ABSTRACT_FROM  => 'lib/WWW/Kickstarter.pm',
   dist           => { COMPRESS => 'gzip -9f', SUFFIX => '.gz' },
   clean          => { FILES => 'WWW-Kickstarter-*' },
   BUILD_REQUIRES => {},

   META_MERGE  => {
      'meta-spec' => { version => 2 },

      license => [ 'unrestricted' ],

      prereqs => {
         configure => {
            requires => {
               'ExtUtils::MakeMaker'   => 6.74,
            },
         },
         runtime => {
            requires => {
               'autovivification'      => 0,
               'Carp'                  => 0,
               'overload'              => 0,
               'Time::HiRes'           => 0,
               'URI'                   => 0,
               'URI::Escape'           => 0,
               'URI::QueryParam'       => 0,
               'version'               => 0,

               # Used by replaceable WWW::Kickstarter::HttpClient::Lwp
               'HTTP::Headers'         => 0,
               'HTTP::Request::Common' => 0,
               'LWP::Protocol::https'  => 0,
               'LWP::UserAgent'        => 0,

               # Used by replaceable WWW::Kickstarter::JsonParser::JsonXs
               'JSON::XS'              => 0,
            },
            # recommends => { },
            # suggests => { },
         },
         test => {
            requires => {
               'Test::More'            => 0,
            },
            recommends => {
               'Test::Pod'             => 1.22,
            },
         },
         develop => {
            requires => {
               'Pod::Coverage'         => 0.18,
               'Test::Pod::Coverage'   => 1.08,
            },
         },
      },

      resources => {
         homepage => 'http://search.cpan.org/dist/WWW-Kickstarter/',
         license => [ 'http://creativecommons.org/publicdomain/zero/1.0/' ],
         bugtracker => {
            web    => 'http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Kickstarter',
            mailto => 'bug-WWW-Kickstarter@rt.cpan.org',
         },
         repository => {
            type => 'git',
            url  => 'https://github.com/ikegami/perl-WWW-Kickstarter.git',
            web  => 'https://github.com/ikegami/perl-WWW-Kickstarter',
         },
      },
   },
);
