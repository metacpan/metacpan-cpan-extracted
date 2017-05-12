package Tie::Alias::Handle;

use 5.008;
use strict;
use warnings;
use Carp;

our $VERSION = '0.01';

sub isAlias { 1; };

sub TIEHANDLE {

	croak "use open with a & in the mode to dup a handle"; #FIXME

     #   my ( $class , $ref ) = @_ ;
     #   ref($ref) or croak "NOT A REFERENCE";
     #   if ( eval { tied($$ref) -> isAlias } ) {
     #           # we are re-aliasing something
     #           return tied ($$ref);
     #   }else{
     #           # $ref is already a pointer to the object
     #           bless $ref, $class;
     #   };
};




1;
__END__

=head1 NAME

Tie::Alias::Handle - required by Tie::Alias::TIEHANDLE

=head1 DESCRIPTION

This module holds a single error message, suggesting
that the user append an ampersand to their mode string
to duplicate a handle:  handles already have a robust
aliasing mechanism.

=head1 BUGS

Buffers may get duplicated when you duplicate file handles,
also a new handle is opened instead of aliasing to a handle,
so this doesn't really work to provide an alias like the
other Tie::Alias modules at this time.  Future releases
will be complete, hopefully.  Perhaps one of the file handle
team will adopt this module.


=head1 SEE ALSO

l<Tie::Alias>
l<perltie>
l<open>

=cut
