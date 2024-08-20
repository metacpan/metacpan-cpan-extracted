# https://learn.microsoft.com/en-us/dotnet/api/system.console.read?view=net-8.0
# This example demonstrates the System::Console->Read() method.

use 5.014;
use warnings;

use lib '../lib', 'lib';
use Win32::Console::DotNet;
use System;

sub main {
  my $m1 = "\nType a string of text then press Enter. " .
           "Type '+' anywhere in the text to quit:\n";
  my $m2 = "Character '%s' is hexadecimal %#.4x.";
  my $m3 = "Character     is hexadecimal %#.4x.";
  my $ch;
  my $x;
   
  #
  Console->WriteLine($m1);
  do {
    $x = Console->Read();
    try: eval {
      die "Value was either too large or too small for a character.\n" 
        if $x < 0;
      $ch = chr $x;
      if ( $ch =~ /^\s+$/ ) {
        Console->WriteLine($m3, $x);
        if ( $ch eq chr 0x0a ) {
          Console->WriteLine($m1);
        }
      }
      else {
        Console->WriteLine($m2, $ch, $x);
      }
    };
    catch: if ( $@ ) {
      chomp $@;
      Console->WriteLine("%s Value read = %d.", $@, $x);
      $ch = "\0";
      Console->WriteLine($m1);
    }

  }
  while ( $ch ne '+' );
  return 0;
}

exit main();

__END__

=pod

This example produces the following results:

  Type a string of text then press Enter. Type '+' anywhere in the text to quit:

  The quick brown fox.
  Character 'T' is hexadecimal 0x0054.
  Character 'h' is hexadecimal 0x0068.
  Character 'e' is hexadecimal 0x0065.
  Character     is hexadecimal 0x0020.
  Character 'q' is hexadecimal 0x0071.
  Character 'u' is hexadecimal 0x0075.
  Character 'i' is hexadecimal 0x0069.
  Character 'c' is hexadecimal 0x0063.
  Character 'k' is hexadecimal 0x006b.
  Character     is hexadecimal 0x0020.
  Character 'b' is hexadecimal 0x0062.
  Character 'r' is hexadecimal 0x0072.
  Character 'o' is hexadecimal 0x006f.
  Character 'w' is hexadecimal 0x0077.
  Character 'n' is hexadecimal 0x006e.
  Character     is hexadecimal 0x0020.
  Character 'f' is hexadecimal 0x0066.
  Character 'o' is hexadecimal 0x006f.
  Character 'x' is hexadecimal 0x0078.
  Character '.' is hexadecimal 0x002e.
  Character     is hexadecimal 0x000d.
  Character     is hexadecimal 0x000a.

  Type a string of text then press Enter. Type '+' anywhere in the text to quit:

  ^Z
  Value was either too large or too small for a character. Value read = -1.

  Type a string of text then press Enter. Type '+' anywhere in the text to quit:

  +
  Character '+' is hexadecimal 0x002b.
