#!perl
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => "WWW::Search::Google",
    VERSION_FROM => 'Google.pm',
    PREREQ_PM    => {},
    AUTHOR       => 'Leon Brocard <acme@astray.com>',
    ABSTRACT     => 'WWW::Search::Google searches Google via SOAP'
);
