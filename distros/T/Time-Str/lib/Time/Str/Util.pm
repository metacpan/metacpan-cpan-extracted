package Time::Str::Util;
use strict;
use warnings;
use v5.10.1;

use Carp     qw[croak];
use Exporter qw[import];

BEGIN {
  our $VERSION     = '0.92';
  our @EXPORT_OK   = qw[ binary_search
                         lower_bound
                         range_bounds
                         upper_bound ];
  our %EXPORT_TAGS = ( all => \@EXPORT_OK );
  our @CARP_NOT    = qw[Time::Str::PP::Util];

  require Time::Str;
  unless (Time::Str::IMPLEMENTATION() eq 'XS') {
    require Time::Str::PP; Time::Str::PP::Util->import(@EXPORT_OK);
  }
  
  push @EXPORT_OK, qw[ find_tzdb_directory
                       find_local_timezone
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
      (?<Name>   [A-Za-z]{3,} | [<][A-Za-z0-9+-]{3,}[>] )
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

sub _tzif_from_zoneinfo_path {
  my ($path, $tzdb_directory) = @_;

  defined $tzdb_directory
    or return;

  my $pos = rindex $path, 'zoneinfo/';
  $pos >= 0
    or return;

  my $name = substr $path, $pos + length('zoneinfo/');

  valid_tzdb_timezone($name)
    or return;

  my $file = "$tzdb_directory/$name";
  -f $file
    or return;

  return Time::TZif->new(path => $file, name => $name);
}

sub find_local_timezone {
  @_ <= 1 or croak q/Usage: find_local_timezone([tzdb_directory])/;
  my ($tzdb_directory) = @_;

  $tzdb_directory //= find_tzdb_directory();

  require Time::TZif;
  require Time::TZif::POSIX;

  if (defined $ENV{TZ}) {
    my $tz = $ENV{TZ};

    # Convention on BSD/GNU: empty TZ means UTC
    unless (length $tz) {
      if (defined $tzdb_directory && -f "$tzdb_directory/UTC") {
        return Time::TZif->new(
          path => "$tzdb_directory/UTC",
          name => 'UTC',
        );
      }
      return Time::TZif::POSIX->new(
        tz_string => 'UTC0',
        name      => 'UTC',
      );
    }

    # Try as a tzdb zone name first (matches libc: file before POSIX rule)
    if (defined $tzdb_directory && valid_tzdb_timezone($tz)) {
      my $path = "$tzdb_directory/$tz";
      if (-f $path) {
        return Time::TZif->new(path => $path, name => $tz);
      }
    }

    # Try as a POSIX TZ rule
    if (valid_posix_timezone($tz)) {
      return Time::TZif::POSIX->new(tz_string => $tz);
    }

    # Collapse multiple slashes for path handling
    $tz =~ s|/{2,}|/|g;

    # Absolute or relative path containing zoneinfo/
    my $tzif = _tzif_from_zoneinfo_path($tz, $tzdb_directory);
    return $tzif if defined $tzif;

    # Remove leading colon (implementation-defined path convention)
    $tz =~ s|\A:||;

    # After colon removal, try as tzdb zone name
    if (defined $tzdb_directory && valid_tzdb_timezone($tz)) {
      my $path = "$tzdb_directory/$tz";
      if (-f $path) {
        return Time::TZif->new(path => $path, name => $tz);
      }
    }

    # Last resort: literal file path
    if (-f $tz) {
      return Time::TZif->new(path => $tz);
    }

    return undef;
  }

  # TZ not set: use /etc/localtime
  if (defined $tzdb_directory) {
    my $resolved = readlink '/etc/localtime';
    if (defined $resolved) {
      my $tzif = _tzif_from_zoneinfo_path($resolved, $tzdb_directory);
      return $tzif if defined $tzif;
    }
  }

  if (-f '/etc/localtime') {
    return Time::TZif->new(path => '/etc/localtime');
  }

  return undef;
}

1;
