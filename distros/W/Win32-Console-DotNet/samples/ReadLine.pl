# https://learn.microsoft.com/en-us/dotnet/api/system.console.readline?view=net-8.0
# This example demonstrates the System::Console->read() method.

use 5.014;
use warnings;
use Time::Piece;

use lib '../lib', 'lib';
use Win32::Console::DotNet;
use System;

sub main {
  #
  Console->Clear();

  my $dat = localtime;

  Console->Write("\nToday is %s at %s.", $dat->mdy, $dat->hms);
  Console->Write("\nPress Enter key to continue... ");
  Console->ReadLine();
  return 0;
}

exit main();

__END__

=pod

The example displays output like the following:

    Today is 10/26/2015 at 12:22:22 PM.

    Press Enter key to continue...
