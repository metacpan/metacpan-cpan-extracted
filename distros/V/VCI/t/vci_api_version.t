#!/usr/bin/perl
use strict;
use warnings;
use lib 't/lib';
use Test::Exception tests => 5;
use Test::Warn;
use VCI;

throws_ok { VCI->connect(type => 'MajorVersionTooHigh', repo => '') }
          qr/This driver implements VCI/, "Major Version Too High";
throws_ok { VCI->connect(type => 'APIVersionTooHigh', repo => '') }
          qr/This driver implements VCI/, "API Version Too High";
throws_ok { VCI->connect(type => 'MajorVersionTooLow', repo => '') }
          qr/VCI has a major version of/, "Major Version Too Low";
lives_ok { VCI->connect(type => 'VersionJustRight', repo => '') }
         'Version Just Right';
warning_like {VCI->connect(type => 'APIVersionTooLow', repo => '', debug => 1)}
             qr/only implements VCI/, "API Version Too Low";