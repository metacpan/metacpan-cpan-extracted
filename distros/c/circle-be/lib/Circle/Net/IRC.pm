#  You may distribute under the terms of the GNU General Public License
#
#  (C) Paul Evans, 2008-2017 -- leonerd@leonerd.org.uk

package Circle::Net::IRC;

use strict;
use warnings;

use base qw( Circle::Net Circle::Ruleable );
__PACKAGE__->APPLY_Ruleable;

use base qw( Circle::Rule::Store ); # for the attributes

our $VERSION = '0.173320';

use constant NETTYPE => 'irc';

use Circle::Net::IRC::Channel;
use Circle::Net::IRC::User;

use Circle::TaggedString;

use Circle::Rule::Store;

use Circle::Widget::Box;
use Circle::Widget::Label;

use Net::Async::IRC 0.10; # on_irc_error
use IO::Async::Timer::Countdown;

use Text::Balanced qw( extract_delimited );
use Scalar::Util qw( weaken );

sub new
{
   my $class = shift;
   my %args = @_;

   my $self = $class->SUPER::new( %args );

   $self->{root} = $args{root};
   my $loop = $self->{loop} = $args{loop};

   # For WindowItem
   $self->set_prop_tag( $args{tag} );

   my $irc = $self->{irc} = Net::Async::IRC->new(
      # TODO: All these event handler subs should be weaselled
      on_message => sub {
         my ( $irc, $command, $message, $hints ) = @_;
         $self->on_message( $command, $message, $hints );
      },

      on_closed => sub {
         $self->on_closed;
      },

      on_irc_error => sub {
         my ( $irc, $message ) = @_;
         $self->push_displayevent( "status", { text => "IRC error $message" } );
         $self->close_now;
      },

      encoding => "UTF-8",

      pingtime => 120,
      on_ping_timeout => sub {
         $self->on_ping_timeout;
      },

      pongtime => 60,
      on_pong_reply => sub {
         my ( $irc, $lag ) = @_;
         $self->on_ping_reply( $lag );
      },
   );

   weaken( my $weakself = $self );
   $self->{reconnect_timer} = IO::Async::Timer::Countdown->new(
      delay     => 1, # Doesn't matter, as ->enqueue_reconnect will set it before start anyway
      on_expire => sub { $weakself and $weakself->reconnect },
   );
   $loop->add( $self->{reconnect_timer} );

   $self->{servers} = [];

   $self->{channels} = {};
   $self->{users} = {};

   my $rulestore = $self->init_rulestore( parent => $args{root}->{rulestore} );

   $rulestore->register_cond( matchnick => $self );
   $rulestore->register_cond( fromnick  => $self );
   $rulestore->register_cond( channel   => $self );
   $rulestore->register_cond( isaction  => $self );

   $rulestore->register_action( display   => $self );
   $rulestore->register_action( chaction  => $self );

   $rulestore->new_chain( "input" );

   $rulestore->get_chain( "input" )->append_rule( "matchnick: highlight" );

   $rulestore->new_chain( "output" );

   $self->set_network_status( "disconnected" );

   return $self;
}

sub describe
{
   my $self = shift;
   return __PACKAGE__."[". $self->get_prop_tag . "]";
}

sub get_prop_users
{
   my $self = shift;

   my $users = $self->{users};
   return [ values %$users ];
}

sub reify
{
   # always real; this is a no-op
}

sub get_channel_if_exists
{
   my $self = shift;
   my ( $channame ) = @_;

   my $irc = $self->{irc};
   my $channame_folded = $irc->casefold_name( $channame );

   return $self->{channels}->{$channame_folded};
}

sub get_channel_or_create
{
   my $self = shift;
   my ( $channame ) = @_;

   my $irc = $self->{irc};
   my $channame_folded = $irc->casefold_name( $channame );

   return $self->{channels}->{$channame_folded} if exists $self->{channels}->{$channame_folded};

   my $registry = $self->{registry};
   my $chanobj = $registry->construct(
      "Circle::Net::IRC::Channel",
      root => $self->{root},
      net  => $self,
      irc  => $irc,
      name => $channame,
   );

   my $root = $self->{root};

   $self->{channels}->{$channame_folded} = $chanobj;
   $chanobj->subscribe_event( destroy => sub {
      my ( $chanobj ) = @_;
      $root->broadcast_sessions( "delete_item", $chanobj );
      $self->del_prop_channels( $chanobj );
      delete $self->{channels}->{$channame_folded};
   } );

   $self->add_prop_channels( $chanobj );

   return $chanobj;
}

sub get_user_if_exists
{
   my $self = shift;
   my ( $nick ) = @_;

   my $irc = $self->{irc};
   my $nick_folded = $irc->casefold_name( $nick );

   return $self->{users}->{$nick_folded};
}

