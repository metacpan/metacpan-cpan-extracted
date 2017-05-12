#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'Test::XHTML',
    VERSION_FROM	    => 'lib/Test/XHTML.pm',
    ABSTRACT            => 'Test web page code validation',
    NO_META             => 1,
    PREREQ_PM => {

        # used in modules
        'Class::Accessor::Fast' => '0',
        'Data::Dumper'          => '0',
        'File::Basename'        => '0',
        'File::Find::Rule'      => '0',
        'File::Path'            => '0',
        'HTML::TokeParser'      => '3.69',
        'IO::File'              => '0',
        'Test::Builder'         => '0',
        'WWW::Mechanize'        => '0',
        'XML::Catalogs::HTML'   => '0',
        'XML::LibXML'           => '1.70',

        # used in scripts
        'Getopt::Long'          => '0', # xhtml-valid script only

        # used in testing
        'Test::Builder::Tester' => '0',
        'Test::More'            => '0.70',

    },

    'EXE_FILES'         => ['bin/xhtml-valid'],
);
