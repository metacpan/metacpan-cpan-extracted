package Twitter::NoDateError;

use strict;
use warnings;

use base 'Error::Simple';

=pod

=head1 NAME

Twitter::NoDateError - Error to be thronw when no date was passed as parameter  

=head1 SYNOPSIS
 
 use Error;

 sub new {
     my $class = shift;
     my $date = shift || throw Twitter::NoDateError();
     my $this;
    
    bless $this, $class;
 }
 
=head1 DESCRIPTION 

This is package used to be thrown as an error

=head1 INTERFACE

The same methods as Error::Simple can be used. 

=head1 AUTHOR

Victor A. Rodriguez (Bit-Man)

=head1 SEE ALSO

Error, Error::Simple

=cut

1;