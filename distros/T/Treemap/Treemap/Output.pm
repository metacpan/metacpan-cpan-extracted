package Treemap::Output;

use 5.006;
use strict;
use warnings;
use Carp;

require Exporter;

our @ISA = qw( Exporter );
our @EXPORT_OK = (  );
our @EXPORT = qw( );
our $VERSION = '0.01';


# ------------------------------------------
# Methods:
# ------------------------------------------


# ------------------------------------------
# new() - Create and return new Treemap 
#         object:
# ------------------------------------------
sub new 
{
   my $proto = shift;
   my $class = ref( $proto ) || $proto;
   my $self = {
      @_,         # Allow user to override parameters
   };

   bless $self, $class;
   return $self;
}

1;

__END__

# ------------------------------------------
# Documentation:
# ------------------------------------------

=head1 NAME

Treemap::Output - Creates an output object with methods suitable for use with a
Treemap object.

=head1 DESCRIPTION

This base class is not meant to be directly instantiated. Subclasses of
Treemap::Output which implement output to various formats shoud be instantiated
instead. See the SEE ALSO section below for existing output methods.

=head1 CREATING OUTPUT SUBCLASSES

The following methods must be implemented, accepting the following parameters:

=over 4

=item rect(x1,y1,x2,y2,colour)

Co-ordinates are absolute and floating point, and colour is specified with
HTML-esque strings (#RRGGBB)

=item text(x1,y1,x2,y2,text,children)

Co-ordinates are absolute and floating point, text is the string you will be
printing, and children is a flag that will be set true, or false depending on
whether there will be any items contained within this rectangle that you're
labeling.  This is primarily used for positining the text.

=back 4

=head1 SEE ALSO

L<Treemap::Output::Imager>, L<Treemap::Output::PrintedText>

=head1 AUTHORS

Simon Ditner <simon@uc.org>, and Eric Maki <eric@uc.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