sub get_user_or_create
{
   my $self = shift;
   my ( $nick ) = @_;

   unless( defined $nick and length $nick ) {
      warn "Unable to create a new user with an empty nick\n";
      return undef;
   }

   my $irc = $self->{irc};
   my $nick_folded = $irc->casefold_name( $nick );

   return $self->{users}->{$nick_folded} if exists $self->{users}->{$nick_folded};

   my $registry = $self->{registry};
   my $userobj = $registry->construct(
      "Circle::Net::IRC::User",
      root => $self->{root},
      net  => $self,
      irc  => $irc,
      name => $nick,
   );

   my $root = $self->{root};

   $self->{users}->{$nick_folded} = $userobj;

   $userobj->subscribe_event( destroy => sub {
      my ( $userobj ) = @_;
      $root->broadcast_sessions( "delete_item", $userobj );
      $self->del_prop_users( $userobj );
      my $nick_folded = $irc->casefold_name( $userobj->get_prop_name );
      delete $self->{users}->{$nick_folded};
   } );

   $userobj->subscribe_event( change_nick => sub {
      my ( undef, $oldnick, $oldnick_folded, $newnick, $newnick_folded ) = @_;
      $self->{users}->{$newnick_folded} = delete $self->{users}->{$oldnick_folded};
   } );

   $self->add_prop_users( $userobj );

   return $userobj;
}

sub get_target_if_exists
{
   my $self = shift;
   my ( $name ) = @_;

   my $irc = $self->{irc};
   my $type = $irc->classify_name( $name );

   if( $type eq "channel" ) {
      return $self->get_channel_if_exists( $name );
   }
   elsif( $type eq "user" ) {
      return $self->get_user_if_exists( $name );
   }
   else {
      return undef;
   }
}

sub get_target_or_create
{
   my $self = shift;
   my ( $name ) = @_;

   my $irc = $self->{irc};
   my $type = $irc->classify_name( $name );

   if( $type eq "channel" ) {
      return $self->get_channel_or_create( $name );
   }
   elsif( $type eq "user" ) {
      return $self->get_user_or_create( $name );
   }
   else {
      return undef;
   }
}

sub connect
{
   my $self = shift;
   my %args = @_;

   my $irc = $self->{irc};

   my $host = $args{host};
   my $nick = $args{nick} || $self->get_prop_nick || $self->{configured_nick};

   if( $args{SSL} and not eval { require IO::Async::SSL } ) {
      return Future->new->fail( "SSL is set but IO::Async::SSL is not available" );
   }

   $self->{loop}->add( $irc ) if !$irc->loop;
   my $f = $irc->login(
      host    => $host,
      service => $args{port},
      nick    => $nick,
      user    => $args{ident},
      pass    => $args{pass},

      ( $args{SSL} ? (
         extensions => [qw( SSL )],
         SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_NONE(),
      ) : () ),

      local_host => $args{local_host} || $self->{local_host},

      on_login => sub {
         foreach my $target ( values %{ $self->{channels} }, values %{ $self->{users} } ) {
            $target->on_connected;
         }

         $self->set_prop_nick( $nick );

         $self->set_network_status( "" );

         $self->fire_event( "connected" );
      },

      on_error => $args{on_error},
   );

   $self->set_network_status( "connecting" );

   $f->on_fail( sub { $self->set_network_status( "disconnected" ) } );

   return $f;
}

sub connected
{
   my $self = shift;

   # Consider we're "connected" if the underlying IRC object is logged in
   my $irc = $self->{irc};
   return $irc->is_loggedin;
}

# Map mIRC's colours onto an approximation of ANSI terminal
my @irc_colour_map = (
   15, 0, 4, 2,    # white black blue green
   9, 1, 5, 3,     # red [brown=darkred] [purple=darkmagenta] [orange=darkyellow]
   11, 10, 6, 14,  # yellow lightgreen cyan lightcyan
   12, 13, 8, 7    # lightblue [pink=magenta] grey lightgrey
);

sub format_colour
{
   my $self = shift;
   my ( $colcode ) = @_;

   return $colcode if $colcode =~ m/^#[0-9a-f]{6}/i;
   return "#$1$1$2$2$3$3" if $colcode =~ m/^#([0-9a-f])([0-9a-f])([0-9a-f])/i;

   return sprintf( "ansi.col%02d", $irc_colour_map[$1] ) if $colcode =~ m/^(\d\d?)/ and defined $irc_colour_map[$1];

   return undef;
}

