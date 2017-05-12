package Treemap::Input::XML;

use 5.006;
use strict;
use warnings;
use Carp;
use XML::Simple;

require Exporter;
require Treemap::Input;

our @ISA = qw( Treemap::Input Exporter );
our @EXPORT_OK = (  );
our @EXPORT = qw( );
our $VERSION = '0.01';


# ------------------------------------------
# Methods:
# ------------------------------------------

sub load
{
   my $self = shift;
   my( $path ) = @_;
   
   if ( $self->{ DATA } = $self->_load( $path )  )
   {
      return 1;
   }
   return 0;
}

# ------------------------------------------
# ------------------------------------------
#  Hey, look at that, XML loads right in as our tree map data structure. Ain't
#  that handy?
# ------------------------------------------
sub _load
{
   my $self = shift;
   my( $path ) = @_;
   my $tree = XMLin( $path, keyattr => {}, forcearray => [ "children" ] );
   return $tree;
}

1;

__END__

# ------------------------------------------
# Documentation:
# ------------------------------------------

=head1 NAME

=over 4

=item Treemap::Input::XML

An input class to read in XML documents of a specific format suitable for use
with Treemap objects. The format is explained below.

=back 4

=head1 SYNOPSIS

 #!/usr/bin/perl -w
 use Treemap::Input::XML;
 
 my $xml = Treemap::Input::XML->new();
 $xml->load( "somefile.xml" );

=head1 DESCRIPTION

This class reads in an XML file, and makes the data available for use to a Treemap object.

The format of the XML file is as follows:

 <children name="test1" size="8" colour="#FFFFFF">
   <children name="test1sub1" size="4" colour="#FF0000">
     <children name="test1sub1sub1" size="2" colour="#00FF00" />
     <children name="test1sub1sub2" size="2" colour="#00FF00" />
   </children>
   <children name="test1sub2" size="4" colour="#FFFF00" />
 </children>

I<Note that the size of a parent node must be the sum of all it's children.>

=head1 METHODS

=over 4

=item new()

Instantiate a new object

=item load( "path/to/file.xml" )

Loads the XML data from the specified file path.

=back 4

=head1 SEE ALSO

L<Treemap::Input>, L<Treemap>

=head1 AUTHORS

Simon Ditner <simon@uc.org>, and Eric Maki <eric@uc.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
