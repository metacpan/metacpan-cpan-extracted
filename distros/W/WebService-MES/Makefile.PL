#!/usr/bin/perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'WebService::MES',
    VERSION_FROM  => 'lib/WebService/MES.pm',
    PREREQ_PM     => { 'Moo' => 0, 'URI' => 0, 'LWP::UserAgent' => 0 },
    ABSTRACT_FROM => 'lib/WebService/MES.pm',
    AUTHOR        => 'Fred Moyer <fred@redhotpenguin.com>'
);
