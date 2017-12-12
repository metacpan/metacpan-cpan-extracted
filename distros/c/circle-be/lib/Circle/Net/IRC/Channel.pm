#  You may distribute under the terms of the GNU General Public License
#
#  (C) Paul Evans, 2008-2017 -- leonerd@leonerd.org.uk

package Circle::Net::IRC::Channel;

use strict;
use warnings;
use 5.010; # //
use base qw( Circle::Net::IRC::Target );

our $VERSION = '0.173320';

use Carp;

use Circle::TaggedString;

use Circle::Widget::Box;
use Circle::Widget::Entry;
use Circle::Widget::Label;

use POSIX qw( strftime );

sub init_prop_occupant_summary
{
   return { total => 0 };
}

sub on_connected
{
   my $self = shift;
   $self->SUPER::on_connected;

   if( $self->{autojoin} ) {
      $self->join( on_joined => sub { } );
   }
}

sub join
{
   my $self = shift;
   my %args = @_;

   my $on_joined = $args{on_joined};
   ref $on_joined eq "CODE" or croak "Expected 'on_joined' as CODE ref";

   my $key = $args{key} // $self->{key};

   my $net = $self->{net};
   $net->do_join( $self->get_prop_name, $key );

   $self->{on_joined} = $on_joined;
   $self->{on_join_error} = $args{on_join_error};
}

sub invite
{
   my $self = shift;
   my ( $nick ) = @_;

   my $irc = $self->{irc};
   # INVITE user #channel
   $irc->send_message( "INVITE", undef, $nick, $self->get_prop_name );
}

sub kick
{
   my $self = shift;
   my ( $nick, $message ) = @_;

   my $irc = $self->{irc};
   $irc->send_message( "KICK", undef, $self->get_prop_name, $nick, $message );
}

sub mode
{
   my $self = shift;
   my ( $modestr, @args ) = @_;

   my $irc = $self->{irc};
   $irc->send_message( "MODE", undef, $self->get_prop_name, $modestr, @args );
}

sub method_mode
{
   my $self = shift; my $ctx = shift;
   my ( $modestr, $argsarray ) = @_;
   $self->mode( $modestr, @$argsarray );
}

sub part
{
   my $self = shift;
   my %args = @_;

   my $on_parted = $args{on_parted};
   ref $on_parted eq "CODE" or croak "Expected 'on_parted' as CODE ref";

   my $irc = $self->{irc};
   $irc->send_message( "PART", undef, $self->get_prop_name, defined $args{message} ? $args{message} : ( "" ) );

   $self->{on_parted} = $on_parted;
}

sub topic
{
   my $self = shift;
   my ( $topic ) = @_;

   my $irc = $self->{irc};
   $irc->send_message( "TOPIC", undef, $self->get_prop_name, $topic );
}

sub method_topic
{
   my $self = shift; my $ctx = shift;
   $self->topic( @_ );
}

sub user_leave
{
   my $self = shift;
   my ( $nick_folded ) = @_;

   $self->del_prop_occupants( $nick_folded );
   $self->post_update_occupants;
}

sub gen_modestr
{
   my $self = shift;

   # This is a dynamic property

   my $mode = $self->get_prop_mode;

   # Order the mode as the server declares

   my $irc = $self->{irc};
   my $channelmodes = $irc->server_info( "channelmodes" );

   my @modes = sort { index( $channelmodes, $a ) <=> index( $channelmodes, $b ) } keys %$mode;

   my $str = "+";
   my @args;

   foreach my $modechar ( @modes ) {
      $str .= $modechar;
      push @args, $mode->{$modechar} if length $mode->{$modechar};
   }

   return CORE::join( " ", $str, @args );
}

