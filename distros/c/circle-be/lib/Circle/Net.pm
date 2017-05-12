#  You may distribute under the terms of the GNU General Public License
#
#  (C) Paul Evans, 2017 -- leonerd@leonerd.org.uk

package Circle::Net;

use strict;
use warnings;

use base qw( Tangence::Object Circle::WindowItem );

sub set_network_status
{
   my $self = shift;
   my ( $status ) = @_;

   $self->{status} = $status;

   my $text = $self->get_prop_tag;
   $text .= "[$self->{status}]" if length $self->{status};

   $self->{widget_netname}->set_prop_text( $text ) if $self->{widget_netname};
}

sub get_widget_netname
{
   my $self = shift;

   return $self->{widget_netname} ||= do {
      my $registry = $self->{registry};

      my $widget = $registry->construct(
         "Circle::Widget::Label",
         classes => [qw( netname )],
      );
      $self->watch_property( "tag",
         on_updated => sub {
            my $text = $_[1];
            $text .= "[$self->{status}]" if length $self->{status};
            $widget->set_prop_text( $text );
         }
      );
      $widget;
   };
}

0x55AA;
