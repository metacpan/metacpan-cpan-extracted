# https://learn.microsoft.com/en-us/dotnet/api/system.console.openstandardoutput?view=net-8.0
# https://learn.microsoft.com/en-us/dotnet/api/system.console.readline?view=net-8.0
# The following example illustrates the use of the OpenStandardOutput method.

use 5.014;
use warnings;
use FindBin qw( $Script );

use lib '../lib', 'lib';
use Win32::Console::DotNet;
use System;

use constant tabSize => 4;
use constant usageText => "Usage: perl $Script inputfile.txt outputfile.txt";

sub main {
  my (undef, undef, @args) = @_;
  if (@args < 2) {
    Console->WriteLine(usageText);
    return 1;
  }

  try: eval {
    # Attempt to open output file.
    if ( my $writer = IO::File->new($args[1], 'w') ) {
      if ( my $reader = IO::File->new($args[0], 'r') ) {
        # Redirect standard output from the console to the output file.
        Console->SetOut($writer);
        # Redirect standard input from the console to the input file.
        Console->SetIn($reader);
        my $line;
        while ( defined($line = Console->ReadLine()) ) {
          my $newLine = do { my $re = ' ' x tabSize; $line =~ s/$re/\t/r };
          Console->WriteLine($newLine);
        }
      }
    }
  };
  catch: if ( $@ ) {
    my $errorWriter = Console->Error;
    $errorWriter->say($@);
    $errorWriter->say(usageText);
    return 1;
  }

  # Recover the standard output stream so that a
  # completion message can be displayed.
  my $standardOutput = IO::File->new_from_fd(
    fileno(Console->OpenStandardOutput()), 'w');
  $standardOutput->autoflush(1);
  Console->SetOut($standardOutput);
  Console->WriteLine("$Script has completed the processing of $args[0].");
  return 0;
}

exit main(@ARGV+1, $0, @ARGV);
