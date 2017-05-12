package Tibco::Rv::Cm::Msg;
use base qw/ Tibco::Rv::Msg /;


use vars qw/ $VERSION @CARP_NOT /;
$VERSION = '1.02';


@CARP_NOT = qw/ Tibco::Rv::Msg /;


my ( %defaults );
BEGIN
{
   %defaults = ( CMTimeLimit => undef );
}


sub new
{
   my ( $proto ) = shift;
   my ( %params ) = ( CMSender => undef, CMSequence => undef, %defaults );
   my ( %args ) = @_;
   foreach my $field ( keys %defaults )
   {
      next unless ( exists $args{$field} );
      $params{$field} = $args{$field};
      delete $args{$field};
   }
   my ( $self ) = $proto->SUPER::new( %args );

   @$self{ keys %params } = ( values %params );
   $self->CMTimeLimit( $params{CMTimeLimit} )
      if ( defined $params{CMTimeLimit} );

   return $self;
}


sub _adopt
{
   my ( $proto, $id ) = @_;
   my ( $self ) = $proto->SUPER::_adopt( $id );
   @$self{ qw/ CMSender CMSequence /, keys %defaults } =
      ( undef, undef, values %defaults );
   $self->_getCMValues;
   return $self;
}


sub _getCMValues
{
   my ( $self ) = @_;
   Tibco::Rv::Msg::Msg_GetCMValues(
      @$self{ qw/ id CMSender CMSequence CMTimeLimit / } );
}


sub CMSender { return shift->{CMSender} }
sub CMSequence { return shift->{CMSequence} }


sub CMTimeLimit
{
   my ( $self ) = shift;
   return @_ ? $self->_setCMTimeLimit( @_ ) : $self->{CMTimeLimit};
}


sub _setCMTimeLimit
{
   my ( $self, $CMTimeLimit ) = @_;
   my ( $status ) =
      Tibco::Rv::Msg::tibrvMsg_SetCMTimeLimit( $self->{id}, $CMTimeLimit );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
   return $self->{CMTimeLimit} = $CMTimeLimit;
}


1;


=pod

=head1 NAME

Tibco::Rv::Cm::Msg - Tibco certified message object

=head1 SYNOPSIS

   $rv->createCmListener( ..., callback => sub
   {
      my ( $msg ) = @_;
      print "Listener got a message: $msg, from sender: ", $msg->CMSender,
      ', sequence: ', $msg->CMSequence, "\n";
   } );

=head1 DESCRIPTION

Tibco certified message-manipulating class.  It is a subclass of
L<Tibco::Rv::Msg|Tibco::Rv::Msg>, so Msg methods are available to
certified messages.  Additionally, methods specific to certified
messaging (CMSender, CMSequence, and CMTimeLimit) are available.

=head1 CONSTRUCTOR

=over 4

=item $msg = new Tibco::Rv::Cm::Msg( %args )

   %args:
      sendSubject => $sendSubject,
      replySubject => $replySubject,
      CMTimeLimit => $CMTimeLimit,
      $fieldName1 => $stringValue1,
      $fieldName2 => $stringValue2, ...

Creates a C<Tibco::Rv::Cm::Msg>, with sendSubject, replySubject, and
CMTimeLimit as given in %args (these three values default to C<undef> if
not specified).  Any other name => value pairs are added as string fields.

=back

=head1 METHODS

=over 4

=item $CMSender = $msg->CMSender

Returns the CMSender that sent C<$msg>.  If C<$msg> was not sent from a
certified messaging sender, C<undef> is returned.

=item $CMSequence = $msg->CMSequence

Returns the sequence number if C<$msg> was sent from a certified messaging
sender, and if the listener is registered for certified delivery.  Otherwise,
C<undef> is returned.

See your TIB/Rendezvous documentation for more information on CMSender and
CMSequence.

=item $CMTimeLimit = $msg->CMTimeLimit

Returns the certified messaging time limit for C<$msg>, after which the
sender no longer certifies delivery.  A return value of C<0> represents
no time limit.

=item $msg->CMTimeLimit( $CMTimeLimit )

=back

Sets the certified messaging time limit for C<$msg>, after which the sender
no longer certifies delivery.  If no time limit is set, the value set by
C<Tibco::Rv::Cm::Transport::setDefaultCMTimeLimit> is used.  If
setDefaultCMTimeLimit was not called, C<0> is used (no time limit).

=head1 SEE ALSO

L<Tibco::Rv::Msg>

=head1 AUTHOR

Paul Sturm E<lt>I<sturm@branewave.com>E<gt>

=cut
