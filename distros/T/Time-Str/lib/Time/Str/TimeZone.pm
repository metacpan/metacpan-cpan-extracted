package Time::Str::TimeZone;
use strict;
use warnings;
use v5.10.1;

use Carp              qw[croak];
use Exporter          qw[import];
use Time::Str::Util   qw[find_local_timezone
                         find_tzdb_directory
                         valid_tzdb_timezone];
use Time::TZif        qw[];

BEGIN {
  our $VERSION   = '0.91';
  our @EXPORT_OK = qw[timezone];
}

our $PROVIDER = __PACKAGE__;

my $Initialized;
my $ZoneDirectory;
my %Zone;

sub locate {
  @_ == 2 or croak q/Usage: Time::Str::TimeZone->locate(timezone)/;
  my ($class, $timezone) = @_;

  unless (exists $Zone{$timezone}) {
    valid_tzdb_timezone($timezone)
      or croak q/Parameter 'timezone' is not a valid IANA Time Zone Database timezone name/;

    unless ($Initialized) {
      $ZoneDirectory = find_tzdb_directory();
      (defined $ZoneDirectory && -f "$ZoneDirectory/UTC")
        or croak q/Unable to locate IANA Time Zone Database directory; Set TZDIR environment variable/;
      $Initialized = 1;
    }

    if ($timezone eq 'local') {
      my $local = find_local_timezone($ZoneDirectory);
      (defined $local)
        or croak q/Unable to determine system timezone; Set TZ environment variable/;
      $Zone{$timezone} = $local;
    }
    else {
      my $path = "$ZoneDirectory/$timezone";
      (-f $path)
        or croak qq/Unable to locate IANA Time Zone: '$timezone'/;
      $Zone{$timezone} = Time::TZif->new(path => $path, name => $timezone);
    }
  }

  return $Zone{$timezone};
}

sub flush {
  @_ == 1 or croak q/Usage: Time::Str::TimeZone->flush()/;
  %Zone = ();
  $Initialized = 0;
}

sub reset : method {
  @_ == 1 or croak q/Usage: Time::Str::TimeZone->reset()/;
  return $PROVIDER->flush();
}

sub timezone {
  @_ == 1 or croak q/Usage: timezone(timezone)/;
  my ($timezone) = @_;
  return $PROVIDER->locate($timezone);
}

1;
