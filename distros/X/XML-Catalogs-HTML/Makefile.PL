#!perl

use strict;
use warnings;

use ExtUtils::MakeMaker qw( WriteMakefile );

WriteMakefile(
   NAME           => 'XML::Catalogs::HTML',
   AUTHOR         => 'Eric Brine <ikegami@adaelis.com>',
   VERSION_FROM   => 'lib/XML/Catalogs/HTML.pm',
   ABSTRACT_FROM  => 'lib/XML/Catalogs/HTML.pm',
   dist           => { COMPRESS => 'gzip -9f', SUFFIX => '.gz' },
   clean          => { FILES => 'XML-Catalogs-HTML-*' },
   BUILD_REQUIRES => {},

   META_MERGE  => {
      'meta-spec' => { version => 2 },

      license => [ 'open_source' ],  # A mix of CC0_1_0 and W3C Document License

      prereqs => {
         configure => {
            requires => {
               'ExtUtils::MakeMaker' => 6.52,
            },
         },
         runtime => {
            requires => {
               'parent'              => 0,
               'strict'              => 0,
               'XML::Catalogs'       => 0,
               'version'             => 0,
               'warnings'            => 0,
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
         homepage => 'http://search.cpan.org/dist/XML-Catalogs-HTML/',
         #license => [ 'http://creativecommons.org/publicdomain/zero/1.0/' ],   # Except for .dtd and .ent files.
         bugtracker => {
            web    => 'https://github.com/ikegami/perl-XML-Catalogs-HTML/issues',
         },
         repository => {
            type => 'git',
            url  => 'https://github.com/ikegami/perl-XML-Catalogs-HTML.git',
            web  => 'https://github.com/ikegami/perl-XML-Catalogs-HTML',
         },
      },
   },
);
