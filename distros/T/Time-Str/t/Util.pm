package Util;
use strict;
use warnings;

use IO::File    qw[SEEK_SET];
use Test::Fatal qw[exception];

BEGIN {
  our @EXPORT_OK  = qw[ throws_ok warns_ok tmpfile rewind ];
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

sub rewind(*) {
  seek($_[0], 0, SEEK_SET)
    or die qq/Couldn't rewind file handle: '$!'/;
}

sub tmpfile {
  my $fh = IO::File->new_tmpfile
    or die qq/Couldn't create a new temporary file: '$!'/;

  binmode($fh)
    or die qq/Couldn't binmode temporary file handle: '$!'/;

  if (@_) {
    print({$fh} @_)
      or die qq/Couldn't write to temporary file handle: '$!'/;

    seek($fh, 0, SEEK_SET)
      or die qq/Couldn't rewind temporary file handle: '$!'/;
  }

  return $fh;
}

1;
