#  You may distribute under the terms of the GNU General Public License
#
#  (C) Paul Evans, 2008-2014 -- leonerd@leonerd.org.uk

package Circle::Net::IRC::Target;

use strict;
use warnings;
use base qw( Tangence::Object Circle::WindowItem );

sub new
{
   my $class = shift;
   my %args = @_;

   my $self = $class->SUPER::new( @_ );

   $self->{irc} = $args{irc};

   $self->set_prop_name( $args{name} );
   $self->set_prop_tag( $args{name} );

   $self->{root} = $args{root};
   $self->{net}  = $args{net};

   return $self;
}

# Convenience accessor
sub name
{
   my $self = shift;
   return $self->get_prop_name;
}

use Scalar::Util qw( refaddr );
use overload
#   '""' => "STRING",
   '0+' => sub { refaddr $_[0] },
   fallback => 1;

use constant PREFIX_OVERHEAD => 3;
use constant PRIVMSG_OVERHEAD => length("PRIVMSG :");
use constant CTCP_ACTION_OVERHEAD => length("PRIVMSG :\x01CTCP ACTION \x01");

sub STRING
{
   my $self = shift;
   return ref($self)."[name=".$self->name."]";
}

sub describe
{
   my $self = shift;
   return ref($self) . "[" . $self->name . "]";
}

sub get_prop_tag
{
   my $self = shift;
   return $self->name;
}

sub get_prop_network
{
   my $self = shift;
   return $self->{net};
}

sub reify
{
   my $self = shift;

   return if $self->get_prop_real;

   $self->set_prop_real( 1 );

   my $root = $self->{root};
   $root->broadcast_sessions( "new_item", $self );
}

sub on_message
{
   my $self = shift;
   my ( $command, $message, $hints ) = @_;

   # $command might contain spaces from synthesized events - e.g. "ctcp ACTION"
   ( my $method = "on_message_$command" ) =~ s/ /_/g;

   return 1 if $self->can( $method ) and $self->$method( $message, $hints );

   if( not $hints->{handled} and not $hints->{synthesized} ) {
      $self->push_displayevent( "irc.irc", {
            command => $command,
            prefix  => $message->prefix,
            args    => join( " ", map { "'$_'" } $message->args ),
         } );
      $self->bump_level( 1 );
   }

   return 1;
}

sub pick_display_target
{
   my $self = shift;
   my ( $display ) = @_;

   return $self        if $display eq "self";
   return $self->{net} if $display eq "server";
}

sub default_message_level
{
   my $self = shift;
   my ( $hints ) = @_;

   return $hints->{is_notice} ? 1 : 2;
}

sub on_message_text
{
   my $self = shift;
   my ( $message, $hints ) = @_;

   my $srcnick = $hints->{prefix_name};
   my $text    = $hints->{text};

   my $is_notice = $hints->{is_notice};

   my $net = $self->{net};

   my $event = {
      %$hints,
      text      => $net->format_text_tagged( $text ),
      is_action => 0, 
      level     => $self->default_message_level( $hints ),
      display   => ( !defined $hints->{prefix_nick} or $is_notice && !$self->get_prop_real ) ? "server" : "self",
   };

   $net->run_rulechain( "input", $event );

   my $eventname = $is_notice ? "notice" : "msg";

   $self->fire_event( $eventname, $srcnick, $text );

   if( my $target = $self->pick_display_target( $event->{display} ) ) {
      $target->push_displayevent( "irc.$eventname", { target => $self->name, nick => $srcnick, text => $event->{text} } );
      $target->bump_level( $event->{level} ) if defined $event->{level};

      $target->reify;
   }

   return 1;
}

sub on_message_ctcp_ACTION
{
   my $self = shift;
   my ( $message, $hints ) = @_;

   my $srcnick = $hints->{prefix_name};
   my $text    = $hints->{ctcp_args};

   my $net = $self->{net};

   my $event = {
      %$hints,
      text      => $net->format_text_tagged( $text ),
      is_action => 1,
      level     => $self->default_message_level( $hints ),
      display   => "self",
   };

   $net->run_rulechain( "input", $event );

   $self->fire_event( "act", $srcnick, $text );

   if( my $target = $self->pick_display_target( $event->{display} ) ) {
      $target->push_displayevent( "irc.act", { target => $self->name, nick => $srcnick, text => $event->{text} } );
      $target->bump_level( $event->{level} ) if defined $event->{level};

      $target->reify;
   }

   return 1;
}

