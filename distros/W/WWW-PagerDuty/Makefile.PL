#!/usr/bin/env perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'WWW::PagerDuty',
  VERSION_FROM => 'lib/WWW/PagerDuty.pm',
  PREREQ_PM    => {'JSON' => 0, 'LWP::UserAgent' => 0},
  AUTHOR       => 'Robert Novak <robertn@ccbill.com>'
);
