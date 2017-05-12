#!/usr/bin/env perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME           => 'WWW::Mailgun',
  VERSION_FROM   => 'lib/WWW/Mailgun.pm',
  PREREQ_PM      => {
    'Digest::SHA1'         => 0,
    'JSON'                 => 0,
    'LWP::Protocol::https' => 0,
    'LWP::UserAgent'       => 0,
    'match::simple'        => 0,
    'MIME::Base64'         => 0,
  },
  BUILD_REQUIRES => {
    'Test::Differences' => 0,
    'Test::MockModule'  => 0,
  },
  AUTHOR         => 'George Tsafas <elb0w@elbowrage.com>'
);
