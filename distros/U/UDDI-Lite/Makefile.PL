#!/usr/bin/perl

use strict;
use warnings;

use ExtUtils::MakeMaker;
WriteMakefile(
    NAME          => 'UDDI::Lite',
    VERSION_FROM  => 'lib/UDDI/Lite.pm',
    PREREQ_PM     => { 'SOAP::Lite' => 0.716 },
    ABSTRACT_FROM => 'lib/UDDI/Lite.pm',
    AUTHOR        => 'Paul Kulchenko (paulclinger@yahoo.com)',
);
