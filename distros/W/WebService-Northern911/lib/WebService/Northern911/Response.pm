package WebService::Northern911::Response;

use strict;

sub new {
  my $class = shift;
  my $self;

  my $tree = shift;
  $tree = $tree->{'parameters'} if exists $tree->{'parameters'};
  my ($key) = grep /Result$/, keys(%$tree); # should only ever be one key
  $tree = $tree->{$key} or die "can't parse transaction result";

  my $error_message = join("\n",
    map { $_->{ErrorMessage} }
    @{ $tree->{Errors}{Error} }
  );

  $self = {
    is_success    => $tree->{Accepted},
    error_message => $error_message,
  };

  if ( $key eq 'QueryCustomerResult' ) {
    if ($tree->{Accepted}) {
      $self->{customer} = $tree->{Customer};
    } elsif ( $tree->{Errors}{Error}[0]{ErrorCode} == 101 ) {
      # 101 = Customer does not exist.  But the query was successful...
      $self->{is_success} = 1;
    }
  } elsif ( $key eq 'GetVendorDumpURL' ) {
    $self->{url} = $tree->{VendorDumpURL};
  }

  bless $self, $class;
}

sub is_success {
  $_[0]->{is_success};
}

sub error_message {
  $_[0]->{error_message};
}

sub customer {
  $_[0]->{customer};
}

sub url {
  $_[0]->{url};
}

=head1 NAME

WebService::Northern911::Response - Response object returned by
WebService::Northern911 API calls

=head1 METHODS

=over 4

=item is_success

1 if the API method was a success, 0 if not.  If it's 0, C<error_message>
will contain any error returned.  Note that we report the C<QueryCustomer>
method as a success if it returns a negative result; in that case, 
C<customer> will be undef.

=item error_message

Any error messages returned from the web service, separated by newlines.

=item customer

For C<QueryCustomer> calls, returns a hashref of the customer information
per the field names used by C<AddorUpdateCustomer>.

=item url

For C<GetVendorDumpURL> calls, returns the URL where the data dump can be
downloaded.

=back

=cut

1;
