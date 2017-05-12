package Treemap::Input;

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
# new() - Create and return new Treemap object:
# ------------------------------------------
sub new 
{
   my $proto = shift;
   my $class = ref( $proto ) || $proto;
   my $self = {
      @_,
   };

   bless $self, $class;
   return $self;
}

sub treedata 
{
   my $self = shift;
   return $self->{ DATA };
}
1;

__END__

# ------------------------------------------
# Documentation:
# ------------------------------------------

=head1 NAME

Treemap::Input - Creates an input object with methods suitable for use with a
Treemap object.

=head1 DESCRIPTION

This base class is not meant to be directly instantiated. Subclasses of
Treemap::Input which implement input from various formats shoud be instantiated
instead. See the SEE ALSO section below.

=head1 CREATING INPUT SUBCLASSES

 package Treemap::Input::YourSubclass

 require Treemap::Input
 our @ISA = qw( Treemap::Input Exporter );

No special methods need be implemented at this time. This will be changed in
the future, since it violates data incapsulation. When we think of a better way
to implement this, we will.

For the time being, a hash within the instance of the class of name "DATA" must
exist. It should be structured as follows:

 {DATA}->{name} = string
       ->{size} = numeric
       ->{colour} = "#RRGGBB"
       ->{children} = array reference to refrences of this format

=head1 SEE ALSO

L<Treemap::Input::Dir>, L<Treemap::Input::XML>

=head1 AUTHORS

Simon Ditner <simon@uc.org>, and Eric Maki <eric@uc.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
