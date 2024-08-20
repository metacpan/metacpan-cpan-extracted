# https://learn.microsoft.com/en-us/dotnet/api/system.console.writeline?view=net-8.0
# https://learn.microsoft.com/en-us/dotnet/api/system.console.write?view=net-8.0
# This example demonstrates the System::Console->WriteLine() method.

use 5.014;
use warnings;
use Time::Piece;

use lib '../lib', 'lib';
use Win32::Console::DotNet;
use System;

sub curf($) {
  if ( eval { require CLDR::Number } ) {
    my $cldr = CLDR::Number->new(locale => 'en');
    my $curf = $cldr->currency_formatter(currency_code => 'USD');
    return $curf->format($_[0]);
  } else {
    return sprintf('$%.2f', abs($_[0]));
  }
}

sub perf($) {
  if ( eval { require CLDR::Number } ) {
    my $cldr = CLDR::Number->new(locale => 'en');
    my $perf = $cldr->percent_formatter;
    $perf->minimum_fraction_digits(2);
    return $perf->format($_[0]);
  } else {
    return sprintf('%.2f %%', $_[0]*100);
  }
}

sub rfc1123($) {
  if ( eval { require HTTP::Date } ) {
    return HTTP::Date::time2str($_[0]->epoch);
  } else {
    my $gmt = $_[0] - $_[0]->tzoffset;
    return sprintf('%s, %02d %s %d %s GMT',
      $gmt->day(localtime->day_list),
      $gmt->mday,
      $gmt->month(localtime->mon_list),
      $gmt->year,
      $gmt->hms,
    );
  }
}

sub universal($) {
  if ( eval { require HTTP::Date } ) {
    return HTTP::Date::time2isoz($_[0]->epoch);
  } else {
    my $gmt = $_[0] - $_[0]->tzoffset;
    return $gmt->strftime("%Y-%M-%d %H:%M:%SZ");
  }
}

sub universal_full($) {
  my $gmt = $_[0] - $_[0]->tzoffset;
  return sprintf('%s %s', $gmt->strftime("%A, %B %d, %Y"), $gmt->hms);
}

my $thisDate = localtime;

sub main {
  Console->Clear();

  # Format a negative integer or floating-point number in various ways.
  Console->WriteLine("Standard Numeric Format Specifiers");
  Console->WriteLine(
    "(C) Currency: . . . . . . . . (%3\$s)\n".
    "(D) Decimal:. . . . . . . . . %1\$d\n".
    "(E) Scientific: . . . . . . . %2\$.6E\n".
    "(F) Fixed point:. . . . . . . %2\$.2f\n".
    "(G) General:. . . . . . . . . %1\$d\n".
    "    (default):. . . . . . . . %1\$d (default = '%%d')\n".
    "(N) Number: . . . . . . . . . %1\$.2f\n".
    "(P) Percent:. . . . . . . . . %4\$s\n".
    "(R) Round-trip: . . . . . . . %2\$.2f\n".
    "(X) Hexadecimal:. . . . . . . %1\$lX\n",
    -123, -123.45, curf(123), perf(-123.45),
  );

  # Format the current date in various ways.
  Console->WriteLine("Standard Format Specifiers");
  Console->WriteLine(
    "(d) Short date: . . . . . . . %s\n".
    "(D) Long date:. . . . . . . . %s\n".
    "(t) Short time: . . . . . . . %s\n".
    "(T) Long time:. . . . . . . . %s\n".
    "(f) Full date/short time: . . %s\n".
    "(F) Full date/long time:. . . %s\n".
    "(g) General date/short time:. %s\n".
    "(G) General date/long time: . %s\n".
    "    (default):. . . . . . . . %s (default = '%%s')\n".
    "(M) Month:. . . . . . . . . . %s\n".
    "(R) RFC1123:. . . . . . . . . %s\n".
    "(s) Sortable: . . . . . . . . %s\n".
    "(u) Universal sortable: . . . %s (invariant)\n".
    "(U) Universal full date/time: %s\n".
    "(Y) Year: . . . . . . . . . . %s\n",
    $thisDate->dmy,
    $thisDate->strftime("%A, %B %d, %Y"),
    $thisDate->strftime("%H:%M"),
    $thisDate->hms,
    $thisDate->strftime("%A, %B %d, %Y %H:%M"),
    $thisDate->strftime("%A, %B %d, %Y %H:%M:%S"),
    $thisDate->strftime("%d.%m.%Y %H:%M"),
    $thisDate->strftime("%d.%m.%Y %H:%M:%S"),
    $thisDate,
    $thisDate->strftime("%B %d"),
    rfc1123($thisDate),
    $thisDate->datetime,
    universal($thisDate),
    universal_full($thisDate),
    $thisDate->strftime("%B, %Y"),
  );

  # Format a Color enumeration value in various ways.
  Console->WriteLine("Standard Enumeration Format Specifiers");
  Console->WriteLine(
    "(G) General:. . . . . . . . . %2\$s\n".
    "    (default):. . . . . . . . %1\$d (default = '%%d')\n".
    "(F) Flags:. . . . . . . . . . %1\$d (flags or integer)\n".
    "(D) Decimal number: . . . . . %1\$d\n".
    "(X) Hexadecimal:. . . . . . . %1\$08X\n",
    ConsoleColor->Green, ConsoleColor->get(ConsoleColor->Green)
  );
  return 0;
}

exit main();

__END__

=pod

This code example produces the following results:

  Standard Numeric Format Specifiers
  (C) Currency: . . . . . . . . ($123.00)
  (D) Decimal:. . . . . . . . . -123
  (E) Scientific: . . . . . . . -1.234500E+002
  (F) Fixed point:. . . . . . . -123.45
  (G) General:. . . . . . . . . -123
      (default):. . . . . . . . -123 (default = 'G')
  (N) Number: . . . . . . . . . -123.00
  (P) Percent:. . . . . . . . . -12,345.00 %
  (R) Round-trip: . . . . . . . -123.45
  (X) Hexadecimal:. . . . . . . FFFFFF85

  Standard DateTime Format Specifiers
  (d) Short date: . . . . . . . 6/26/2004
  (D) Long date:. . . . . . . . Saturday, June 26, 2004
  (t) Short time: . . . . . . . 8:11 PM
  (T) Long time:. . . . . . . . 8:11:04 PM
  (f) Full date/short time: . . Saturday, June 26, 2004 8:11 PM
  (F) Full date/long time:. . . Saturday, June 26, 2004 8:11:04 PM
  (g) General date/short time:. 6/26/2004 8:11 PM
  (G) General date/long time: . 6/26/2004 8:11:04 PM
      (default):. . . . . . . . 6/26/2004 8:11:04 PM (default = 'G')
  (M) Month:. . . . . . . . . . June 26
  (R) RFC1123:. . . . . . . . . Sat, 26 Jun 2004 20:11:04 GMT
  (s) Sortable: . . . . . . . . 2004-06-26T20:11:04
  (u) Universal sortable: . . . 2004-06-26 20:11:04Z (invariant)
  (U) Universal full date/time: Sunday, June 27, 2004 3:11:04 AM
  (Y) Year: . . . . . . . . . . June, 2004

  Standard Enumeration Format Specifiers
  (G) General:. . . . . . . . . Green
      (default):. . . . . . . . Green (default = 'G')
  (F) Flags:. . . . . . . . . . Green (flags or integer)
  (D) Decimal number: . . . . . 3
  (X) Hexadecimal:. . . . . . . 00000003
