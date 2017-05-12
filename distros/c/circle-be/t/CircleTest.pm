#  You may distribute under the terms of the GNU General Public License
#
#  (C) Paul Evans, 2012-2013 -- leonerd@leonerd.org.uk

package t::CircleTest;

use strict;
use warnings;

our $VERSION = '0.170740';

use Exporter qw( import );
our @EXPORT_OK = qw(
   get_session
   get_widget_from
   get_widgetset_from
   send_command
);

use IO::Async::Test;

sub get_session
{
   my ( $rootobj ) = @_;

   my $session;
   $rootobj->call_method(
      method => "get_session",
      args   => [ [qw( tabs )] ],
      on_result => sub { $session = $_[0] },
   );

   wait_for { $session };

   return $session;
}

sub get_widget_from
{
   my ( $windowitem ) = @_;

   my $widget;
   $windowitem->call_method(
      method => "get_widget",
      on_result => sub { $widget = $_[0] },
      on_error  => sub { die "Test failed early - $_[-1]" },
   );

   wait_for { $widget };
   return $widget;
}

my %widgetsets;
sub get_widgetset_from
{
   my ( $windowitem ) = @_;

   return $widgetsets{$windowitem} if $widgetsets{$windowitem};

   my $widget = get_widget_from( $windowitem );

   my %widgets;
   my @queue = ( $widget );
   while( my $w = shift @queue ) {
      if( $w->proxy_isa( "Circle.Widget.Box" ) ) {
         push @queue, map { $_->{child} } @{ $w->prop( "children" ) };
      }
      else {
         $widgets{ ( $w->proxy_isa )[0]->name } = $w;
      }
   }

   return $widgetsets{$windowitem} = \%widgets;
}

sub send_command
{
   my ( $windowitem, $command ) = @_;

   my $done;
   $windowitem->call_method(
      method => "do_command",
      args   => [ $command ],
      on_result => sub { $done = 1 },
      on_error  => sub { die "Test failed early - $_[-1]" },
   );

   wait_for { $done };
}

0x55AA;