sub on_connected
{
   my $self = shift;

   $self->push_displayevent( "status", { text => "Server is connected" } );
}

sub on_disconnected
{
   my $self = shift;
   my ( $message ) = @_;

   $self->push_displayevent( "status", { text => $message } );
}

sub _split_text_chunks
{
   my ( $text, $maxlen, $on_chunk ) = @_;

   my $head = "<< ";
   my $tail = " >>";

   while( length $text ) {
      if( $maxlen >= length $text ) {
         $on_chunk->( $text );
         return;
      }

      my $prefix = substr $text, 0, $maxlen - length( $tail );
      if( $prefix =~ m/\s+\S+$/ ) {
         substr( $prefix, $-[0] ) = "";
      }

      $on_chunk->( $prefix . $tail );

      substr( $text, 0, length $prefix ) = "";
      $text =~ s/^\s+//;
      substr( $text, 0, 0 ) = $head;
   }
}

sub msg
{
   my $self = shift;
   my ( $text, %hints ) = @_;

   my $irc = $self->{irc};
   my $net = $self->{net};

   my $event = {
      text      => Circle::TaggedString->new( $text ),
      is_action => $hints{action}, 
   };

   $net->run_rulechain( "output", $event );

   my $is_action = $event->{is_action};

   my $maxlen = 510 -
      # To work out the maximum message length size we'd need to know our own
      # prefix that the server will send. We can't know the host, but we know
      # everything else. Just pretend it's maximal length, 64
      ( length( $irc->{nick} ) + length( $irc->{user} ) + 64 + PREFIX_OVERHEAD );
   my $target = $self->name;

   foreach my $line ( split m/\n/, $event->{text}->str ) {
      if( $is_action ) {
         _split_text_chunks( $line, $maxlen - length($target) - CTCP_ACTION_OVERHEAD, sub {
            $irc->send_ctcp( undef, $target, "ACTION", $_[0] );
         });
      }
      else {
         _split_text_chunks( $line, $maxlen - length($target) - PRIVMSG_OVERHEAD, sub {
            $irc->send_message( "PRIVMSG", undef, $target, $_[0] );
         });
      }

      my $line_formatted = $net->format_text( $line );

      $self->fire_event( $is_action ? "act" : "msg", $irc->nick, $line );
      $self->push_displayevent( $is_action ? "irc.act" : "irc.msg", { target => $self->name, nick => $irc->nick, text => $line_formatted } );
   }
}

sub method_msg
{
   my $self = shift; my $ctx = shift;
   $self->msg( $_[0], action => 0 );
}

sub notice
{
   my $self = shift;
   my ( $text ) = @_;

   my $irc = $self->{irc};
   $irc->send_message( "NOTICE", undef, $self->name, $text );

   my $net = $self->{net};
   my $text_formatted = $net->format_text( $text );

   $self->fire_event( "notice", $irc->nick, $text );
   $self->push_displayevent( "irc.notice", { target => $self->name, nick => $irc->nick, text => $text_formatted } );
}

sub method_notice
{
   my $self = shift; my $ctx = shift;
   $self->notice( @_ );
}

sub method_act
{
   my $self = shift; my $ctx = shift;
   $self->msg( $_[0], action => 1 );
}

sub command_say
   : Command_description("Quote text directly as a PRIVMSG")
   : Command_arg('text', eatall => 1)
{
   my $self = shift;
   my ( $text ) = @_;

   $self->msg( $text, action => 0 );

   return;
}

sub command_me
   : Command_description("Send a CTCP ACTION")
   : Command_arg('text', eatall => 1)
{
   my $self = shift;
   my ( $text ) = @_;

   $self->msg( $text, action => 1 );

   return;
}

sub commandable_parent
{
   my $self = shift;
   return $self->{net};
}

sub enumerable_name
{
   my $self = shift;
   return $self->get_prop_tag;
}

sub parent
{
   my $self = shift;
   return $self->{net};
}

sub enter_text
{
   my $self = shift;
   my ( $text ) = @_;

   return unless length $text;

   $self->msg( $text );
}

sub get_widget_commandentry
{
   my $self = shift;
   my $widget = $self->SUPER::get_widget_commandentry;

   $self->{net}->add_entry_widget_completegroups( $widget );

   return $widget;
}

0x55AA;
