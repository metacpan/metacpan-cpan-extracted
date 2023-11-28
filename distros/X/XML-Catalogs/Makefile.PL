#!perl

use strict;
use warnings;

use ExtUtils::MakeMaker qw( WriteMakefile );

WriteMakefile(
   NAME           => 'XML::Catalogs',
   AUTHOR         => 'Eric Brine <ikegami@adaelis.com>',
   VERSION_FROM   => 'lib/XML/Catalogs.pm',
   ABSTRACT_FROM  => 'lib/XML/Catalogs.pm',
   dist           => { COMPRESS => 'gzip -9f', SUFFIX => '.gz' },
   clean          => { FILES => 'XML-Catalogs-*' },
   BUILD_REQUIRES => {},

   META_MERGE  => {
      'meta-spec' => { version => 2 },

      license => [ 'unrestricted' ],

      prereqs => {
         configure => {
            requires => {
               'ExtUtils::MakeMaker' => 6.52,
            },
         },
         runtime => {
            requires => {
               'Carp'           => 0,
               'File::ShareDir' => 0,
               'strict'         => 0,
               'URI::file'      => 0,
               'version'        => 0,
               'warnings'       => 0,
            },
            # recommends => { },
            # suggests => { },
         },
         test => {
            requires => {
               'Test::More'          => 0,
            },
            recommends => {
               'Test::Pod'           => 1.22,
            },
         },
         develop => {
            requires => {
               'Pod::Coverage'       => 0.18,
               'Test::Pod::Coverage' => 1.08,
            },
         },
      },

      resources => {
         homepage => 'http://search.cpan.org/dist/XML-Catalogs/',
         license => [ 'http://creativecommons.org/publicdomain/zero/1.0/' ],
         bugtracker => {
            web    => 'https://github.com/ikegami/perl-XML-Catalogs/issues',
         },
         repository => {
            type => 'git',
            url  => 'https://github.com/ikegami/perl-XML-Catalogs.git',
            web  => 'https://github.com/ikegami/perl-XML-Catalogs',
         },
      },
   },
);
