#!/usr/bin/perl -T

# t/03core.t
#  Tests core functionality
#
# $Id: 03core.t 8620 2009-08-18 04:36:27Z FREQUENCY@cpan.org $

use strict;
use warnings;

use Test::More tests => 8;
use Test::NoWarnings; # 1 test

use Video::FourCC::Info;

# Normal operation
{
  my $codec = Video::FourCC::Info->new('DIV3');
  isa_ok($codec, 'Video::FourCC::Info');

  is($codec->code, 'DIV3', 'FourCC code is DIV3');
  is($codec->description, 'DivX 3 Low-Motion', 'DivX 3 Low Motion Codec');
  is($codec->owner, 'DivX');
}

# Static usage of module
{
  my $fourcc = Video::FourCC::Info->describe('DIV3');
  is($fourcc, 'DivX 3 Low-Motion', 'Use of class method describe');

  $fourcc = Video::FourCC::Info->describe('div3');
  is($fourcc, 'DivX 3 Low-Motion', 'Lowercase use of describe');
}

# Check that the date parsed is appropriate
{
  my $codec = Video::FourCC::Info->new('CC12');

  eval { require DateTime };

  # If there is no DateTime, then the registered date will be a simple
  # string; otherwise, we have to stringify DateTime
  is($@ ? $codec->registered : $codec->registered->ymd('-'), '1996-06-12',
    'Intel YUV12 codec register date');
}

# Test that nothing bad happens when there is missing info
# If nothing happens, then we're successful; otherwise it's likely there
# will be a warning, which is caught by Test::NoWarnings
{
  Video::FourCC::Info->new('ACTL'); # No date or owner known
}
