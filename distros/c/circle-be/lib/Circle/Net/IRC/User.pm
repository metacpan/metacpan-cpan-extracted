#  You may distribute under the terms of the GNU General Public License
#
#  (C) Paul Evans, 2008-2016 -- leonerd@leonerd.org.uk

package Circle::Net::IRC::User;

use strict;
use warnings;
use base qw( Circle::Net::IRC::Target );

our $VERSION = '0.173320';

use Carp;

# Don't reprint RPL_USERISAWAY message within 1 hour
# TODO: Some sort of config setting system
my $awaytime_print = 3600;

sub default_message_level
{
   my $self = shift;
   my ( $hints ) = @_;

   return 3;
}

sub on_message
{
   my $self = shift;
   my ( $command, $message, $hints ) = @_;

   # Messages from the user will have a prefix_user hint, server messages will not.
   if( defined( my $ident = $hints->{prefix_user} ) ) {
      my $hostname = $hints->{prefix_host};

      $self->update_ident( "$ident\@$hostname" );
   }

   return $self->SUPER::on_message( @_ );
}

sub update_ident
{
   my $self = shift;
   my ( $ident ) = @_;

   return if defined $self->get_prop_ident and $self->get_prop_ident eq $ident;
   $self->set_prop_ident( $ident );
}

sub on_message_NICK
{
   my $self = shift;
   my ( $message, $hints ) = @_;

   my $oldnick = $self->name;
   my $newnick = $hints->{new_nick};

   $self->push_displayevent( "irc.nick", { oldnick => $oldnick, newnick => $newnick } );
   $self->bump_level( 1 );

   $self->set_prop_name( $newnick );
   $self->set_prop_tag( $newnick );

   my $oldnick_folded = $self->{irc}->casefold_name( $oldnick );

   $self->fire_event( "change_nick", $oldnick, $oldnick_folded, $newnick, $hints->{new_nick_folded} );

   return 1;
}

sub on_message_QUIT
{
   my $self = shift;
   my ( $message, $hints ) = @_;

   my $nick    = $self->name;
   my $quitmsg = $hints->{text};

   defined $quitmsg or $quitmsg = "";

   my $net = $self->{net};
   my $quitmsg_formatted = $net->format_text( $quitmsg );

   my $userhost = "$hints->{prefix_user}\@$hints->{prefix_host}";

   $self->push_displayevent( "irc.quit", { nick => $nick, userhost => $userhost, quitmsg => $quitmsg_formatted } );
   $self->bump_level( 1 );

   return 1;
}

sub on_message_RPL_AWAY
{
   my $self = shift;
   my ( $message, $hints ) = @_;

   my $nick    = $self->name;
   my $awaymsg = $hints->{text};

   defined $awaymsg or $awaymsg = "";

   # Surpress the message if it's already been printed and it's quite soon
   my $now = time;
   if( defined $self->{printed_awaymsg} and
       $self->{printed_awaymsg} eq $awaymsg and
       $now < $self->{printed_awaytime} + $awaytime_print ) {
      return 1;
   }

   my $net = $self->{net};
   my $awaymsg_formatted = $net->format_text( $awaymsg );

   my $userhost = "$hints->{prefix_user}\@$hints->{prefix_host}";

   $self->push_displayevent( "irc.away", { nick => $nick, userhost => $userhost, text => $awaymsg_formatted } );
   $self->bump_level( 1 );

   $self->{printed_awaymsg} = $awaymsg;
   $self->{printed_awaytime} = $now;

   return 1;
}

sub on_message_RPL_LOGON
{
   my $self = shift;
   $self->on_message_RPL_NOWON( @_ );

   my $nick = $self->name;

   $self->push_displayevent( "irc.online", { nick => $nick } );
   $self->bump_level( 1 );

   return 1;
}

sub on_message_RPL_LOGOFF
{
   my $self = shift;
   $self->on_message_RPL_NOWOFF( @_ );

   my $nick = $self->name;

   $self->push_displayevent( "irc.offline", { nick => $nick } );
   $self->bump_level( 1 );

   return 1;
}

sub on_message_RPL_NOWON
{
   my $self = shift;

   $self->set_prop_presence( "online" );

   return 1;
}

sub on_message_RPL_NOWOFF
{
   my $self = shift;

   $self->set_prop_presence( "offline" );

   return 1;
}

# Send it back
sub on_message_whois
{
   my $self = shift;
   my ( $message, $hints ) = @_;

   my $net = $self->{net};
   $net->on_message_whois( $message, $hints );
}

sub command_close
   : Command_description("Close the window")
{
   my $self = shift;

   $self->destroy;
}

sub command_requery
   : Command_description("Change the target nick for this user query")
   : Command_arg('newnick')
{
   my $self = shift;
   my ( $newnick ) = @_;

   my $oldnick = $self->name;

   $self->set_prop_name( $newnick );
   $self->set_prop_tag( $newnick );

   my $oldnick_folded = $self->{irc}->casefold_name( $oldnick );
   my $newnick_folded = $self->{irc}->casefold_name( $newnick );

   $self->fire_event( "change_nick", $oldnick, $oldnick_folded, $newnick, $newnick_folded );

   return ( "Now talking to $newnick" );
}

sub command_whois
   : Command_description("Send a WHOIS query")
   : Command_arg('user?')
{
   my $self = shift;
   my ( $user, $cinv ) = @_;

   $user //= $self->name;

   $self->{net}->command_whois( $user, $cinv );
}

sub make_widget_pre_scroller
{
   my $self = shift;
   my ( $box ) = @_;

   my $registry = $self->{registry};

   my $identlabel = $registry->construct(
      "Circle::Widget::Label",
      classes => [qw( ident )],
   );
   $self->watch_property( "ident",
      on_updated => sub { $identlabel->set_prop_text( $_[1] ) }
   );

   $box->add( $identlabel );
}

sub get_widget_presence
{
   my $self = shift;

   my $registry = $self->{registry};
   my $presencelabel = $registry->construct(
      "Circle::Widget::Label",
      classes => [qw( presence )],
   );
   $self->watch_property( "presence",
      on_updated => sub { $presencelabel->set_prop_text( "($_[1])" ) },
   );

   return $presencelabel;
}

sub get_widget_statusbar
{
   my $self = shift;

   my $registry = $self->{registry};
   my $net = $self->{net};

   my $statusbar = $registry->construct(
      "Circle::Widget::Box",
      classes => [qw( status )],
      orientation => "horizontal",
   );

   $statusbar->add( $net->get_widget_netname );

   $statusbar->add( $self->get_widget_presence );

   return $statusbar;
}

0x55AA;
