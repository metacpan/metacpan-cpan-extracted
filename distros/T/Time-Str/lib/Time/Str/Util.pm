package Time::Str::Util;
use strict;
use warnings;
use v5.10.1;

use Carp     qw[croak];
use Exporter qw[import];

BEGIN {
  our $VERSION     = '0.88';
  our @EXPORT_OK   = qw[ lower_bound
                         range_bounds
                         upper_bound ];
  our %EXPORT_TAGS = ( all => \@EXPORT_OK );
  our @CARP_NOT    = qw[Time::Str::PP::Util];

  require Time::Str;
  unless (Time::Str::IMPLEMENTATION() eq 'XS') {
    require Time::Str::PP; Time::Str::PP::Util->import(@EXPORT_OK);
  }
  
  push @EXPORT_OK, qw[ find_tzdb_directory 
                       valid_tzdb_timezone
                       valid_posix_timezone ];
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

{
  my $ValidName_Rx = qr{
    (?(DEFINE)
      (?<NameInitial> [A-Za-z])
      (?<NameChar>    [A-Za-z0-9])
      (?<NamePart>    (?&NameInitial) (?&NameChar)* (?: [_+-] (?&NameChar)+ )* )
      (?<Name>        (?&NamePart) (?: [/] (?&NamePart) )* )
    )
    \A (?&Name) \z
  }x;

  sub valid_tzdb_timezone {
    @_ == 1 or croak q/Usage: valid_tzdb_timezone(string)/;
    my ($string) = @_;
    return (defined $string && $string =~ $ValidName_Rx);
  }
}

{
  my $ValidPOSIX_Rx = qr{
    (?(DEFINE)
      (?<Name>   [A-Za-z]{3,} )
      (?<Offset> [+-]? [0-9]{1,2} (?: [:][0-9]{2} (?: [:][0-9]{2} )? )? )
      (?<Time>   [+-]? [0-9]{1,3} (?: [:][0-9]{2} (?: [:][0-9]{2} )? )? )
      (?<Rule>   M [0-9]{1,2} [.] [0-9] [.] [0-9]
               | J [0-9]{1,3}
               |   [0-9]{1,3} )
    )

    \A
          (?&Name)         (?&Offset)
    (?:
          (?&Name) (?:     (?&Offset) )?
      [,] (?&Rule) (?: [/] (?&Time)   )?
      [,] (?&Rule) (?: [/] (?&Time)   )?
    )?
    \z
  }x;

  sub valid_posix_timezone {
    @_ == 1 or croak q/Usage: valid_posix_timezone(string)/;
    my ($string) = @_;
    return (defined $string && $string =~ $ValidPOSIX_Rx);
  }
}

1;
