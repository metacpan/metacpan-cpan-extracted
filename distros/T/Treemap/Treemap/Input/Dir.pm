package Treemap::Input::Dir;

use 5.006;
use strict;
use warnings;
use Carp;

use File::Basename;

require Exporter;
require Treemap::Input;

our @ISA = qw( Treemap::Input Exporter );
our @EXPORT_OK = (  );
our @EXPORT = qw( );
our $VERSION = '0.01';

# ------------------------------------------
# Methods:
# ------------------------------------------
sub new
{
   my $classname = shift;
   my $self = $classname->SUPER::new( @_ );  # Call parent constructor
   $self->_init( @_ );  # Initialize child variables
   return $self;
}

sub _init
{
   my $self = shift;
   $self->{FOLLOW_SYMLINK} = $self->{FOLLOW_SYMLINK} || undef;
}

sub load
{
   my $self = shift;
   my( $path ) = @_;

   if ( $self->{ DATA } = $self->_load( $path ) )
   { 
      return 1;
   }
   return 0;
}

# ------------------------------------------
# _load()
# ------------------------------------------
sub _load
{
   my $self = shift;
   my( $path ) = @_;
   my( $tree, $DH, @children, $size );

   @children = ();
   $size = 0;

   opendir( $DH, $path );

   while( my $dir_entry = readdir( $DH ) )
   {
      next if( $dir_entry =~ /^\.{1,2}$/ );

      my $item;
      my $filename = "$path/$dir_entry";

      # Skip Sympbolic Links
      if( !$self->{FOLLOW_SYMLINK} && -l $filename )
      {
         next;
      }

      if( -d $filename )
      {
         $item = $self->_load( $filename );
         $item->{name} = basename( $item->{name} );
      }
      elsif( -f $filename )
      {
         ( $item->{size}, my $mtime ) = (stat( $filename ))[7,9];
         $item->{name} = $dir_entry;

         $item->{colour} = $self->_colour_by_mtime( $mtime );
      }
      else
      {
         next;
      }
      push( @children, $item );
      $size += $item->{size};
   }
   close( $DH );
   
   $tree->{name} = $path;
   $tree->{size} = $size;
   $tree->{colour} = "#FFFFFF";
   $tree->{children} = \@children if( scalar(@children) > 0 );

   return $tree;
}

sub _colour_by_mtime
{
   my $self = shift;
   my $mtime = shift;
   my $ctime = time;

   my $age = 1 + ( $ctime - $mtime ) / ( 60 * 60 );
   my $level = int ( log( $age ) * 10 );

   $level = 100 if ( $level > 100 );

   $level = int( 255 * ( $level / 100 ));
  
   return sprintf("#%02X%02X%02X", 255-$level, 0, $level );
}

sub _colour_by_type
{
   my $self = shift;
   my $ext  = shift;

   $ext =~ m/(\w)(\w)?(\w)?/;
}

1;

__END__

# ------------------------------------------
# Documentation:
# ------------------------------------------

=head1 NAME

=over 4

=item Treemap::Input::Dir

Creates an input object with methods suitable for use with a Treemap object.

=back 4

=head1 SYNOPSIS

 #!/usr/bin/perl -w
 use Treemap::Input::Dir;
 
 my $dir = Treemap::Input::Dir->new();
 $dir->load( "/some/dir" );

=head1 DESCRIPTION

This class reads in a directory tree, and makes the data available for use to a
Treemap object.  Colour is based the the mtime of the files. Rectangle areas
are based on the size of the directory contents / files.

=head1 METHODS

=over 4

=item new( FOLLOW_SYMLINKS => (1|undef) )

Instantiate a new object

=item load( "path" )

Load the directory tree from the specified path.

=back 4

=head1 SEE ALSO

L<Treemap::Input>, L<Treemap>

=head1 AUTHORS

Simon Ditner <simon@uc.org>, and Eric Maki <eric@uc.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
