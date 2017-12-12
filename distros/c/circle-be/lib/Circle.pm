#  You may distribute under the terms of the GNU General Public License
#
#  (C) Paul Evans, 2008-2014 -- leonerd@leonerd.org.uk

package Circle;

use strict;
use warnings;
use base qw( Net::Async::Tangence::Server );
IO::Async::Listener->VERSION( '0.64' ); # {handle_constructor}
Net::Async::Tangence::Server->VERSION( '0.13' ); # Future-returning API

our $VERSION = '0.173320';

use Carp;

use Tangence::Registry 0.20; # Support for late-loading classes

use File::ShareDir qw( module_file );

use IO::Async::OS;

require Circle::RootObj; # must be late-bound, after $VERSION is set

=head1 NAME

C<Circle> - server backend for the C<Circle> application host

=cut

sub new
{
   my $class = shift;
   my %args = @_;

   my $loop = $args{loop} or croak "Need a loop";

   my $registry = Tangence::Registry->new(
      tanfile => module_file( __PACKAGE__, "circle.tan" ),
   );

   my $rootobj = $registry->construct(
      "Circle::RootObj",
      loop => $loop
   );
   $rootobj->id == 1 or die "Assert failed: root object does not have ID 1";

   my $self = $class->SUPER::new(
      registry => $registry,
   );

   $loop->add( $self );

   $self->{rootobj} = $rootobj;

   return $self;
}

sub make_local_client
{
   my $self = shift;

   my $loop = $self->loop;

   my ( $S1, $S2 ) = IO::Async::OS->socketpair or die "Cannot socketpair - $!";

   # Internal hackery; stolen from IaListener
   my $acceptor = $self->acceptor;
   my $handle = $self->{handle_constructor}->( $self );
   $S1->blocking( 0 );
   $handle->set_handle( $S1 );
   $self->on_accept( $handle );

   require Net::Async::Tangence::Client;
   my $client = Net::Async::Tangence::Client->new(
      handle => $S2,
      identity => "test_client",
   );

   $loop->add( $client );

   return $client;
}

sub new_with_client
{
   my $class = shift;

   my $self = $class->new( @_ );

   my $client = $self->make_local_client;

   return ( $self, $client );
}

sub warn
{
   my $self = shift;
   my $text = join " ", @_;
   chomp $text;

   my $rootobj = $self->{rootobj};
   $rootobj->push_displayevent( warning => { text => $text } );
   $rootobj->bump_level( 2 );
}

=head1 QUESTIONS

=head2 How do I connect to freenode.net #perl and identify with NickServ

   # in Global tab
   /networks add -type irc Freenode

   # in Freenode tab
   /set nick YourNickHere
   /servers add irc.freenode.net -ident yournamehere -pass secretpasswordhere
   /connect

   # Don't forget to
   /config save

=head2 How do I get notifications whenever someone uses the word perl in a channel that isn't on magnet or freenode#perl

   /rules add input not(channel("#perl")) matches("perl"): highlight

Rules are network-specific so just don't do that on Magnet.

=head2 How do I set up a command to ban the hostmask for a given nick in the current channel for 24h

You'll have to read the hostmask of the user specifically, but then

   /mode +b ident@host.name.here
   /delay 86400 mode -b ident@host.name.here

Note the lack of C</> on the inner C<mode> to C<delay>

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
