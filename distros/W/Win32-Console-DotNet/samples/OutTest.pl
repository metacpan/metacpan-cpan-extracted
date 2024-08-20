# https://learn.microsoft.com/en-us/dotnet/api/system.console.out?view=net-8.0
# The following example demostrate the Out property.

use 5.014;
use warnings;

use lib '../lib', 'lib';
use Win32::Console::DotNet;
use System;

sub main {
  # Get all files in the current directory.
  my @files = do {
    use autodie;
    opendir my $dir, ".";
    local @_ = readdir $dir;
    closedir $dir;
    @_;
  };
  @files = sort(@files);

  # Display the files to the current output source to the console.
  Console->Out->say("First display of filenames to the console:");
  Console->Out->say($_) foreach @files;
  Console->Out->say();

  # Redirect output to a file named Files.txt and write file list.
  my $sw = IO::File->new(".\\Files.txt", 'w');
  $sw->autoflush(1);
  Console->SetOut($sw);
  Console->Out->say("Display filenames to a file:");
  Console->Out->say($_) foreach @files;
  Console->Out->say();

  # Close previous output stream and redirect output to standard output.
  Console->Out->close();
  $sw = IO::File->new_from_fd(fileno(Console->OpenStandardOutput()), 'w');
  $sw->autoflush(1);
  Console->SetOut($sw);

  # Display the files to the current output source to the console.
  Console->Out->say("Second display of filenames to the console:");
  Console->Out->say($_) foreach @files;
  return 0;
}

exit main();

__END__

=pod

The following example uses the C<Out> property to display an array containing 
the  names of files in the application's current directory to the standard 
output  device. It then sets the standard output to a file named Files.txt and 
lists the array elements to the file. Finally, it sets the output to the 
standard output stream and again displays the array elements to the standard 
output device.
