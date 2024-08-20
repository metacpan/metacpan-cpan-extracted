# https://learn.microsoft.com/en-us/dotnet/api/system.console.readkey?view=net-8.0
# The following example uses the ReadKey() method to wait for the user to 
# press the Enter key before terminating the app.

use 5.014;
use warnings;
use DateTime;
use Time::Piece;

use lib '../lib', 'lib';
use Win32::Console::DotNet;
use System;

sub main {
  my $dat = localtime;
  Console->WriteLine("The time: %s at %s", $dat->dmy, $dat->hms);
  my $tz = DateTime::TimeZone->new(name => 'local');
  Console->WriteLine("The time zone: %s\n", 
    $dat->isdst() ? $tz->name() . $dat->strftime(" (%Z)")
                  : $tz->name
  );
  Console->Write("Press <Enter> to exit... ");
  while ( Console->ReadKey(1)->Key != ConsoleKey->Enter ) {}
  return 0;
}

exit main();

__END__

=pod

The example displays output like the following:

  The time: 11/11/2015 at 4:02 PM:
  The time zone: Pacific Standard Time
