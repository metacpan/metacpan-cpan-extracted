package Time::Str::Calendar;
use strict;
use warnings;
use v5.10.1;

use Exporter qw[import];

BEGIN {
  our $VERSION     = '0.88';
  our @EXPORT_OK   = qw[ leap_year
                         month_days
                         nth_dow_in_month
                         valid_ymd
                         yd_to_md
                         ymd_to_doy
                         ymd_to_dow
                         ymd_to_rdn
                         rdn_to_ymd
                         rdn_to_dow
                         resolve_century ];
  our %EXPORT_TAGS = ( all => \@EXPORT_OK );
  our @CARP_NOT    = qw[Time::Str::PP::Calendar];

  require Time::Str;
  unless (Time::Str::IMPLEMENTATION() eq 'XS') {
    require Time::Str::PP; Time::Str::PP::Calendar->import(@EXPORT_OK);
  }
}

1;