sub apply_modes
{
   my $self = shift;
   my ( $modes ) = @_;

   my @mode_added;
   my @mode_deleted;

   my $irc = $self->{irc};
   my $PREFIX_FLAGS = $irc->isupport( "prefix_flags" );

   foreach my $m ( @$modes ) {
      my ( $type, $sense, $mode ) = @{$m}{qw( type sense mode )};

      my $pm = $sense > 0 ? "+" :
               $sense < 0 ? "-" :
                            "";

      if( !defined $type ) {
         print STDERR "TODO: Undefined type for chanmode $mode\n";
      }
      elsif( $type eq 'list' ) {
         print STDERR "TODO: A list chanmode $pm$mode $m->{value}\n";
      }
      elsif( $type eq 'occupant' ) {
         my $flag = $m->{flag};
         my $nick_folded = $m->{nick_folded};

         my $occupant = $self->get_prop_occupants->{$nick_folded};

         if( $sense > 0 ) {
            my $flags = $occupant->{flag} . $flag;
            # Now sort by PREFIX_FLAGS order
            $flags = CORE::join( "", sort { index( $PREFIX_FLAGS, $a ) <=> index( $PREFIX_FLAGS, $b ) } split( m//, $flags ) );
            $occupant->{flag} = $flags;
         }
         else {
            $occupant->{flag} =~ s/\Q$flag//g;
         }

         # We're not adding it, we're changing it
         $self->add_prop_occupants( $nick_folded => $occupant );
         $self->post_update_occupants;
      }
      elsif( $type eq 'value' ) {
         if( $sense > 0 ) {
            push @mode_added, [ $mode, $m->{value} ];
         }
         else {
            push @mode_deleted, $mode;
         }
      }
      elsif( $type eq 'bool' ) {
         if( $sense > 0 ) {
            push @mode_added, [ $mode, "" ];
         }
         else {
            push @mode_deleted, $mode;
         }
      }
   }

   if( @mode_added ) {
      # TODO: Allow CHANGE_ADD messages to add multiple key/value pairs
      foreach my $m ( @mode_added ) {
         $self->add_prop_mode( $m->[0] => $m->[1] );
      }
   }

   if( @mode_deleted ) {
      $self->del_prop_mode( $_ ) for @mode_deleted;
   }

   if( @mode_added or @mode_deleted or !defined $self->get_prop_modestr ) {
      $self->set_prop_modestr( $self->gen_modestr );
   }
}

sub post_update_occupants
{
   my $self = shift;

   my $irc = $self->{irc};

   my %count = map { $_ => 0 } "total", "", split( m//, $irc->isupport( "prefix_flags" ) );

   my $myflag;

   foreach my $occ ( values %{ $self->get_prop_occupants } ) {
      unless( defined $occ->{nick} ) {
         warn "Have an undefined nick in $occ in $self\n";
         next;
      }
      unless( defined $occ->{flag} ) {
         warn "Have an undefined flag for nick $occ->{nick} in $occ in $self\n";
         next;
      }

      my $flag = $occ->{flag} =~ m/^(.)/ ? $1 : "";

      $count{total}++;
      $count{$flag}++;

      $myflag = $flag if $irc->is_nick_me( $occ->{nick} );
   }

   $self->set_prop_occupant_summary( \%count );

   # Efficient application of property change
   my $old_myflag = $self->get_prop_my_flag;

   $self->set_prop_my_flag( $myflag ) if !defined $old_myflag or $old_myflag ne $myflag;
}

sub on_message_JOIN
{
   my $self = shift;
   my ( $message, $hints ) = @_;

   my $nick = $hints->{prefix_nick};

   my $userhost = "$hints->{prefix_user}\@$hints->{prefix_host}";

   if( $hints->{prefix_is_me} ) {
      $self->{on_joined}->( $self );

      $self->fire_event( "self_joined" );
      $self->push_displayevent( "irc.join", { channel => $self->get_prop_name, nick => $nick, userhost => $userhost } );
      $self->bump_level( 1 );

      # Request the initial mode
      my $irc = $self->{irc};
      $irc->send_message( "MODE", undef, $self->get_prop_name );
   }
   else {
      $self->fire_event( "join", $nick );
      $self->push_displayevent( "irc.join", { channel => $self->get_prop_name, nick => $nick, userhost => $userhost } );
      $self->bump_level( 1 );

      my $nick_folded = $hints->{prefix_nick_folded};
      my $newocc = { nick => $nick, flag => "" };

      $self->add_prop_occupants( $nick_folded => $newocc );
      $self->post_update_occupants;
   }

   return 1;
}

sub on_message_KICK
{
   my $self = shift;
   my ( $message, $hints ) = @_;

   my $kicker  = $hints->{kicker_nick};
   my $kicked  = $hints->{kicked_nick};
   my $kickmsg = $hints->{text};

   defined $kickmsg or $kickmsg = "";

   my $net = $self->{net};
   my $kickmsg_formatted = $net->format_text( $kickmsg );

   my $irc = $self->{irc};
   if( $irc->is_nick_me( $kicked ) ) {
      $self->fire_event( "self_parted" );
      $self->push_displayevent( "irc.kick", { channel => $self->get_prop_name, kicker => $kicker, kicked => $kicked, kickmsg => $kickmsg_formatted } );
      $self->bump_level( 1 );
   }
   else {
      $self->fire_event( "kick", $kicker, $kicked, $kickmsg );
      $self->push_displayevent( "irc.kick", { channel => $self->get_prop_name, kicker => $kicker, kicked => $kicked, kickmsg => $kickmsg_formatted } );
      $self->bump_level( 1 );

      $self->user_leave( $hints->{kicked_nick_folded} );
   }

   return 1;
}

sub on_message_MODE
{
   my $self = shift;
   my ( $message, $hints ) = @_;

   my $modes = $hints->{modes};

   my $nick;
   my $userhost;

   if( defined $hints->{prefix_nick} ) {
      $nick     = $hints->{prefix_nick};
      $userhost = "$hints->{prefix_user}\@$hints->{prefix_host}";
   }
   else {
      $nick = $userhost = $hints->{prefix_host};
   }

   $self->apply_modes( $hints->{modes} );

   my $modestr = CORE::join( " ", $hints->{modechars}, @{ $hints->{modeargs} } );

   # 'nick' for legacy purposes, 'moder' for new
   $self->push_displayevent( "irc.mode", {
      channel  => $self->get_prop_name, 
      nick     => $nick, moder => $nick,
      userhost => $userhost,
      mode     => $modestr,
   } );
   $self->bump_level( 1 );

   return 1;
}

sub on_message_NICK
{
   my $self = shift;
   my ( $message, $hints ) = @_;

   my $oldnick_folded = $hints->{old_nick_folded};

   return 0 unless my $occ = $self->get_prop_occupants->{$oldnick_folded};

   my $oldnick = $hints->{old_nick};
   my $newnick = $hints->{new_nick};

   $self->push_displayevent( "irc.nick", { channel => $self->get_prop_name, oldnick => $oldnick, newnick => $newnick } );
   $self->bump_level( 1 );

   my $newnick_folded = $hints->{new_nick_folded};

   $self->del_prop_occupants( $oldnick_folded );

   $occ->{nick} = $newnick;
   $self->add_prop_occupants( $newnick_folded => $occ );

   $self->post_update_occupants;

   return 1;
}

sub on_message_PART
{
   my $self = shift;
   my ( $message, $hints ) = @_;

   my $nick    = $hints->{prefix_nick};
   my $partmsg = $hints->{text};

   defined $partmsg or $partmsg = "";

   my $net = $self->{net};
   my $partmsg_formatted = $net->format_text( $partmsg );

   my $userhost = "$hints->{prefix_user}\@$hints->{prefix_host}";

   if( $hints->{prefix_is_me} ) {
      $self->fire_event( "self_parted" );
      $self->push_displayevent( "irc.part", { channel => $self->get_prop_name, nick => $nick, userhost => $userhost, partmsg => $partmsg_formatted } );
      $self->bump_level( 1 );

      $self->{on_parted}->( $self );
   }
   else {
      $self->fire_event( "part", $nick, $partmsg );
      $self->push_displayevent( "irc.part", { channel => $self->get_prop_name, nick => $nick, userhost => $userhost, partmsg => $partmsg_formatted } );
      $self->bump_level( 1 );

      $self->user_leave( $hints->{prefix_nick_folded} );
   }

   return 1;
}

sub on_message_QUIT
{
   my $self = shift;
   my ( $message, $hints ) = @_;

   my $nick_folded = $hints->{prefix_nick_folded};

   return 0 unless $self->get_prop_occupants->{$nick_folded};

   my $nick    = $hints->{prefix_nick};
   my $quitmsg = $hints->{text};

   defined $quitmsg or $quitmsg = "";

   my $net = $self->{net};
   my $quitmsg_formatted = $net->format_text( $quitmsg );

   my $userhost = "$hints->{prefix_user}\@$hints->{prefix_host}";

   $self->push_displayevent( "irc.quit", { channel => $self->get_prop_name, nick => $nick, userhost => $userhost, quitmsg => $quitmsg_formatted } );
   $self->bump_level( 1 );

   $self->user_leave( $nick_folded );

   return 1;
}

sub on_message_TOPIC
{
   my $self = shift;
   my ( $message, $hints ) = @_;

   my $topic = $hints->{text};

   $self->set_prop_topic( $topic );

   my $nick = $hints->{prefix_name};

   my $userhost = "$hints->{prefix_user}\@$hints->{prefix_host}";

   $self->fire_event( "topic", $nick, $topic );
   $self->push_displayevent( "irc.topic", { channel => $self->get_prop_name, nick => $nick, userhost => $userhost, topic => $topic } );
   $self->bump_level( 1 );

   return 1;
}

sub on_message_RPL_CHANNELMODEIS
{
   my $self = shift;
   my ( $message, $hints ) = @_;

   $self->apply_modes( $hints->{modes} );

   my $modestr = CORE::join( " ", $hints->{modechars}, @{ $hints->{modeargs} } );

   $self->push_displayevent( "irc.mode_is", { channel => $self->get_prop_name, mode => $modestr } );
   $self->bump_level( 1 );

   return 1;
}

sub on_message_RPL_NOTOPIC
{
   my $self = shift;
   my ( $message, $hints ) = @_;

   $self->set_prop_topic( "" );

   return 1;
}

sub on_message_RPL_TOPIC
{
   my $self = shift;
   my ( $message, $hints ) = @_;

   my $topic = $hints->{text};

   $self->set_prop_topic( $topic );

   $self->fire_event( "topic", undef, $topic );
   $self->push_displayevent( "irc.topic_is", { channel => $self->get_prop_name, topic => $topic } );
   $self->bump_level( 1 );

   return 1;
}

sub on_message_RPL_TOPICWHOTIME
{
   my $self = shift;
   my ( $message, $hints ) = @_;

   my $timestr = strftime "%Y/%m/%d %H:%M:%S", localtime $hints->{timestamp};

   $self->push_displayevent( "irc.topic_by", { channel => $self->get_prop_name, topic_by => $hints->{topic_nick}, timestamp => $timestr } );
   $self->bump_level( 1 );

   return 1;
}

sub on_message_RPL_CHANNEL_URL
{
   my $self = shift;
   my ( $message, $hints ) = @_;

   $self->push_displayevent( "irc.text", { server => $hints->{prefix_host}, text => "URL: $hints->{text}" } );
   $self->bump_level( 1 );

   return 1;
}

sub on_message_RPL_CHANNELCREATED
{
   my $self = shift;
   my ( $message, $hints ) = @_;

   my $timestr = strftime "%Y/%m/%d %H:%M:%S", localtime $hints->{timestamp};

   $self->push_displayevent( "irc.text", { server => $hints->{prefix_host}, text => "Channel created $timestr" } );
   $self->bump_level( 1 );

   return 1;
}

sub on_message_names
{
   my $self = shift;
   my ( $message, $hints ) = @_;

   $self->set_prop_occupants( $hints->{names} );
   $self->post_update_occupants;

   return 1;
}

sub command_part
   : Command_description("Part the channel")
   : Command_arg('message?', eatall => 1)
{
   my $self = shift;
   my ( $message, $cinv ) = @_;

   $self->part(
      message => $message,

      on_parted => sub {
         $cinv->respond( "Parted", level => 1 );
         $self->destroy;
      },
      on_part_error => sub {
         $cinv->responderr( "Cannot part - $_[0]", level => 3 );
      },
   );

   return;
}

sub command_mode
   : Command_description("Change a MODE")
   : Command_arg('mode')
   : Command_arg('args', collect => 1)
{
   my $self = shift;
   my ( $mode, $args ) = @_;

   $self->mode( $mode, @$args );

   return;
}

sub command_topic
   : Command_description("Change the TOPIC")
   : Command_arg('topic?', eatall => 1)
{
   my $self = shift;
   my ( $topic ) = @_;

   if( length $topic ) {
      $self->topic( $topic );
   }
   else {
      $self->push_displayevent( "irc.topic_is", { channel => $self->get_prop_name, topic => $self->get_prop_topic } );
   }

   return;
}

sub command_names
   : Command_description("Print a list of users in the channel")
   : Command_opt('flat=+', desc => "all types of users in one flat list")
{
   my $self = shift;
   my ( $opts, $cinv ) = @_;

   my $occ = $self->get_prop_occupants;

   if( $opts->{flat} ) {
      my @names = map { "$occ->{$_}{flag}$occ->{$_}{nick}" } sort keys %$occ;

      $cinv->respond( "Names: " . CORE::join( " ", @names ) );
      return;
   }

   # Split into groups per flag
   my %occgroups;
   for my $nick_folded ( keys %$occ ) {
      my $flag = substr( $occ->{$nick_folded}{flag}, 0, 1 ); # In case user has several
      push @{ $occgroups{ $flag } }, $nick_folded;
   }

   # TODO: Ought to obtain this from somewhere - NaIRC maybe?
   my %flag_to_desc = (
      '~' => "Founder",
      '&' => "Admin",
      '@' => "Operator",
      '%' => "Halfop",
      '+' => "Voice",
      ''  => "User",
   );

   my $irc = $self->{irc};
   foreach my $flag ( sort { $irc->cmp_prefix_flags( $b, $a ) } keys %occgroups ) {
      my @names = map { "$flag$occ->{$_}{nick}" } sort @{ $occgroups{$flag} };

      my $text = Circle::TaggedString->new( $flag_to_desc{$flag} . ": " );
      $text->append_tagged( CORE::join( " ", @names ), indent => 1 );

      $cinv->respond( $text );
   }

   return;
}

sub command_op
   : Command_description("Give channel operator status to users")
   : Command_arg('users', collect => 1)
{
   my $self = shift;
   my ( $users ) = @_;

   my @users = @$users;
   $self->mode( "+".("o"x@users), @users );

   return;
}

sub command_deop
   : Command_description("Remove channel operator status from users")
   : Command_arg('users', collect => 1)
{
   my $self = shift;
   my ( $users ) = @_;

   my @users = @$users;
   $self->mode( "-".("o"x@users), @users );

   return;
}

sub command_halfop
   : Command_description("Give channel half-operator status to users")
   : Command_arg('users', collect => 1)
{
   my $self = shift;
   my ( $users ) = @_;

   my @users = @$users;
   $self->mode( "+".("h"x@users), @users );

   return;
}

sub command_dehalfop
   : Command_description("Remove channel half-operator status from users")
   : Command_arg('users', collect => 1)
{
   my $self = shift;
   my ( $users ) = @_;

   my @users = @$users;
   $self->mode( "-".("h"x@users), @users );

   return;
}

sub command_voice
   : Command_description("Give channel voice status to users")
   : Command_arg('users', collect => 1)
{
   my $self = shift;
   my ( $users ) = @_;

   my @users = @$users;
   $self->mode( "+".("v"x@users), @users );

   return;
}

sub command_devoice
   : Command_description("Remove channel voice status from users")
   : Command_arg('users', collect => 1)
{
   my $self = shift;
   my ( $users ) = @_;

   my @users = @$users;
   $self->mode( "-".("v"x@users), @users );

   return;
}

sub command_invite
   : Command_description("Invite a new user to the channel")
   : Command_arg('user')
{
   my $self = shift;
   my ( $nick ) = @_;

   $self->invite( $nick );

   return;
}

sub command_kick
   : Command_description("Kick a user from the channel")
   : Command_arg('user')
   : Command_arg('message?', eatall => 1 )
{
   my $self = shift;
   my ( $nick, $message ) = @_;

   $message = "" if !defined $message;

   $self->kick( $nick, $message );

   return;
}

### 
# Widget tree
###

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

   my $nicklabel = $registry->construct(
      "Circle::Widget::Label",
      classes => [qw( nick )],
   );

   # TODO: This is hideous...
   my $nick = $net->get_prop_nick || $net->{configured_nick};
   my $my_flag = "";
   my $updatenicklabel = sub { $nicklabel->set_prop_text( $my_flag . $nick ) };
   $net->watch_property( "nick",
      on_set => sub { $nick = $_[1]; goto &$updatenicklabel }
   );
   $self->watch_property( "my_flag",
      on_set => sub { $my_flag = $_[1]; goto &$updatenicklabel }
   );
   $updatenicklabel->();

   $statusbar->add( $nicklabel );

   my $modestrlabel = $registry->construct(
      "Circle::Widget::Label",
      classes => [qw( mode )],
   );
   $self->watch_property( "modestr",
      on_updated => sub { $modestrlabel->set_prop_text( $_[1] || "" ) }
   );

   $statusbar->add( $modestrlabel );

   $statusbar->add_spacer( expand => 1 );

   my $countlabel = $registry->construct(
      "Circle::Widget::Label",
      classes => [qw( occupants )],
   );
   $self->watch_property( "occupant_summary",
      on_updated => sub {
         my ( $self, $summary ) = @_;

         my $irc = $self->{irc};
         my $PREFIX_FLAGS = $irc->isupport( "prefix_flags" ) || "";

         my $str = "$summary->{total} users [" .
             CORE::join( " ", map { "$_$summary->{$_}" } grep { $summary->{$_}||0 > 0 } split( m//, $PREFIX_FLAGS ), "" ) .
             "]";

         $countlabel->set_prop_text( $str );
      }
   );

   $statusbar->add( $countlabel );

   return $statusbar;
}

sub get_widget_occupants_completegroup
{
   my $self = shift;

   return $self->{widget_occupants_completegroup} ||= do {
      my $registry = $self->{registry};

      my $widget = $registry->construct(
         "Circle::Widget::Entry::CompleteGroup",
         suffix_sol => ": ",
      );

      my %key_to_nick;
      $self->watch_property( "occupants",
         on_set => sub {
            my ( undef, $occupants ) = @_;
            $widget->set( map { $key_to_nick{$_} = $occupants->{$_}{nick} } keys %$occupants );
         },
         on_add => sub {
            my ( undef, $key, $occ ) = @_;
            $widget->add( $key_to_nick{$key} = $occ->{nick} );
         },
         on_del => sub {
            my ( undef, $key ) = @_;
            $widget->remove( delete $key_to_nick{$key} );
         },
      );

      my $occupants = $self->get_prop_occupants;
      $widget->set( map { $key_to_nick{$_} = $occupants->{$_}{nick} } keys %$occupants );

      $widget;
   };
}

sub get_widget_commandentry
{
   my $self = shift;
   my $widget = $self->SUPER::get_widget_commandentry;

   $widget->add_prop_completions( $self->get_widget_occupants_completegroup );

   return $widget;
}

sub make_widget_pre_scroller
{
   my $self = shift;
   my ( $box ) = @_;

   my $registry = $self->{registry};

   my $topicentry = $registry->construct(
      "Circle::Widget::Entry",
      classes => [qw( topic )],
      on_enter => sub { $self->topic( $_[0] ) },
   );
   $self->watch_property( "topic",
      on_updated => sub { $topicentry->set_prop_text( $_[1] ) }
   );

   $box->add( $topicentry );
}

0x55AA;
