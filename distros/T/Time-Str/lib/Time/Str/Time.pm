package Time::Str::Time;
use strict;
use warnings;
use v5.10.1;

use Exporter qw[import];

BEGIN {
  our $VERSION     = '0.92';
  our @EXPORT_OK   = qw[ gmtime_modern
                         gmtime_year
                         timegm_posix
                         timegm_modern
                         valid_hms
                         valid_hms60 ];
  our %EXPORT_TAGS = ( all => \@EXPORT_OK );
  our @CARP_NOT    = qw[Time::Str::PP::Time];

  require Time::Str;
  unless (Time::Str::IMPLEMENTATION() eq 'XS') {
    require Time::Str::PP; Time::Str::PP::Time->import(@EXPORT_OK);
  }
}

1;
