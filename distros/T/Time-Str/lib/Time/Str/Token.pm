package Time::Str::Token;
use strict;
use warnings;
use v5.10.1;

use Exporter qw[import];

BEGIN {
  our $VERSION     = '0.87';
  our @EXPORT_OK   = qw[ parse_day
                         parse_day_name
                         parse_month
                         parse_meridiem
                         parse_tz_offset ];
  our %EXPORT_TAGS = ( all => \@EXPORT_OK );
  our @CARP_NOT    = qw[Time::Str::PP::Token];

  require Time::Str;
  unless (Time::Str::IMPLEMENTATION() eq 'XS') {
    require Time::Str::PP; Time::Str::PP::Token->import(@EXPORT_OK);
  }
}

1;
