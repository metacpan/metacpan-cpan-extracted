#!/usr/bin/perl -w 

use strict;
use File::stat;
use File::Basename;
use Data::Dumper;

#
# Peseudo:
# 
# start
#    open directory
#    while there are entries...
#       if it's a directory,
#          recurse into directory
#             returns a hash refrence, with refs name,size,children,colour
#          add size to total size
#          push ref onto list
#       if it's a file
#          create ref name,size,children,colour
#          add size to total size
#          push ref onto list
#       otherwise, it's not something we're interested
#    done
#    close dir
#    create ref name,size,children,colour
#    return ref
# end
#

sub Dir2Tree
{
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

      if( -d $filename )
      {
         $item = &Dir2Tree( $filename );
         $item->{name} = basename( $item->{name} );
      }
      elsif( -f $filename )
      {
         my $info = stat( $filename );
         $item->{size} = $info->size;
         $item->{name} = $dir_entry;
         $item->{colour} = 0xFFFFFF;
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
   $tree->{colour} = 0xFFFFFF;
   $tree->{children} = \@children if( scalar(@children) > 0 );

   return $tree;
}

1;
