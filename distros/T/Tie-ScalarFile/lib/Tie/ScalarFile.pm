package Tie::ScalarFile;

use Carp;
use strict;
use warnings;
use warnings::register;

our $VERSION = "1.12";

my $count = 0;

sub TIESCALAR {
   my $class   = shift;
   my $filename = shift;
   my $fh;
   
   if (open $fh, "<", $filename or
       open $fh, ">", $filename) 
   {
          close $fh;
          $count++;
          return bless \$filename, $class;
   }
   carp "Can't tie $filename: $!" if warnings::enabled();
   return;
}

sub FETCH {
   my $self = shift;
   confess "I am not a class method" unless ref $self;
   return unless open my $fh, $$self;
   read ($fh, my $value, -s $fh);
   return $value;
}

sub STORE {
   my ($self, $value) = @_;
   ref $self                  or confess "not a class method";
   open my $fh, ">", $self    or croak   "can't clobber $$self: $!";
   syswrite ($fh, $value) == length $value 
                              or croak "can't write to $$self: $!";
   close $fh                  or croak "can't close $$self: $!";
   return $value;
}

sub DESTROY {
   my $self = shift;
   confess "wrong type" unless ref $self;
   $count--;
}

sub count { $count }


1;
__END__


=head1 NAME

Tie::ScalarFile - 

=head1 SYNOPSIS

  use Tie::ScalarFile;
  
  my $string;
  tie ($string, "Tie::ScalarFile", "file.txt");
  $string = <<".EOF.";
  blah blah blah...
  .EOF.
  #file.txt now contains "blah blah blah...".
  print $string; #prints "blah blah blah...".
  print count; #prints "1".  

=head1 DESCRIPTION

Tie::ScalarFile is a perl module for associating scalars
with files. You can then add to the scalar, and the file
will be written to. You can read the value, and the file will be
read from.

=head1 FUNCTIONS

=over 3

=item count

counts the number
of currently tied
scalars, and returns it.
for example:

 tie (my $string, "Tie::ScalarFile", "file.txt");
 tie (my $string2, "Tie::ScalarFile", "file2.txt");
 
 print count; #prints "2".


=head1 EXAMPLE

here is a real-life example:

 #!/usr/local/bin/perl -w
 
 use Tie::ScalarFile;
 
 my $contents;
 tie ($contents, "Tie::ScalarFile", "test.txt");
 
 while (<>) {        #while there's stdin...
    $contents = $_;  #...write the input to the test.txt file...
    print $contents; #...and then read it in and print it.
 }
 
 print "There are " . count . "tied scalars."; #print the number of tied scalars.

=head1 EXPORT

count

=head1 SEE ALSO

L<Tie::Scalar>, L<Tie::File>

=head1 AUTHOR

Linc Nightcat, E<lt>nightcat@crocker.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by <nightcat>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut
