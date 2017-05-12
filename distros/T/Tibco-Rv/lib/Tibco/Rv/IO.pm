package Tibco::Rv::IO;
use base qw/ Tibco::Rv::Event /;


use vars qw/ $VERSION @CARP_NOT /;
$VERSION = '1.04';


use constant READ => 1;
use constant WRITE => 2;
use constant EXCEPTION => 4;


@CARP_NOT = qw/ Tibco::Rv::Event /;


sub new
{
   my ( $proto ) = shift;
   my ( %params ) = ( queue => $Tibco::Rv::Queue::DEFAULT, socketId => 1,
      ioType => Tibco::Rv::IO::READ,
      callback => sub { print "IO event occurred\n" } );
   my ( %args ) = @_;
   map { Tibco::Rv::die( Tibco::Rv::INVALID_ARG )
      unless ( exists $params{$_} ) } keys %args;
   %params = ( %params, %args );
   my ( $self ) = $proto->SUPER::new(
      queue => $params{queue}, callback => $params{callback} );

   @$self{ qw/ socketId ioType / } = @params{ qw/ socketId ioType / };

   my ( $status ) = Tibco::Rv::Event::Event_CreateIO(
      $self->{id}, $self->{queue}{id}, $self->{internal_nomsg_callback},
      $self->{socketId}, $self->{ioType} );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );

   return $self;
}


sub socketId { return shift->{socketId} }
sub ioType { return shift->{ioType} }


1;


=pod

=head1 NAME

Tibco::Rv::IO - Tibco IO event object

=head1 SYNOPSIS

   my ( $io );
   $io = $rv->createIO( socketId => fileno( IN ),
      ioType => Tibco::Rv::IO::READ, callback => sub
   {
      my ( $data ) = scalar( <IN> );
      print "I got data: $data\n";
      $io->DESTROY;
   }

=head1 DESCRIPTION

A C<Tibco::Rv::IO> fires an event when a file handle (or socket) becomes
ready for reading, writing, or has an exceptional condition occur.  It is
a subclass of L<Tibco::Rv::Event|Tibco::Rv::Event>, so Event methods are
available to IO objects (documentation on Event methods are reproduced
here for convenience).

=head1 CONSTRUCTOR

=over 4

=item $io = new Tibco::Rv::IO( %args )

   %args:
      queue => $queue,
      socketId => $socketId,
      ioType => $ioType,
      callback => sub { ... }

Creates a C<Tibco::Rv::IO>.  If not specified, queue defaults to the
L<Default Queue|Tibco::Rv::Queue/"DEFAULT QUEUE">, socketId defaults to 1,
ioType defaults to C<Tibco::Rv::IO::READ>, and callback defaults to:

   sub { print "IO event occurred\n" }

Create an IO object to cause an event to fire when C<$socketId> is
ready for reading, writing, or has an exceptional condition (the ioType
parameter must be one of the L<ioType constants|"IOTYPE CONSTANTS"> below).
To extract the socketId from a Perl filehandle, use the builtin fileno( )
function.   When C<$queue> dispatches such an event, it triggers the given
callback.

=back

=head1 METHODS

=over 4

=item $socketId = $io->socketId

Returns the socketId being monitiored.

=item $ioType = $io->ioType

Returns the L<ioType constant|"IOTYPE CONSTANTS"> representing what C<$io>
is monitoring for -- reading, writing, or a conditional exception.

=item $queue = $io->queue

Returns the queue on which this IO's events will be dispatched.

=item $callback = $io->callback

Returns the callback code reference.

=item $io->onEvent

Trigger an event directly.  The event will be processed as if it was
triggered via the event queue.

=item $io->DESTROY

Cancels the IO monitoring.  Called automatically when C<$io> goes out of
scope.  Calling DESTROY more than once has no effect.

=back

=head1 IOTYPE CONSTANTS

=over 4

=item Tibco::Rv::IO::READ => 1

=item Tibco::Rv::IO::WRITE => 2

=item Tibco::Rv::IO::EXCEPTION => 4

=back

=head1 OVERRIDING EVENT CALLBACK

As an alternative to passing in a callback function to the constructor, there
is another way to handle events.  You can subclass C<Tibco::Rv::IO> and
override the onEvent method, as follows:

   package MyIO;
   use base qw/ Tibco::Rv::IO /;

   sub new
   {
      my ( $proto, %args ) = @_;
      my ( $self ) = $proto->SUPER::new( %args );
      # your initialization code
      return $self;
   }

   sub onEvent
   {
      my ( $self ) = @_;
      # process event here
      # $self->queue, $self->socketId, $self->ioType are available
   }

   # any other implementation code for your class

   1;

The C<Tibco::Rv::Event> onEvent method simply calls the callback, so
overriding onEvent allows you to process the event however you want, and
you can just not use the callback.

The advantages of this method of handling events are: it is more
object-oriented; you have access to the queue, socketId, and ioType via the
C<$self> accessor methods; and, you can have more elaborate processing of
IO events without having to shove it all into one callback.

You can use your subclassed IO as follows:

   use Tibco::Rv;
   use MyIO;

   my ( $rv ) = new Tibco::Rv;
   my ( $myIo ) =
      new MyIO( ioType => Tibco::Rv::IO::READ, socketId => fileno( IN ) );
   $rv->start;

=head1 AUTHOR

Paul Sturm E<lt>I<sturm@branewave.com>E<gt>

=cut