sub format_text_tagged
{
   my $self = shift;
   my ( $text ) = @_;

   # IRC [well, technically mIRC but other clients have adopted it] uses Ctrl
   # characters to toggle formatting
   #  ^B = bold
   #  ^U = underline
   #  ^_ = underline
   #  ^R = reverse or italic - we'll use italic
   #  ^V = reverse
   #  ^] = italics
   #  ^O = reset
   #  ^C = colour; followed by a code
   #     ^C      = reset colours
   #     ^Cff    = foreground
   #     ^Cff,bb = background
   #
   # irssi uses the following
   #  ^D$$ = foreground/background, in chr('0'+$colour),
   #  ^Db  = underline
   #  ^Dc  = bold
   #  ^Dd  = reverse or italic - we'll use italic
   #  ^Dg  = reset colours
   #
   # As a side effect we'll also strip all the other Ctrl chars

   # We'll also look for "poor-man's" highlighting
   #   *bold*
   #   _underline_
   #   /italic/

   my $ret = Circle::TaggedString->new();

   my %format;

   while( length $text ) {
      if( $text =~ s/^([\x00-\x1f])// ) {
         my $ctrl = chr(ord($1)+0x40);

         if( $ctrl eq "B" ) {
            $format{b} ? delete $format{b} : ( $format{b} = 1 );
         }
         elsif( $ctrl eq "U" or $ctrl eq "_" ) {
            $format{u} ? delete $format{u} : ( $format{u} = 1 );
         }
         elsif( $ctrl eq "R" or $ctrl eq "]" ) {
            $format{i} ? delete $format{i} : ( $format{i} = 1 );
         }
         elsif( $ctrl eq "V" ) {
            $format{rv} ? delete $format{rv} : ( $format{rv} = 1 );
         }
         elsif( $ctrl eq "O" ) {
            undef %format;
         }
         elsif( $ctrl eq "C" ) {
            my $colourre = qr/#[0-9a-f]{6}|#[0-9a-f]{3}|\d\d?/i;

            if( $text =~ s/^($colourre),($colourre)// ) {
               $format{fg} = $self->format_colour( $1 ) if $self->{use_mirc_colours};
               $format{bg} = $self->format_colour( $2 ) if $self->{use_mirc_colours};
            }
            elsif( $text =~ s/^($colourre)// ) {
               $format{fg} = $self->format_colour( $1 ) if $self->{use_mirc_colours};
            }
            else {
               delete $format{fg};
               delete $format{bg};
            }
         }
         elsif( $ctrl eq "D" ) {
            if( $text =~ s/^b// ) { # underline
               $format{u} ? delete $format{u} : ( $format{u} = 1 );
            }
            elsif( $text =~ s/^c// ) { # bold
               $format{b} ? delete $format{b} : ( $format{b} = 1 );
            }
            elsif( $text =~ s/^d// ) { # revserse/italic
               $format{i} ? delete $format{i} : ( $format{i} = 1 );
            }
            elsif( $text =~ s/^g// ) {
               undef %format
            }
            else {
               $text =~ s/^(.)(.)//;
               my ( $fg, $bg ) = map { ord( $_ ) - ord('0') } ( $1, $2 );
               if( $fg > 0 ) {
                  $format{fg} = sprintf( "ansi.col%02d", $fg );
               }
               if( $bg > 0 ) {
                  $format{bg} = sprintf( "ansi.col%02d", $bg );
               }
            }
         }
         else {
            print STDERR "Unhandled Ctrl code ^$ctrl\n";
         }
      }
      else {
         $text =~ s/^([^\x00-\x1f]+)//;
         my $piece = $1;

         # Now scan this piece for the text-based ones
         while( length $piece ) {
            # Look behind/ahead asserts to ensure we don't capture e.g.
            # /usr/bin/perl by mistake
            if( $piece =~ s/^(.*?)(?<!\w)(([\*_\/])\w+\3)(?!\w)// ) {
               my ( $pre, $inner, $type ) = ( $1, $2, $3 );

               $ret->append_tagged( $pre, %format ) if length $pre;

               my %innerformat = %format;

               $type =~ tr{*_/}{bui};
               $innerformat{$type} = 1;

               $ret->append_tagged( $inner, %innerformat );
            }
            else {
               $ret->append_tagged( $piece, %format );
               $piece = "";
            }
         }
      }
   }

   return $ret;
}

sub format_text
{
   my $self = shift;
   my ( $text ) = @_;

   return $self->format_text_tagged( $text );
}

###
# Rule subs
###

sub parse_cond_matchnick
   : Rule_description("Look for my IRC nick in the text")
   : Rule_format('')
{
   my $self = shift;
   return;
}

sub deparse_cond_matchnick
{
   my $self = shift;
   return;
}

