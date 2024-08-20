# https://learn.microsoft.com/en-us/dotnet/api/system.console.openstandardinput?view=net-9.0
# The following example illustrates the use of the OpenStandardInput method.
# Note: C# StreamReader.Read(buffer, index, count) is not very 'Perlish', 
#       that's why we use IO::Handle->getline().

use 5.014;
use warnings;
use Encode;

use lib '../lib', 'lib';
use Win32::Console::DotNet;
use System;

sub main {
  my $inputStream = Console->OpenStandardInput();
  my $bytes = "\0" x 100;
  Console->WriteLine("To decode, type or paste the UTF7 encoded string and " .
    "press enter:");
  Console->WriteLine("(Example: \"M+APw-nchen ist wundervoll\")");
  my $outputLength = do {
    use bytes;
    my $limit = length($bytes);
    my $line = $inputStream->getline();
    chomp($line);
    $bytes = substr($line, 0, $limit);
    length($bytes);
  };
  my $chars = Encode::decode('UTF-7' => $bytes);
  Console->WriteLine("Decoded string:");
  Console->WriteLine($chars);
  return 0;
}

exit main();
