#!/usr/bin/perl -w                                         # -*- perl -*-

use strict;

use ExtUtils::MakeMaker;
    
my %opts = (
    'NAME'         => 'XML::Namespace',
    'VERSION_FROM' => 'lib/XML/Namespace.pm',
    'PMLIBDIRS'    => [ 'lib' ], 
);

if ($ExtUtils::MakeMaker::VERSION >= 5.43) {
    $opts{ AUTHOR   } = 'Andy Wardley <abw@cpan.org>';
    $opts{ ABSTRACT } = 'Simple support for XML Namespaces',
}

WriteMakefile( %opts );

