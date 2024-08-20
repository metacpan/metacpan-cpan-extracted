# https://learn.microsoft.com/en-us/dotnet/api/system.console.title?view=net-8.0
# This example demonstrates the System::Console->Title property.

use 5.014;
use warnings;

use lib '../lib', 'lib';
use Win32::Console::DotNet;
use System;

sub main {
  Console->WriteLine("The current console title is: \"%s\"",
    Console->Title);
  Console->WriteLine("\t(Press any key to change the console title.)");
  Console->ReadKey(1);
  Console->Title( "The title has changed!" );
  Console->WriteLine("Note that the new console title is \"%s\"\n" .
    "\t(Press any key to quit.)", Console->Title);
  Console->ReadKey(1);
  return 0;
}

exit main();

__END__

=pod

This example produces the following results:

  The current console title is: "Command Prompt - perl  samples\Title.pl"
      (Press any key to change the console title.)
  Note that the new console title is "The title has changed!"
      (Press any key to quit.)
