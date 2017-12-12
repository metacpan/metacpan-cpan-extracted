#  You may distribute under the terms of the GNU General Public License
#
#  (C) Paul Evans, 2008-2014 -- leonerd@leonerd.org.uk

package Circle::RootObj;

use strict;
use warnings;
use base qw( Tangence::Object Circle::WindowItem );

our $VERSION = '0.173320';

use Class::Method::Modifiers;

use Carp;
use YAML (); # 'Dump' and 'Load' are a bit generic; we'll call by FQN

use Circle::Rule::Store;
require Circle::GlobalRules;

use Circle::CommandInvocation;

use Module::Pluggable sub_name    => "net_types",
                      search_path => [ "Circle::Net" ],
                      only        => qr/^Circle::Net::\w+$/, # Not inner ones
                      force_search_all_paths => 1;

{
   foreach my $class ( net_types ) {
      ( my $file = "$class.pm" ) =~ s{::}{/}g;
      require $file;
   }
}

use Data::Dump;

use constant CIRCLERC => $ENV{CIRCLERC} || "$ENV{HOME}/.circlerc";

sub _nettype2class
{
   my ( $type ) = @_;

   foreach ( __PACKAGE__->net_types ) {
      my $thistype = eval { $_->NETTYPE };
      if( defined $thistype and $thistype eq $type ) {
         return $_;
      }
   }

   return undef;
}

sub new
{
   my $class = shift;
   my %args = @_;

   my $loop = delete $args{loop} or croak "Need a loop";

   my $self = $class->SUPER::new( %args );

   $self->{loop} = $loop;

   my $rulestore = $self->{rulestore} = Circle::Rule::Store->new();
   Circle::GlobalRules::register( $rulestore );

   my $file = $args{config} // CIRCLERC;
   if( -r $file ) {
      my $config = YAML::LoadFile( $file );
      $self->load_configuration( $config );
   }

   return $self;
}

sub add_network
{
   my $self = shift;
   my ( $class, $name ) = @_;

   my $loop = $self->{loop};

   # Late-loading to support out-of-tree classes so they don't have to declare
   #   in the .tan file
   eval { Tangence::Class->for_perlname( $class ) } or
      eval { $class->DECLARE_TANGENCE } or
      croak "Unknown Tangence::Class for '$class' and can't lazy-load it";

   my $registry = $self->{registry};
   my $newnet = $registry->construct(
      $class,
      tag  => $name,
      root => $self,
      loop => $loop,
   );

   $newnet->subscribe_event( destroy => sub {
      my ( $newnet ) = @_;
      $self->broadcast_sessions( "delete_item", $newnet );
      $self->del_prop_networks( $name );
   } );

   $self->fire_event( "network_added", $newnet );
   $self->add_prop_networks( $name => $newnet );

   $self->broadcast_sessions( "new_item", $newnet );

   return $newnet;
}

sub del_network
{
   my $self = shift;
   my ( $network ) = @_;

   $network->destroy;
}

use Circle::Collection
   name  => 'networks',
   storage => {
      list => sub {
         my $self = shift;
         my $networks = $self->get_prop_networks;
         return map { { name => $_, type => $networks->{$_}->NETTYPE } } sort keys %$networks;
      },

      get => sub {
         my $self = shift;
         my ( $name ) = @_;
         my $network = $self->get_prop_networks->{$name} or return undef;
         return { name => $name, type => $network->NETTYPE };
      },

      add => sub {
         my $self = shift;
         my ( $name, $item ) = @_;

         my $class = _nettype2class( $item->{type} );

         defined $class or die "unrecognised network type '$item->{type}'\n";

         $self->add_network( $class, $name );
      },

      del => sub {
         my $self = shift;
         my ( $name ) = @_;
         my $network = $self->get_prop_networks->{$name} or return;

         $network->connected and die "still connected\n";

         $self->del_network( $network );
      },
   },
   attrs => [
      name => {},
      type => { nomod => 1, default => "irc" },
   ],
   config => {
      type => "hash",
      load => sub {
         my $self = shift;
         my ( $name, $ynode ) = @_;
         $self->get_prop_networks->{$name}->load_configuration( $ynode );
      },
      store => sub {
         my $self = shift;
         my ( $name, $ynode ) = @_;
         $self->get_prop_networks->{$name}->store_configuration( $ynode );
      },
   },
   ;

our %sessions;

sub add_session
{
   my $self = shift;
   my ( $identity, $type ) = @_;

   eval "require $type";
   die $@ if $@;

   my $registry = $self->{registry};

   my $session = $registry->construct(
      $type,
      root => $self,
      identity => $identity,
   );

   return $sessions{$identity} = $session;
}

sub method_get_session
{
   my $self = shift;
   my ( $ctx, $opts ) = @_;

   my $identity = $ctx->stream->identity;

   return $sessions{$identity} if exists $sessions{$identity};
   
   my $type = _session_type( $opts );

   defined $type or die "Cannot identify a session type\n";

   return $self->add_session( $identity, $type );
}