sub eval_cond_matchnick
{
   my $self = shift;
   my ( $event, $results ) = @_;

   my $text = $event->{text}->str;

   my $nick = $self->{irc}->nick;

   pos( $text ) = 0;

   my $matched;

   while( $text =~ m/(\Q$nick\E)/gi ) {
      my ( $start, $end ) = ( $-[0], $+[0] );
      my $len = $end - $start;

      $results->push_result( "matchgroups", [ [ $start, $len ] ] );
      $matched = 1;
   }

   return $matched;
}

sub parse_cond_fromnick
   : Rule_description("Match the message originating nick against a regexp or string")
   : Rule_format('/regexp/ or "literal"')
{
   my $self = shift;
   my ( $spec ) = @_;

   if( $spec =~ m/^"/ ) {
      # Literal
      my $nick = extract_delimited( $spec, q{"} );
      s/^"//, s/"$// for $nick;

      return literal => $nick;
   }
   elsif( $spec =~ m{^/} ) {
      # Regexp
      my $re = extract_delimited( $spec, q{/} );
      s{^/}{}, s{/$}{} for $re;

      my $iflag = 1 if $spec =~ s/^i//;

      return re => qr/$re/i if $iflag;
      return re => qr/$re/;
   }
}

sub deparse_cond_fromnick
{
   my $self = shift;
   my ( $type, $pattern ) = @_;

   if( $type eq "literal" ) {
      return qq{"$pattern"};
   }
   elsif( $type eq "re" ) {
      # Perl tries to put (?-ixsm:RE) around our pattern. Lets attempt to remove
      # it if we can
      return "/$1/"  if $pattern =~ m/^\(\?-xism:(.*)\)$/;
      return "/$1/i" if $pattern =~ m/^\(\?i-xsm:(.*)\)$/;

      # Failed. Lets just be safe then
      return "/$pattern/";
   }
}

sub eval_cond_fromnick
{
   my $self = shift;
   my ( $event, $results, $type, $pattern ) = @_;

   my $src = $event->{prefix_name_folded};

   if( $type eq "literal" ) {
      my $irc = $self->{irc};

      return $src eq $irc->casefold_name( $pattern );
   }
   elsif( $type eq "re" ) {
      return $src =~ $pattern;
   }
}

sub parse_cond_channel
   : Rule_description("Event comes from a (named) channel")
   : Rule_format('"name"?')
{
   my $self = shift;
   my ( $spec ) = @_;

   if( defined $spec and $spec =~ m/^"/ ) {
      my $name = extract_delimited( $spec, q{"} );
      s/^"//, s/"$// for $name;

      return $name;
   }

   return undef;
}

sub deparse_cond_channel
{
   my $self = shift;
   my ( $name ) = @_;

   return qq{"$name"} if defined $name;
   return;
}

sub eval_cond_channel
{
   my $self = shift;
   my ( $event, $results, $name ) = @_;

   return 0 unless ( $event->{target_type} || "" ) eq "channel";

   return 1 unless defined $name;

   my $irc = $self->{irc};
   return $event->{target_name_folded} eq $irc->casefold_name( $name );
}

sub parse_cond_isaction
   : Rule_description("Event is a CTCP ACTION")
   : Rule_format('')
{
   my $self = shift;
   return undef;
}

sub deparse_cond_isaction
{
   my $self = shift;
   return;
}

sub eval_cond_isaction
{
   my $self = shift;
   my ( $event, $results, $name ) = @_;

   return $event->{is_action};
}

sub parse_action_display
   : Rule_description("Set the display window to display an event")
   : Rule_format('self|server')
{
   my $self = shift;
   my ( $spec ) = @_;

   if( $spec eq "self" ) {
      return "self";
   }
   elsif( $spec eq "server" ) {
      return "server";
   }
   else {
      die "Unrecognised display spec\n";
   }
}

sub deparse_action_display
{
   my $self = shift;
   my ( $display ) = @_;

   return $display;
}

sub eval_action_display
{
   my $self = shift;
   my ( $event, $results, $display ) = @_;

   $event->{display} = $display;
}

sub parse_action_chaction
   : Rule_description("Change an event to or from being a CTCP ACTION")
   : Rule_format('0|1')
{
   my $self = shift;
   my ( $spec ) = @_;

   return !!$spec;
}

sub deparse_action_chaction
{
   my $self = shift;
   my ( $action ) = @_;

   return $action;
}

sub eval_action_chaction
{
   my $self = shift;
   my ( $event, $results, $action ) = @_;

   $event->{is_action} = $action;
}

###
# IRC message handlers
###

sub on_message
{
   my $self = shift;
   my ( $command, $message, $hints ) = @_;

   if( defined $hints->{target_name} ) {
      my $target;

      if( $hints->{target_type} eq "channel" ) {
         $target = $self->get_channel_or_create( $hints->{target_name} );
      }
      elsif( $hints->{target_is_me} and 
             defined $hints->{prefix_name} and
             not $hints->{prefix_is_me} ) {
         # Handle PRIVMSG and similar from the user
         $target = $self->get_user_or_create( $hints->{prefix_name} );
      }
      elsif( $hints->{target_type} eq "user" ) {
         # Handle numerics about the user - Net::Async::IRC has filled in the target
         $target = $self->get_user_or_create( $hints->{target_name} );
      }

      if( $target ) {
         return 1 if $target->on_message( $command, $message, $hints );
      }
   }
   elsif( grep { $command eq $_ } qw( NICK QUIT ) ) {
      # Target all of them
      my $handled = 0;

      my $method = "on_message_$command";

      $handled = 1 if $self->can( $method ) and $self->$method( $message, $hints );

      foreach my $target ( values %{ $self->{channels} } ) {
         $handled = 1 if $target->$method( $message, $hints );
      }

      my $nick_folded = $hints->{prefix_nick_folded};

      if( my $userobj = $self->get_user_if_exists( $hints->{prefix_nick} ) ) {
         $handled = 1 if $userobj->$method( $message, $hints );
      }

      return 1 if $handled;
   }
   elsif( $self->can( "on_message_$command" ) ) {
      my $method = "on_message_$command";
      my $handled = $self->$method( $message, $hints );

      return 1 if $handled;
   }

   if( not $hints->{handled} and not $hints->{synthesized} ) {
      $self->push_displayevent( "irc.irc", {
            command => $command,
            prefix  => $message->prefix,
            args    => join( " ", map { "'$_'" } $message->args ),
         } );
      $self->bump_level( 1 );
   }
}

sub on_message_NICK
{
   my $self = shift;
   my ( $message, $hints ) = @_;

   if( $hints->{prefix_is_me} ) {
      $self->set_prop_nick( $hints->{new_nick} );
   }

   return 1;
}

sub on_message_motd
{
   my $self = shift;
   my ( $message, $hints ) = @_;

   my $motd = $hints->{motd};
   $self->push_displayevent( "irc.motd", { text => $self->format_text($_) } ) for @$motd;
   $self->bump_level( 1 );

   return 1;
}

sub on_message_RPL_UNAWAY
{
   my $self = shift;
   my ( $message, $hints ) = @_;

   $self->set_prop_away( 0 );

   $self->push_displayevent( "irc.text", { server => $hints->{prefix_host}, text => $hints->{text} } );
   $self->bump_level( 1 );

   return 1;
}

sub on_message_RPL_NOWAWAY
{
   my $self = shift;
   my ( $message, $hints ) = @_;

   $self->set_prop_away( 1 );

   $self->push_displayevent( "irc.text", { server => $hints->{prefix_host}, text => $hints->{text} } );
   $self->bump_level( 1 );

   return 1;
}

sub on_message_whois
{
   my $self = shift;
   my ( $message, $hints ) = @_;

   my $f = delete $self->{whois_gate_f}{$hints->{target_name_folded}}
      or return 1;

   $f->done( $hints->{whois} );
}

sub on_closed
{
   my $self = shift;
   my ( $message ) = @_;

   $message ||= "Server is disconnected";
   $self->set_network_status( "disconnected" );

   $self->push_displayevent( "status", { text => $message } );

   foreach my $target ( values %{ $self->{channels} }, values %{ $self->{users} } ) {
      $target->on_disconnected( $message );
   }

   $self->fire_event( "disconnected" );

   unless( $self->{no_reconnect_on_close} ) {
      $self->{reconnect_delay_idx} = 0;
      $self->{reconnect_host_idx} = 0;
      $self->enqueue_reconnect if !$self->{reconnect_timer}->is_running;
   }
   undef $self->{no_reconnect_on_close};
}

my @reconnect_delays = ( 5, 5, 10, 30, 60 );
sub enqueue_reconnect
{
   my $self = shift;
   my $delay = $reconnect_delays[ $self->{reconnect_delay_idx}++ ] // $reconnect_delays[-1];

   my $timer = $self->{reconnect_timer};
   $timer->configure( delay => $delay );
   $timer->start;

   $self->set_network_status( "reconnect pending..." );
}

sub reconnect
{
   my $self = shift;

   my $s = $self->{servers}->[ $self->{reconnect_host_idx}++ ];
   $self->{reconnect_host_idx} %= @{ $self->{servers} };

   my $f = $self->connect(
      host => $s->{host},
      port => $s->{port},
      user => $s->{user},
      pass => $s->{pass},
      SSL  => $s->{SSL},
   );

   $f->on_fail( sub { $self->enqueue_reconnect } );
}

sub on_ping_timeout
{
   my $self = shift;

   $self->on_closed( "Ping timeout" );
   $self->{irc}->close;
}

sub on_ping_reply
{
   my $self = shift;
   my ( $lag ) = @_;

   if( $lag > 1 ) {
      $self->set_network_status( sprintf "lag:%.2f", $lag );
   }
   else {
      $self->set_network_status( "" );
   }
}

sub method_get_isupport
{
   my $self = shift;
   my ( $ctx, $key ) = @_;

   my $irc = $self->{irc};
   return $irc->isupport( $key );
}

sub do_join
{
   my $self = shift;
   my ( $channel, $key ) = @_;

   my $pending = $self->{pending_joins} //= [];

   if( !@$pending ) {
      my $irc = $self->{irc};
      $self->{loop}->later( sub {
         my $channels = join ",", map { $_->[0] } @$pending;
         my $keys     = join ",", map { defined $_->[1] ? ( $_->[1] ) : () } @$pending;

         $irc->send_message( "JOIN", undef, $channels, length $keys ? ( $keys ) : () );

         @$pending = ();
      });
   }

   # Enqueue keyed joins first, others last
   if( defined $key ) {
      unshift @$pending, [ $channel, $key ];
   }
   else {
      push @$pending, [ $channel ];
   }
}

use Circle::Collection
   name  => 'servers',
   storage => 'array',
   attrs => [
      host  => { desc => "hostname" },
      port  => { desc => "alternative port",
                 show => sub { $_ || "6667" },
               },
      SSL   => { desc => "use SSL",
                 show => sub { $_ ? "SSL" : "" },
               },
      ident => { desc => "alternative ident",
                 show => sub { $_ || '$USER' },
               },
      pass  => { desc => "connection password",
                 show => sub { $_ ? "set" : "" },
               },
   ],
   ;

sub command_nick
   : Command_description("Change nick")
   : Command_arg('nick?')
{
   my $self = shift;
   my ( $newnick ) = @_;

   my $irc = $self->{irc};

   if( defined $newnick ) {
      $irc->change_nick( $newnick );
      $self->set_prop_nick( $newnick );
   }

   return;
}

sub command_connect
   : Command_description("Connect to an IRC server")
   : Command_arg('host?')
   : Command_opt('port=$',  desc => "alternative port (default '6667')")
   : Command_opt('SSL=+',   desc => "use SSL")
   : Command_opt('nick=$',  desc => "initial nick")
   : Command_opt('ident=$', desc => "alternative ident (default '\$USER')")
   : Command_opt('pass=$',  desc => "connection password")
   : Command_opt('local_host=$', desc => "local host to bind")
{
   my $self = shift;
   my ( $host, $opts, $cinv ) = @_;

   my $s;

   if( !defined $host ) {
      if( !@{ $self->{servers} } ) {
         $cinv->responderr( "Cannot connect - no servers defined" );
         return;
      }

      # TODO: Pick one - for now just the first
      $s = $self->{servers}->[0];

      $host = $s->{host};
   }
   else {
      ( $s ) = grep { $_->{host} eq $host } @{ $self->{servers} };
      $s or return $cinv->responderr( "No definition for $host" );
   }

   $self->{reconnect_timer}->stop;

   my $f = $self->connect(
      host  => $host,
      nick  => $opts->{nick},
      port  => $opts->{port}  || $s->{port},
      SSL   => $opts->{SSL}   || $s->{SSL},
      ident => $opts->{ident} || $s->{ident},
      pass  => $opts->{pass}  || $s->{pass},
      local_host => $opts->{local_host},
      on_error => sub { warn "Empty closure" },
   );

   $f->on_done( sub { $cinv->respond( "Connected to $host", level => 1 ) } );
   $f->on_fail( sub { $cinv->responderr( "Unable to connect to $host - $_[0]", level => 3 ) } );

   return ( "Connecting to $host ..." );
}

sub command_reconnect
   : Command_description("Disconnect then reconnect to the IRC server")
   : Command_arg('message', eatall => 1)
{
   my $self = shift;
   my ( $message ) = @_;

   my $irc = $self->{irc};

   $irc->send_message( "QUIT", undef, $message );

   $irc->close;

   $self->{no_reconnect_on_close} = 1;

   $self->reconnect
      ->on_done( sub { undef $self->{no_reconnect_on_close} });

   return;
}

sub command_disconnect
   : Command_description("Disconnect from the IRC server")
   : Command_arg('message?', eatall => 1)
{
   my $self = shift;
   my ( $message ) = @_;

   my $irc = $self->{irc};

   if( $irc->read_handle ) {
      $irc->send_message( "QUIT", undef, defined $message ? ( $message ) : () );
      $irc->close;

      $self->{no_reconnect_on_close} = 1;
   }
   else {
      my $timer = $self->{reconnect_timer};
      $timer->stop if $timer->is_running;
      $self->set_network_status( "disconnected" );
   }

   return;
}

sub command_join
   : Command_description("Join a channel")
   : Command_arg('channel')
   : Command_opt('key=$', desc => "join key")
{
   my $self = shift;
   my ( $channel, $opts, $cinv ) = @_;

   my $irc = $self->{irc};

   my $chanobj = $self->get_channel_or_create( $channel );

   $chanobj->reify;

   $chanobj->join(
      key => $opts->{key},
      on_joined => sub {
         $cinv->respond( "Joined $channel", level => 1 );
      },
      on_join_error => sub {
         $cinv->responderr( "Cannot join $channel - $_[0]", level => 3 );
      },
   );

   return;
}

sub command_part
   : Command_description("Part a channel")
   : Command_arg('channel')
   : Command_arg('message?', eatall => 1)
{
   my $self = shift;
   my ( $channel, $message, $cinv ) = @_;

   my $chanobj = $self->get_channel_if_exists( $channel )
      or return "No such channel $channel";

   $chanobj->part(
      message => $message,

      on_parted => sub {
         $cinv->respond( "Parted $channel", level => 1 );
         $chanobj->destroy;
      },
      on_part_error => sub {
         $cinv->respond( "Cannot part $channel - $_[0]", level => 3 );
      },
   );

   return;
}

sub command_query
   : Command_description("Open a private message window to a user")
   : Command_arg('nick')
{
   my $self = shift;
   my ( $nick, $cinv ) = @_;

   my $userobj = $self->get_user_or_create( $nick );

   $userobj->reify;

   # TODO: Focus it

   return;
}

sub command_msg
   : Command_description("Send a PRIVMSG to a target")
   : Command_arg('target')
   : Command_arg('text', eatall => 1)
{
   my $self = shift;
   my ( $target, $text ) = @_;

   if( my $targetobj = $self->get_target_if_exists( $target ) ) {
      $targetobj->msg( $text );
   }
   else {
      my $irc = $self->{irc};
      $irc->send_message( "PRIVMSG", undef, $target, $text );
   }

   return;
}

sub command_notice
   : Command_description("Send a NOTICE to a target")
   : Command_arg('target')
   : Command_arg('text', eatall => 1)
{
   my $self = shift;
   my ( $target, $text ) = @_;

   if( my $targetobj = $self->get_target_if_exists( $target ) ) {
      $targetobj->notice( $text );
   }
   else {
      my $irc = $self->{irc};
      $irc->send_message( "NOTICE", undef, $target, $text );
   }

   return;
}

sub command_quote
   : Command_description("Send a raw IRC command")
   : Command_arg('cmd')
   : Command_arg('args', collect => 1)
{
   my $self = shift;
   my ( $cmd, $args ) = @_;

   my $irc = $self->{irc};

   $irc->send_message( $cmd, undef, @$args );

   return;
}

sub command_away
   : Command_description("Set AWAY message")
   : Command_arg('message', eatall => 1)
{
   my $self = shift;
   my ( $message ) = @_;

   my $irc = $self->{irc};

   length $message or $message = "away";

   $irc->send_message( "AWAY", undef, $message );

   return;
}

sub command_unaway
   : Command_description("Remove AWAY message")
{
   my $self = shift;

   my $irc = $self->{irc};

   $irc->send_message( "AWAY", undef );

   return;
}

sub command_whois
   : Command_description("Send a WHOIS query")
   : Command_arg('user')
{
   my $self = shift;
   my ( $user, $cinv ) = @_;

   my $irc = $self->{irc};
   my $user_folded = $irc->casefold_name( $user );

   $irc->send_message( "WHOIS", undef, $user );

   my $f = ( $self->{whois_gate_f}{$user_folded} ||= Future->new );
   $f->on_done( sub {
      my ( $data ) = @_;

      $cinv->respond( "WHOIS $user:" );
      foreach my $datum ( @$data ) {
         my %d = %$datum;
         my $whois = delete $d{whois};

         $cinv->respond( " $whois - " . join( " ",
            map { my $val = $d{$_};
                  # 'channels' comes as an ARRAY
                  ref($val) eq "ARRAY" ? "$_=@{$d{$_}}" : "$_=$d{$_}"
                } sort keys %d
         ) );
      }
   });
   $f->on_fail( sub {
      my ( $failure ) = @_;
      $cinv->responderr( "Cannot WHOIS $user - $failure" );
   });

   return ();
}

use Circle::Collection
   name => 'channels',
   storage => 'methods',
   attrs => [
      name     => { desc => "name" },
      autojoin => { desc => "JOIN automatically when connected",
                    show => sub { $_ ? "yes" : "no" },
                  },
      key      => { desc => "join key" },
   ],
   ;

sub channels_list
{
   my $self = shift;
   return map { $self->channels_get( $_ ) } sort keys %{ $self->{channels} };
}

sub channels_get
{
   my $self = shift;
   my ( $name ) = @_;

   my $chan = $self->get_channel_if_exists( $name ) or return undef;

   return {
      name     => $chan->get_prop_name,
      ( map { $_ => $chan->{$_} } qw( autojoin key ) ),
   };
}

sub channels_set
{
   my $self = shift;
   my ( $name, $def ) = @_;

   my $chanobj = $self->get_channel_if_exists( $name ) or die "Missing channel $name for channels_set";

   foreach (qw( autojoin key )) {
      $chanobj->{$_} = $def->{$_} if exists $def->{$_};
   }
}

sub channels_add
{
   my $self = shift;
   my ( $name, $def ) = @_;

   my $chanobj = $self->get_channel_or_create( $name );

   $chanobj->reify;

   foreach (qw( autojoin key )) {
      $chanobj->{$_} = $def->{$_} if exists $def->{$_};
   }
}

sub channels_del
{
   my $self = shift;
   my ( $name, $def ) = @_;

   my $chanobj = $self->get_channel_if_exists( $name ) or return undef;

   $chanobj->destroy;
}

sub commandable_parent
{
   my $self = shift;
   return $self->{root};
}

sub enumerable_name
{
   my $self = shift;
   return $self->get_prop_tag;
}

sub parent
{
   my $self = shift;
   return $self->{root};
}

sub enumerate_items
{
   my $self = shift;

   my %all = ( %{ $self->{channels} }, %{ $self->{users} } );

   # Filter only the real ones
   $all{$_}->get_prop_real or delete $all{$_} for keys %all;

   return { map { $_->enumerable_name => $_ } values %all };
}

sub get_item
{
   my $self = shift;
   my ( $name, $create ) = @_;

   foreach my $items ( $self->{channels}, $self->{users} ) {
      return $items->{$name} if exists $items->{$name} and $items->{$name}->get_prop_real;
   }

   return $self->get_target_or_create( $name ) if $create;

   return undef;
}

__PACKAGE__->APPLY_Setting( local_host =>
   description => "Local bind address",
   type        => 'str',
);

__PACKAGE__->APPLY_Setting( nick =>
   description => "Initial connection nick",
   type        => 'str',
   storage     => 'configured_nick',
);

__PACKAGE__->APPLY_Setting( use_mirc_colours =>
   description => "Use mIRC colouring information",
   type        => 'bool',
   default     => 1,
);

###
# Widgets
###

sub get_widget_statusbar
{
   my $self = shift;

   my $registry = $self->{registry};

   my $statusbar = $registry->construct(
      "Circle::Widget::Box",
      classes => [qw( status )],
      orientation => "horizontal",
   );

   $statusbar->add( $self->get_widget_netname );

   my $nicklabel = $registry->construct(
      "Circle::Widget::Label",
      classes => [qw( nick )],
   );
   $self->watch_property( "nick",
      on_updated => sub { $nicklabel->set_prop_text( $_[1] ) }
   );

   $statusbar->add( $nicklabel );

   my $awaylabel = $registry->construct(
      "Circle::Widget::Label",
      classes => [qw( away )],
   );
   $self->watch_property( "away",
      on_updated => sub { $awaylabel->set_prop_text( $_[1] ? "[AWAY]" : "" ) }
   );

   $statusbar->add( $awaylabel );

   return $statusbar;
}

sub get_widget_channel_completegroup
{
   my $self = shift;

   return $self->{widget_channel_completegroup} ||= do {
      my $registry = $self->{registry};

      my $widget = $registry->construct(
         "Circle::Widget::Entry::CompleteGroup",
      );

      # Have to cache id->name so we can delete properly
      # TODO: Consider fixing on_del
      my %id_to_name;
      $self->watch_property( "channels",
         on_set => sub {
            my ( undef, $channels ) = @_;
            $widget->set( map { $id_to_name{$_->id} = $_->name } values %$channels );
         },
         on_add => sub {
            my ( undef, $added ) = @_;
            $widget->add( $id_to_name{$added->id} = $added->name );
         },
         on_del => sub {
            my ( undef, $deleted_id ) = @_;
            $widget->remove( delete $id_to_name{$deleted_id} );
         },
      );

      $widget->set( keys %{ $self->{channels} } );

      $widget;
   };
}

sub add_entry_widget_completegroups
{
   my $self = shift;
   my ( $entry ) = @_;

   $entry->add_prop_completions( $self->get_widget_channel_completegroup );
}

sub get_widget_commandentry
{
   my $self = shift;
   my $widget = $self->SUPER::get_widget_commandentry;

   $self->add_entry_widget_completegroups( $widget );

   return $widget;
}

0x55AA;
