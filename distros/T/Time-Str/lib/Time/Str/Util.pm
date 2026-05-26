package Time::Str::Util;
use strict;
use warnings;
use v5.10.1;

use Carp     qw[croak];
use Exporter qw[import];

BEGIN {
  our $VERSION     = '0.87';
  our @EXPORT_OK   = qw[ lower_bound
                         range_bounds
                         upper_bound ];
  our %EXPORT_TAGS = ( all => \@EXPORT_OK );
  our @CARP_NOT    = qw[Time::Str::PP::Util];

  require Time::Str;
  unless (Time::Str::IMPLEMENTATION() eq 'XS') {
    require Time::Str::PP; Time::Str::PP::Util->import(@EXPORT_OK);
  }
  
  push @EXPORT_OK, qw[ find_tzdb_directory ];
}

{
  # Directories to probe, in order of preference.
  # Covers Linux, macOS, FreeBSD, Solaris, and Cygwin.
  my @TZDB_CANDIDATES = qw(
    /usr/share/zoneinfo
    /usr/lib/zoneinfo
    /usr/share/lib/zoneinfo
    /etc/zoneinfo
    /usr/share/zoneinfo.default
  );

  sub find_tzdb_directory {
    @_ == 0 or croak q/Usage: find_tzdb_directory()/;

    return $ENV{TZDIR} if defined $ENV{TZDIR} && -d $ENV{TZDIR};

    foreach my $dir (@TZDB_CANDIDATES) {
      return $dir if -d $dir && -f "$dir/UTC";
    }

    # macOS: /var/db/timezone/zoneinfo is a symlink to the active version
    my $macos = '/var/db/timezone/zoneinfo';
    return $macos if -d $macos && -f "$macos/UTC";

    return undef;
  }
}

1;
