package Tibco::Rv::Status;


use vars qw/ $VERSION /;
$VERSION = '1.02';


use Inline with => 'Tibco::Rv::Inline';
use Inline C => 'DATA', NAME => __PACKAGE__,
   VERSION => $Tibco::Rv::Inline::VERSION;


use overload '""' => 'toString', '0+' => 'toNum', fallback => 1;


sub new
{
   my ( $proto ) = shift;
   my ( %params ) = ( status => Tibco::Rv::OK );
   my ( %args ) = @_;
   map { Tibco::Rv::die( Tibco::Rv::INVALID_ARG )
      unless ( exists $params{$_} ) } keys %args;
   %params  = ( %params, %args );
   my ( $class ) = ref( $proto ) || $proto;
   my ( $self ) = bless { status => $params{status} }, $class;
   return $self;
}


sub toString { return tibrvStatus_GetText( shift->{status} ) }
sub toNum { return shift->{status} }


1;


=pod

=head1 NAME

Tibco::Rv::Status - status code

=head1 SYNOPSIS

   my ( $status ) =
      new Tibco::Rv::Status( status => Tibco::Rv::INVALID_ARG );

   $status = $msg->removeField( $fieldName, $fieldId );
   print "returned: $status\n" if ( $status != Tibco::Rv::OK );


=head1 DESCRIPTION

Wrapper class for status codes.

=head1 CONSTRUCTOR

=over 4

=item $status = new Tibco::Rv::Status( %args )

   %args:
      status => $status

Creates a C<Tibco::Rv::Status> object with the given status.  C<$status>
should be one of the
L<Tibco::Rv Status Constants|Tibco::Rv/"STATUS CONSTANTS">, or an equivalent
numeric value.

=back

=head1 METHODS

=over 4

=item $str = $status->toString (or "$status")

Returns a descriptive string of C<$status>.  Or, simply use C<$status> in
a string context.

=item $num = $status->toNum (or 0+$status)

Returns the numeric value of C<$status>.  Or, simply use C<$status> in a
numeric context.

=back

=head1 AUTHOR

Paul Sturm E<lt>I<sturm@branewave.com>E<gt>

=cut


__DATA__
__C__


const char * tibrvStatus_GetText( tibrv_status status );
