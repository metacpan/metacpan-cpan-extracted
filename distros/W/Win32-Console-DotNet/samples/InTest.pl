# https://learn.microsoft.com/en-us/dotnet/api/system.console.in?view=net-8.0
# The following sample illustrates the use of the In property.

use 5.014;
use warnings;

use lib '../lib', 'lib';
use Win32::Console::DotNet;
use System;

sub main {

  my $tIn = Console->In;
  my $tOut = Console->Out;

  $tOut->say("Hola Mundo!");
  $tOut->print("What is your name: ");
  my $name = $tIn->getline();
  chomp $name;

  $tOut->printf("Buenos Dias, %s!\n", $name);
  return 0;
}

exit main();
