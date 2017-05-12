#!/usr/bin/perl -w

use strict;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'XML::LibXSLT::Easy',
    VERSION_FROM => 'lib/XML/LibXSLT/Easy.pm',
    INSTALLDIRS  => 'site',
    SIGN         => 1,
    PL_FILES     => { },
    PREREQ_PM    => {
        'Moose' => '0.50',

        # for the actual processing
        'XML::LibXML' => 0,
        'XML::LibXSLT' => 0,

        # for various argument types
        'URI' => 0,
        'Path::Class' => 0,
        'MooseX::MultiMethods' => 0,

        # types used in the multi dispatch
        'MooseX::Types' => 0,
        'MooseX::Types::URI' => 0,
        'MooseX::Types::Path::Class' => 0,
        'MooseX::Types::Moose' => 0,

        # loading of Batch conf files, and finding the files from the config
        'Config::Any' => 0,
        'File::Glob' => 0,

        # misc stuff
        'namespace::clean' => '0.08',
        'Devel::PartialDump' => 0,
        'Scope::Guard' => 0,

        'Test::More' => 0,
        'Test::Exception' => 0,
        'Test::XML' => 0,
        'Test::use::ok' => 0,
    },
);

