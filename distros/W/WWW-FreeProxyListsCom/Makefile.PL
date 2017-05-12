#!/usr/bin/perl
use warnings;
use strict;

require 5.006;
use ExtUtils::MakeMaker;
WriteMakefile
(
    'NAME' => 'WWW::FreeProxyListsCom',
    'VERSION_FROM' => 'lib/WWW/FreeProxyListsCom.pm',
    'META_MERGE' => {
    'meta-spec' => { version => 2 },
        resources => {
            bugtracker => {
                web => 'https://github.com/stevieb9/p5-www-freeproxylistscom/issues',
            },
            repository => {
                type => 'git',
                url => 'https://github.com/stevieb9/p5-www-freeproxylistscom.git',
                web => 'https://github.com/stevieb9/p5-www-freeproxylistscom',
            },
        },
    },
    'PREREQ_PM' => {
               'Carp' => '1.04',
               'Class::Accessor::Grouped' => 0,
               'Devel::TakeHashArgs' => '0.001',
               'HTML::Entities' => '1.35',
               'HTML::TokeParser::Simple' => '3.15',
               'Test::More' => 0,
               'URI' => '1.35',
               'WWW::Mechanize' => '1.34'
             },
    'INSTALLDIRS' => 'site',
    'EXE_FILES' => [],
    'PL_FILES' => {}
);