sub broadcast_sessions
{
   my $self = shift;
   my ( $method, @args ) = @_;

   foreach my $session ( values %sessions ) {
      $session->$method( @args ) if $session->can( $method );
   }
}

sub invoke_session
{
   my $self = shift;
   my ( $conn, $method, @args ) = @_;

   my $session = $sessions{$conn->identity};
   return unless $session;

   $session->$method( @args ) if $session->can( $method );
}

sub _session_type
{
   my ( $opts ) = @_;
   my %opts = map { $_ => 1 } @$opts;

   if( $opts{tabs} ) {
      delete $opts{tabs};
      require Circle::Session::Tabbed;
      return Circle::Session::Tabbed::_session_type( \%opts );
   }

   print STDERR "Need Session for options\n";
   print STDERR "  ".join( "|", sort keys %opts )."\n";

   return undef;
}

use Circle::Collection
   name => 'sessions',
   storage => {
      list => sub {
         map { my $class = ref $sessions{$_}; $class =~ s/^Circle::Session:://;
               { name => $_, type => $class } } sort keys %sessions;
      },
   },
   attrs => [
      name => {},
      type => { nomod => 1 },
   ],
   commands => {
      # Disable add modify del
      add => undef, mod => undef, del => undef,
   },
   config => 0,
   ;

sub command_session
   : Command_description("Manage the current session")
{
}

sub command_session_info
   : Command_description("Show information about the session")
   : Command_subof('session')
   : Command_default()
{
   my $self = shift;
   my ( $cinv ) = @_;

   my $identity = $cinv->connection->identity;
   my $session = defined $identity ? $sessions{$identity} : undef;

   unless( defined $session ) {
      $cinv->responderr( "Cannot find a session for this identity" );
      return;
   }

   ( my $type = ref $session ) =~ s/^Circle::Session:://;

   $cinv->respond_table(
      [
         [ Type     => $type ],
         [ Identity => $identity ],
         [ Items    => scalar $session->items ],
      ],
      colsep => ": ",
   );

   return;
}

sub command_session_clonefrom
   : Command_description("Clone items from another session")
   : Command_subof('session')
   : Command_arg('name')
{
   my $self = shift;
   my ( $name, $cinv ) = @_;

   my $identity = $cinv->connection->identity;

   my $destsession = defined $identity ? $sessions{$identity} : undef or
      return $cinv->responderr( "Cannot find a session for this identity" );

   my $srcsession = $sessions{$name} or
      return $cinv->responderr( "Cannot find a session called '$name'" );

   eval { $destsession->clonefrom( $srcsession ); 1 } or
      return $cinv->responderr( "Cannot clone $name into $identity - $@" );

   return;
}

sub command_eval
   : Command_description("Evaluate a perl expression")
   : Command_arg('expr', eatall => 1)
{
   my $self = shift;
   my ( $expr, $cinv ) = @_;

   my $connection = $cinv->connection;

   my $identity = $connection->identity;
   my $session = defined $identity ? $sessions{$identity} : undef;

   my %pad = (
      ROOT    => $self,
      LOOP    => $self->{loop},
      CONN    => $connection,
      ITEM    => $cinv->invocant,
      SESSION => $session,
   );

   my $result = do {
      local $SIG{__WARN__} = sub {
         my $msg = $_[0];
         $msg =~ s/ at \(eval \d+\) line \d+\.$//;
         chomp $msg;
         $cinv->respondwarn( $msg, level => 2 );
      };

      eval join( "", map { "my \$$_ = \$pad{$_}; " } keys %pad ) . "$expr";
   };

   if( $@ ) {
      my $err = $@; chomp $err;
      $cinv->responderr( "Died: $err" );
   }
   else {
      my @lines;

      my $timedout;
      local $SIG{ALRM} = sub { $timedout = 1; die };
      eval {
         alarm(5);
         @lines = split m/\n/, Data::Dump::dump($result);
         alarm(0);
      };

      if( $timedout ) {
         $cinv->responderr( "Failed - took too long to render results. Try something more specific" );
         return;
      }

      if( @lines > 20 ) {
         @lines = ( @lines[0..18], "...", $lines[-1] );
      }

      if( @lines == 1 ) {
         $cinv->respond( "Result: $lines[0]" );
      }
      else {
         $cinv->respond( "Result:" );
         $cinv->respond( "  $_" ) for @lines;
      }
   }

   return;
}

