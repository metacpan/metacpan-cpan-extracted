package WebService::Northern911;

use Digest::MD5 'md5_hex';
use DateTime;
use XML::Compile::WSDL11;
use XML::Compile::SOAP11;
use XML::Compile::Transport::SOAPHTTP;
use File::ShareDir 'dist_dir';

use WebService::Northern911::Response;

our $VERSION = 0.1;

=head1 NAME

WebService::Northern911 - Interface to the Northern 911 ALI database

=head1 SYNOPSIS

use WebService::Northern911;

my $n911 = WebService::Northern911->new( vendor_code => '007',
                                  password => '280fip1@' );

my $result = $n911->AddorUpdateCustomer(
  PHONE_NUMBER    => '4015559988',
  FIRST_NAME      => 'John',
  LAST_NAME       => 'Doe',
  STREET_NUMBER   => 1024,
  STREET_NAME     => 'Main St',
  CITY            => 'Calgary',
  PROVINCE_STATE  => 'AB',
  POSTAL_CODE_ZIP => 'Z1A A2Z',
);
if ($result->is_success) {
  print "Updated customer."
} else 
  print $result->error_message;
}

=head1 METHODS

=over 4  

=item new OPTIONS

Creates an object to access the API.  OPTIONS must include C<vendor_code>
and C<password>.  By default, this will connect to the development API;
for access to the live service, pass C<live> => 1.

=cut

sub new {
  my $class = shift;
  my %opt = @_;
  my $vendor_code = $opt{vendor_code} or die "WebService::Northern911::new() requires vendor_code\n";
  my $password = $opt{password} or die "WebService::Northern911::new() requires password\n";

  # create the interface
  # expensive, so reuse this object as much as possible
  my $schema = dist_dir('WebService-Northern911') . '/schema';
  if ($opt{'live'}) {
    $schema .= '/live';
  } else {
    $schema .= '/test';
  }

  # yes, that's right, we have to distribute the schema with this module.
  # XML::Compile::WSDL11 makes the argument that
  my $client = XML::Compile::WSDL11->new("$schema/wsdl");
  for my $xsd (<$schema/xsd*>) {
    $client->importDefinitions($xsd);
  }

  $client->compileCalls;
  my $self = {
    vendor_code => $vendor_code,
    password    => $password,
    client      => $client,
  };
  bless $self, $class;
}

# internal method: returns the authentication string (referred to as the 
# "hash" in the docs)

sub _auth {
  my $self = shift;

  my $now = DateTime->now;
  $now->set_time_zone('UTC');
  md5_hex($self->{vendor_code} .
    $self->{password} .
    $now->strftime('%Y%m%d')
  );
}

# internal method: dispatch a request to the service

sub _call {
  my $self = shift;
  $self->{client}->call(@_);
}

=item AddorUpdateCustomer OPTIONS

Adds or updates a customer.  Note the idiosyncratic capitalization; this
is the spelling of the underlying API method.  OPTIONS may include:

- PHONE_NUMBER: 10 digits, no punctuation
- FIRST_NAME: customer first name, up to 38 characters
- LAST_NAME: customer last name or company name, up to 100 characters
- STREET_NUMBER: up to 10 characters
- STREET_NAME: up to 84 characters
- CITY: up to 38 characters
- PROVINCE_STATE: 2 letter code
- POSTAL_CODE_ZIP: Canadian postal code or U.S. zip code
- OTHER_ADDRESS_INFO: up to 250 characters

Returns a L<WebService::Northern911::Result> object.

=cut

sub AddorUpdateCustomer {
  my $self = shift;
  my %opt = @_;
  my %customer = map { $_ => $opt{$_} }
  qw( PHONE_NUMBER FIRST_NAME LAST_NAME STREET_NUMBER STREET_NAME
      CITY PROVINCE_STATE POSTAL_CODE_ZIP OTHER_ADDRESS_INFO 
    );
  # according to Northern 911 support, this is for a future feature,
  # and should always be 'N' for now
  $customer{ENHANCED_CAPABLE} = 'N';

  $customer{VENDOR_CODE} = $self->{vendor_code};

  my ($answer, $trace) = $self->_call( 'AddorUpdateCustomer',
    hash => $self->_auth,
    customer => \%customer,
  );

  WebService::Northern911::Response->new($answer);
}

=item DeleteCustomer PHONE

Deletes a customer record.  PHONE must be the phone number (10 digits,
as in C<AddorUpdateCustomer>).

=cut

sub DeleteCustomer {
  my $self = shift;
  my $phone = shift;

  my ($answer, $trace) = $self->_call( 'DeleteCustomer',
    vendorCode => $self->{vendor_code},
    hash => $self->_auth,
    phoneNumber => $phone,
  );

  WebService::Northern911::Response->new($answer);
}

=item QueryCustomer PHONE

Queries a customer record.  PHONE must be the phone number.  The response
object will have a "customer" method which returns a hashref of customer
information, in the same format as the arguments to C<AddorUpdateCustomer>.

=cut

sub QueryCustomer {
  my $self = shift;
  my $phone = shift;

  my ($answer, $trace) = $self->_call( 'QueryCustomer',
    vendorCode => $self->{vendor_code},
    hash => $self->_auth,
    phoneNumber => $phone,
  );

  WebService::Northern911::Response->new($answer);
}

=item GetVendorDumpURL

Returns a URL to download a CSV dump of your customer data.  The response
object will have a 'url' method to return the URL.

Note that this feature is heavily throttled (at most once per week, unless
you pay for more frequent access) and the URL can only be used once.

=cut

sub GetVendorDumpURL {
  my $self = shift;

  my ($answer, $trace) = $self->_call( 'GetVendorDumpURL',
    vendorCode => $self->{vendor_code},
    hash => $self->_auth,
  );

  WebService::Northern911::Response->new($answer);
}

=back

=head1 AUTHOR

Mark Wells, <mark@freeside.biz>

Commercial support is available from Freeside Internet Services, Inc.

=head1 COPYRIGHT

Copyright (c) 2014 Mark Wells

=cut

1;
