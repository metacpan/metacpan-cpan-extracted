# https://learn.microsoft.com/en-us/dotnet/api/system.console.openstandarderror?view=net-9.0
# The example calls the SetError method to redirect error information to a 
# file, calls the OpenStandardError method in the process of reacquiring the 
# standard error stream, and indicates that error information was written to a 
# file.

use 5.014;
use warnings;

use lib '../lib', 'lib';
use Win32::Console::DotNet;
use System;

sub main {
  my ($argc, @args) = @_;
  my $errorOutput = "";
  # Make sure that there is at least one command line argument.
  if ( @args <= 1 ) {
    $errorOutput .= "You must include a filename on the command line.\n";
  }

  for (my $ctr = 1; $ctr <= $#args; $ctr++)  {
    # Check whether the file exists.
    unless ( -e ($args[$ctr]//'') ) {
      $errorOutput .= sprintf("'%s' does not exist.\n", $args[$ctr]//'');
    } else {
      # Display the contents of the file.
      my $sr = IO::File->new($args[$ctr], 'r');
      my $contents = join '', $sr->getlines();
      $sr->close();
      Console->WriteLine("*****Contents of file '%s':\n\n",
        $args[$ctr]);
      Console->WriteLine($contents);
      Console->WriteLine("*****\n");
    }
  }

  # Check for error conditions.
  if ( $errorOutput ) {
    # Write error information to a file.
    Console->SetError(IO::File->new('.\ViewTextFile.Err.txt', 'w+'));
    Console->Error->say($errorOutput);
    Console->Error->close();
    # Reacquire the standard error stream.
    my $standardError = IO::File->new_from_fd(
        fileno(Console->OpenStandardError()), 'w');
    $standardError->autoflush(1);
    Console->SetError($standardError);
    Console->Error->say("\nError information written to ViewTextFile.Err.txt");
  }

  return 0;
}

exit main(@ARGV+1, $0, @ARGV);

__END__

=pod

If the example is compiled and run with the following command line:

  perl ViewTextFile.pl file1.txt file2.txt

and neither file1.txt nor file2.txt exist, it displays the following output:

  Error information written to ViewTextFile.Err.txt

and writes the following text to ViewTextFile.Err.txt:
  
  'file1.txt' does not exist.
  'file2.txt' does not exist.
