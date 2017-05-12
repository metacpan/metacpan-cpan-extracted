#  You may distribute under the terms of the GNU General Public License
#
#  (C) Paul Evans, 2008-2014 -- leonerd@leonerd.org.uk

package Circle;

use strict;
use warnings;
use base qw( Net::Async::Tangence::Server );
IO::Async::Notifier->VERSION( '0.43' ); # ->loop
Net::Async::Tangence::Server->VERSION( '0.12' ); # subclass of IaListener

our $VERSION = '0.170740';

use Carp;

use Tangence::Registry 0.20; # Support for late-loading classes
use Circle::RootObj;

use File::ShareDir qw( module_file );

use IO::Async::OS;

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
   my $handle = $self->{new_handle}->( $self );
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

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