sub command_rerequire
   : Command_description("Rerequire a perl module")
   : Command_arg('module')
{
   my $self = shift;
   my ( $module, $cinv ) = @_;

   # This might be a module name Foo::Bar or a filename Foo/Bar.pm
   my $filename;

   if( $module =~ m/::/ ) {
      ( $filename = $module ) =~ s{::}{/}g;
      $filename .= ".pm";
   }
   elsif( $module =~ m/^(.*)\.pm$/ ) {
      $filename = $module;
      ( $module = $1 ) =~ s{/}{::}g;
   }
   else {
      return $cinv->responderr( "Unable to recognise if $module is a module name or a file name" );
   }

   if( !exists $INC{$filename} ) {
      return $cinv->responderr( "Module $module in file $filename isn't loaded" );
   }

   {
      local $SIG{__WARN__} = sub {
         my $msg = $_[0];
         $msg =~ s/ at \(eval \d+\) line \d+\.$//;
         chomp $msg;
         $cinv->respondwarn( $msg, level => 2 );
      };

      no warnings 'redefine';

      delete $INC{$filename};
      eval { require $filename };
   }

   if( $@ ) {
      my $err = $@; chomp $err;
      $cinv->responderr( "Died: $err" );
   }
   else {
      $cinv->respond( "Reloaded $module from $filename" );
   }

   return;
}

sub commandable_parent
{
   my $self = shift;
   my ( $cinv ) = @_;

   return $sessions{$cinv->connection->identity};
}

sub enumerate_items
{
   my $self = shift;
   my $networks = $self->get_prop_networks;
   return { map { $_->enumerable_name => $_ } values %$networks };
}

sub enumerable_name
{
   return "";
}

sub parent
{
   return undef;
}

sub command_delay
   : Command_description("Run command after some delay")
   : Command_arg('seconds')
   : Command_arg('command', eatall => 1)
{
   my $self = shift;
   my ( $seconds, $text, $cinv ) = @_;

   # TODO: A CommandInvocant subclass that somehow prefixes its output so we
   # know it's delayed output from earlier, so as not to confuse
   my $subinv = $cinv->nest( $text );

   my $cmdname = $subinv->peek_token or
      return $cinv->responderr( "No command given" );

   my $loop = $self->{loop};

   my $id = $loop->enqueue_timer(
      delay => $seconds,
      code => sub {
         eval {
            $subinv->invocant->do_command( $subinv );
         };
         if( $@ ) {
            my $err = $@; chomp $err;
            $cinv->responderr( "Delayed command $cmdname failed - $err" );
         }
      },
   );

   # TODO: Store ID, allow list, cancel, etc...

   return;
}

###
# Configuration management
###

sub command_config
   : Command_description("Save configuration or change details about it")
{
   # The body doesn't matter as it never gets run
}

sub command_config_show
   : Command_description("Show the configuration that would be saved")
   : Command_subof('config')
   : Command_default()
{
   my $self = shift;
   my ( $cinv ) = @_;

   # Since we're only showing config, only fetch it for the invocant
   my $obj = $cinv->invocant;

   unless( $obj->can( "get_configuration" ) ) {
      $cinv->respond( "No configuration" );
      return;
   }

   my $config = YAML::Dump( $obj->get_configuration );

   $cinv->respond( $_ ) for split m/\n/, $config;
   return;
}

sub command_config_save
   : Command_description("Save configuration to disk")
   : Command_subof('config')
{
   my $self = shift;
   my ( $cinv ) = @_;

   my $file = CIRCLERC;
   YAML::DumpFile( $file, $self->get_configuration );

   $cinv->respond( "Configuration written to $file" );
   return;
}

sub command_config_reload
   : Command_description("Reload configuration from disk")
   : Command_subof('config')
{
   my $self = shift;
   my ( $cinv ) = @_;

   my $file = CIRCLERC;
   $self->load_configuration( YAML::LoadFile( $file ) );

   $cinv->respond( "Configuration loaded from $file" );
   return;
}

# For Configurable role
after load_configuration => sub {
   my $self = shift;
   my ( $ynode ) = @_;

   if( my $sessions_ynode = $ynode->{sessions} ) {
      foreach my $sessionname ( keys %$sessions_ynode ) {
         my $sessionnode = $sessions_ynode->{$sessionname};
         my $type = $sessionnode->{type};

         my $session = $self->add_session( $sessionname, "Circle::Session::$type" );
         $session->load_configuration( $sessionnode );
      }
   }
};

after store_configuration => sub {
   my $self = shift;
   my ( $ynode ) = @_;

   my $sessions_ynode = $ynode->{sessions} ||= YAML::Node->new({});
   %$sessions_ynode = ();

   foreach my $identity ( keys %sessions ) {
      my $session = $sessions{$identity};

      my $sessionnode = $session->get_configuration;
      $sessions_ynode->{$identity} = $sessionnode;

      unless( $sessionnode->{type} ) { # exists doesn't quite play ball
         # Ensure it's first
         unshift @{ tied(%$sessionnode)->keys }, 'type'; # I am going to hell for this
         ( $sessionnode->{type} ) = (ref $session) =~ m/^Circle::Session::(.*)$/;
      }
   }
};

0x55AA;
