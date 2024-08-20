# https://learn.microsoft.com/en-us/dotnet/api/system.console.bufferheight?view=net-8.0
# https://learn.microsoft.com/en-us/dotnet/api/system.console.bufferwidth?view=net-8.0
# This example demonstrates the Console->BufferHeight and
#                               Console->BufferWidth properties.

use 5.014;
use warnings;

use lib '../lib', 'lib';
use Win32::Console::DotNet;
use System;

sub main {
  Console->WriteLine("The current buffer height is %d rows.",
                      Console->BufferHeight);
  Console->WriteLine("The current buffer width is %d columns.",
                      Console->BufferWidth);
  return 0;
}

exit main();

__END__

=pod

This example produces the following results:

  The current buffer height is 300 rows.
  The current buffer width is 85 columns.
