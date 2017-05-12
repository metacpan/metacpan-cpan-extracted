#!/usr/bin/perl

use strict;
use ExtUtils::MakeMaker;

BEGIN {
    require 5.006_00;
}

WriteMakefile(
    NAME          => "Test::HTML::W3C",
    ABSTRACT      => "Perform W3C HTML validation testing",
    AUTHOR        => 'victor73@gmail.com',
    VERSION_FROM  => "lib/Test/HTML/W3C.pm",
    PREREQ_PM     => { 
                       "WebService::Validator::HTML::W3C" => 0.1,
                       "Test::Builder::Module" => 0,
                     },
);
