#!/usr/bin/perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'WebService::VigLink',
    VERSION_FROM => 'lib/WebService/VigLink.pm',
    PREREQ_PM =>
      { 'Any::URI::Escape' => 0.01, },
    ABSTRACT_FROM => 'lib/WebService/VigLink.pm',
    AUTHOR        => 'Fred Moyer <fred@slwifi.com>',
);
