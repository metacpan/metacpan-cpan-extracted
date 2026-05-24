package Util;
use strict;
use warnings;

use Test::Fatal qw[exception];

BEGIN {
  our @EXPORT_OK  = qw[find_tzdir throws_ok warns_ok];
  our %EXPORT_TAGS = (
      all => [ @EXPORT_OK ],
  );

  require Exporter;
  *import = \&Exporter::import;
}

my $Tester;
sub throws_ok (&$;$) {
  my ($code, $regexp, $name) = @_;

  require Test::Builder;
  $Tester ||= Test::Builder->new;

  my $e  = exception(\&$code);
  my $ok = ($e && $e =~ m/$regexp/);

  $Tester->ok($ok, $name);

  unless ($ok) {
    if ($e) {
      $Tester->diag("expecting: " . $regexp);
      $Tester->diag("found: " . $e);
    }
    else {
      $Tester->diag("expected an exception but none was raised");
    }
  }
}

sub warns_ok (&$;$) {
  my ($code, $regexp, $name) = @_;

  require Test::Builder;
  $Tester ||= Test::Builder->new;

  my @warnings = ();
  local $SIG{__WARN__} = sub { push @warnings, @_ };

  my $e  = exception(\&$code);
  my $ok = (!$e && @warnings == 1 && $warnings[0] =~ m/$regexp/);

  $Tester->ok($ok, $name);

  unless ($ok) {
    if ($e) {
      $Tester->diag("expected a warning but an exception was raised");
      $Tester->diag("exception: " . $e);
    }
    elsif (@warnings == 0) {
      $Tester->diag("expected a warning but none were issued");
    }
    elsif (@warnings >= 2) {
      $Tester->diag("expected a warning but several were issued");
      $Tester->diag("warnings: " . join '', @warnings);
    }
    else {
      $Tester->diag("expecting: " . $regexp);
      $Tester->diag("found: " . $warnings[0]);
    }
  }
}

{
  # Directories to probe, in order of preference.
  # Covers Linux, macOS, FreeBSD, Solaris, and Cygwin.
  my @TZDIR_CANDIDATES = qw(
    /usr/share/zoneinfo
    /usr/lib/zoneinfo
    /usr/share/lib/zoneinfo
    /etc/zoneinfo
    /usr/share/zoneinfo.default
  );

  sub find_tzdir {
    # Honour explicit override
    return $ENV{TZDIR} if defined $ENV{TZDIR} && -d $ENV{TZDIR};

    for my $dir (@TZDIR_CANDIDATES) {
      return $dir if -d $dir && -f "$dir/UTC";
    }

    # macOS: /var/db/timezone/zoneinfo is a symlink to the active version
    my $macos = '/var/db/timezone/zoneinfo';
    return $macos if -d $macos && -f "$macos/UTC";

    return undef;
  }
}

1;
