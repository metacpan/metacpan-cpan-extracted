package SDKException;
use Error;
use JSON;
sub new
{
  my ($class, $code, $message, $details, $cause) = @_;

  my $self={
      code    => $code,
      message => $message,
      details => JSON->new->utf8->encode($details),
      cause   => $cause
  };

  if(defined($self->{cause})) {
    $self->{message} = $self->{message}."\n".$self->{cause};
  }
  if(defined($self->{details})) {
    $self->{message}=$self->{message}."\n".$self->{details};
  }
  bless $self,$class;
  return $self;
}
sub to_string
{
  my $self=shift;
  return "\n"."Error Code:".$self->{code}."\n"."Message:".$self->{message}."\n"."TRACE:".$self->{cause}."\n";
}

=head1 NAME

 com::zoho::api::exception::SDKException - This class is the common SDKException object. This stands as a POJO for the SDKException thrown.

=head1 DESCRIPTION

=head2 METHODS

=over 4

=item C<new>

Creates an SDKException class instance with the specified parameters.

Param code : A String containing the Exception error code.

Param message : A String containing the Exception error message.

Param details : A JSONObject containing the error response.

Param cause : A Exception class instance.

=item C<to_string>

Returns a String representing the cause of the details

=back

=cut

1;
