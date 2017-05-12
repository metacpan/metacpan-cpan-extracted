#  You may distribute under the terms of the GNU General Public License
#
#  (C) Paul Evans, 2008-2010 -- leonerd@leonerd.org.uk

package Circle::Rule::Resultset;

use strict;
use warnings;

use Carp;

sub new
{
   my $class = shift;

   return bless {}, $class;
}

sub get_result
{
   my $self = shift;
   my ( $name ) = @_;

   carp "No result '$name'" unless exists $self->{$name};

   return $self->{$name};
}

sub push_result
{
   my $self = shift;
   my ( $name, $value ) = @_;

   if( !exists $self->{$name} ) {
      $self->{$name} = [ $value ];
   }
   elsif( ref $self->{$name} eq "ARRAY" ) {
      push @{ $self->{$name} }, $value;
   }
   else {
      croak "Expected '$name' to be an ARRAY result";
   }
}

sub merge_from
{
   my $self = shift;
   my ( $other ) = @_;

   foreach my $name ( %$other ) {
      my $otherval = $other->{$name};

      if( !$self->{$name} ) {
         $self->{$name} = $otherval;
         next;
      }

      my $myval = $self->{$name};

      # Already had it - type matches?
      if( ref $myval ne ref $otherval ) {
         croak "Cannot merge; '$name' has different result types";
      }

      my $type = ref $myval;

      if( ref $myval eq "ARRAY" ) {
         push @$myval, @$otherval;
      }
      else {
         croak "Don't know how to handle result type '$name' ($type)";
      }
   }
}

0x55AA;
