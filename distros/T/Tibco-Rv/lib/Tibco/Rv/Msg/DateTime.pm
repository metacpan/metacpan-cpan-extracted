package Tibco::Rv::Msg::DateTime;


use vars qw/ $VERSION /;
$VERSION = '1.02';


my ( %defaults );
BEGIN
{
   %defaults = ( sec => 0, nsec => 0 );
}


use overload '""' => 'toString', '0+' => 'toNum', fallback => 1;


sub new
{
   my ( $proto ) = shift;
   my ( %args ) = @_;
   map { Tibco::Rv::die( Tibco::Rv::INVALID_ARG )
      unless ( exists $defaults{$_} ) } keys %args;
   my ( %params ) = ( %defaults, %args );
   my ( $class ) = ref( $proto ) || $proto;
   my ( $self ) = $class->_new;

   @$self{ qw/ sec nsec / } = @params{ qw/ sec nsec / };

   my ( $status ) =
      Tibco::Rv::Msg::MsgDateTime_Create( @$self{ qw/ ptr sec nsec / } );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );

   return $self;
}


sub now { return shift->new( sec => time ) }


sub _new
{
   my ( $class, $ptr ) = @_;
   return bless { ptr => $ptr, %defaults }, $class;
}


sub _adopt
{
   my ( $proto, $ptr ) = @_;
   my ( $self );
   my ( $class ) = ref( $proto );
   if ( $class )
   {
      $self = $proto;
      $self->DESTROY;
      @$self{ 'ptr', keys %defaults } = ( $ptr, values %defaults );
   } else {
      $self = bless $proto->_new( $ptr ), $proto;
   }
   $self->_getValues;
   return $self;
}


sub _getValues
{
   my ( $self ) = @_;
   Tibco::Rv::Msg::MsgDateTime_GetValues( @$self{ qw/ ptr sec nsec / } );
}


sub toString { return scalar( gmtime shift->{sec} ) . 'Z' }
sub toNum { return shift->{sec} } 


sub sec
{
   my ( $self ) = shift;
   return @_ ? $self->_setSec( @_ ) : $self->{sec};
}


sub nsec
{
   my ( $self ) = shift;
   return @_ ? $self->_setNsec( @_ ) : $self->{nsec};
}


sub _setSec
{
   my ( $self, $sec ) = @_;
   Tibco::Rv::Msg::MsgDateTime_SetSec( $self->{ptr}, $sec );
   return $self->{sec} = $sec;
}


sub _setNsec
{
   my ( $self, $nsec ) = @_;
   Tibco::Rv::Msg::MsgDateTime_SetNsec( $self->{ptr}, $nsec );
   return $self->{nsec} = $nsec;
}


sub DESTROY
{
   my ( $self ) = @_;
   return unless ( exists $self->{ptr} );

   my ( $status ) = Tibco::Rv::Msg::MsgDateTime_Destroy( $self->{ptr} );
   delete @$self{ keys %$self };
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
}


1;


=pod

=head1 NAME

Tibco::Rv::Msg::DateTime - Tibco DateTime datatype

=head1 SYNOPSIS

   my ( $date ) = $msg->createDateTime;
   my ( $now ) = Tibco::Rv::Msg::DateTime->now;
   $msg->addDateTime( now => $now );
   print "time: $now\n";

=head1 DESCRIPTION

DateTime-manipulating class.  Holds seconds since the epoch plus some
nanoseconds.

=head1 CONSTRUCTOR

=over 4

=item $date = new Tibco::Rv::Msg::DateTime( %args )

   %args:
      sec => $seconds,
      nsec => $nanoseconds

Creates a C<Tibco::Rv::Msg::DateTime>, with C<$seconds> since the epoch
(defaults to 0 if unspecified), and C<$nanoseconds> before or after that
time (defaults to 0 if unspecified).

=item $now = Tibco::Rv::Msg::DateTime->now

Creates a C<Tibco::Rv::Msg::DateTime> with seconds specifying the current
time.

=back

=head1 METHODS

=over 4

=item $sec = $date->sec

Returns the seconds.

=item $date->sec( $sec )

Sets the seconds.

=item $nsec = $date->nsec

Returns the nanoseconds.

=item $date->nsec( $nsec )

Sets the nanoseconds.

=item $str = $date->toString (or "$date")

Returns a string representation of C<$date>.  For example,
"Fri Jan 31 04:43:55 2003Z".  Note that this is Zulu (GMT) time.  Or,
simply use C<$date> in a string context.

=item $date->toNum (or 0+$date)

Returns the number of seconds since the epoch represented by C<$date>.
Suitable for passing to localtime( ) or other time functions.  Or,
simply use C<$date> in a numeric context.

=back

=head1 AUTHOR

Paul Sturm E<lt>I<sturm@branewave.com>E<gt>

=cut
