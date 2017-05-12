#  You may distribute under the terms of the GNU General Public License
#
#  (C) Paul Evans, 2008-2013 -- leonerd@leonerd.org.uk

package Circle::Widget::Entry;

use strict;
use warnings;

use base qw( Circle::Widget );

sub new
{
   my $class = shift;
   my %args = @_;

   my $self = $class->SUPER::new( @_ );

   $self->{on_enter} = $args{on_enter};
   $self->{history}  = $args{history};

   $self->set_prop_text( "" );
   $self->set_prop_autoclear( $args{autoclear} );

   return $self;
}

sub method_enter
{
   my $self = shift;
   my ( $ctx, $text ) = @_;
   $self->{on_enter}->( $text, $ctx );

   if( defined( my $history = $self->{history} ) ) {
      my $histqueue = $self->get_prop_history;

      my $overcount = @$histqueue + 1 - $history;

      $self->shift_prop_history( $overcount ) if $overcount > 0;

      $self->push_prop_history( $text );
   }
}

package Circle::Widget::Entry::CompleteGroup;

use base qw( Tangence::Object );

sub new
{
   my $class = shift;
   my %args = @_;

   my $self = $class->SUPER::new( @_ );

   $self->set_prop_only_at_sol( $args{only_at_sol} || 0 );
   $self->set_prop_prefix_sol( $args{prefix_sol} || '' );
   $self->set_prop_suffix_sol( $args{suffix_sol} || '' );

   return $self;
}

sub set
{
   my $self = shift;
   my ( @strings ) = @_;

   $self->set_prop_items( \@strings );
}

sub add
{
   my $self = shift;
   my ( $str ) = @_;

   grep { $_ eq $str } @{ $self->get_prop_items } or
      $self->push_prop_items( $str );
}

sub remove
{
   my $self = shift;
   my ( $str ) = @_;

   my $items = $self->get_prop_items;
   my @indices = grep { $items->[$_] eq $str } 0 .. $#$items;

   $self->splice_prop_items( $_, 1, () ) for reverse @indices;
}

0x55AA;
