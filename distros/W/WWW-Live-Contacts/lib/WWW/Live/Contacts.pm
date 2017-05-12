package WWW::Live::Contacts;

use strict;
use warnings;

use HTTP::Date qw(str2time time2str);
use Carp;

require WWW::Live::Contacts::Contact;
require WWW::Live::Contacts::Collection;
require LWP::UserAgent;
require HTTP::Request;
require XML::Simple;

our $VERSION = '1.0.1';
our $CONTACTS_BASE_URL = 'https://livecontacts.services.live.com/users/@C@%s/rest/livecontacts';
our $FORCED_ARRAY = [ 'Email', 'Phone', 'Location', 'Contact', 'IMAddress' ];

sub new {
  my ( $proto, %options ) = @_;
  my $class = ref $proto || $proto;
  
  my $consent_token = delete $options{'consent_token'};
  my $debug         = delete $options{'debug'};
  $consent_token || croak 'No consent token provided';
  $consent_token->isa('WWW::Live::Auth::ConsentToken') || croak 'Consent token is not an object';
  
  $options{'agent'} ||= __PACKAGE__ . "/$VERSION";
  
  my $self = bless {
    '_ua' => LWP::UserAgent->new( %options ),
    '_xs' => XML::Simple->new( KeyAttr    => [],
                               NoAttr     => 1,
                               ForceArray => $FORCED_ARRAY,
                               SuppressEmpty => undef,
                               NoSort     => 1 ),
    'consent_token' => $consent_token,
  }, $class;
  $self->{'_debug'} = 1 if ( $debug );
  
  return $self;
}

sub proxy {
  my $self = shift;
  return $self->{'_ua'}->proxy( 'https', shift );
}

sub get_contacts {
  my ( $self, %args ) = @_;
  my $filter = $args{'filter'} ? '?filter=' . $args{'filter'} : '';
  my $response = $self->_read_request( "/Contacts$filter", $args{'modified_since'} );
  
  my @contacts = ();
  if ( $response->code == 200 ) {
    my $hash = $self->{'_xs'}->XMLin( $response->content );
    @contacts = map {
      WWW::Live::Contacts::Contact->new_from_hashref( $_ )
    } @{ $hash->{'Contact'} || [] };
  }
  
  return WWW::Live::Contacts::Collection->new(
    entries  => \@contacts,
    response => $response,
  );
}

sub get_contact {
  my ( $self, $id, $filter ) = @_;
  $filter = $filter ? "?filter=$filter" : '';
  my $response = $self->_read_request( "/contacts/contact($id)$filter" );
  my $hash = $self->{'_xs'}->XMLin( $response->content );
  return WWW::Live::Contacts::Contact->new_from_hashref( $hash );
}

# NOTE: This method is not atomic This is because the API does not support
# multiple or hierarchical updates, and therefore each contact and each child is
# submitted independently. For example, a contact with 2 emails, 1 address and 1
# phone number is submitted using 5 separate requests.
sub write_contacts {
  my ( $self, @contacts ) = @_;
  
  for my $contact ( @contacts ) {
    # If the contact already has an ID, we need to update/delete it
    if ( my $id = $contact->id ) {
      if ( $contact->is_deleted ) {
        $self->_write_request( 'DELETE', "/Contacts/Contact($id)" );
        next;
      }
      my $xml = $self->{'_xs'}->XMLout( $contact->updateable_copy, RootName => 'Contact' );
      $self->_write_request( 'PUT', "/Contacts/Contact($id)", $xml );
    }
    # Otherwise it needs to be inserted
    else {
      my $xml  = $self->{'_xs'}->XMLout( $contact->createable_copy, RootName => 'Contact' );
      my $resp = $self->_write_request( 'POST', '/Contacts', $xml );
      my ($id) = $resp->header('Location') =~ m/Contact\((.+)\)/;
      $contact->id( $id );
    }
    
    # Insert, update or delete any children
    $self->write_emails    ( $contact->id, $contact->emails    );
    $self->write_phones    ( $contact->id, $contact->phones    );
    $self->write_addresses ( $contact->id, $contact->addresses );
  }
  
  return 1;
}

# The API only allows the submission of one element at a time, unfortunately.
sub write_emails {
  my ( $self, $contact_id, @objects ) = @_;

  for my $object ( @objects ) {
    # If the child object has an ID, it must be updated
    if (my $ob_id = $object->id) {
      if ( $object->is_deleted ) {
        $self->_delete_child( $contact_id, $object->id, 'Email' );
      } else {
        $self->_update_child( $contact_id, $object, 'Email' );
      }
    }
    # Otherwise it must be inserted
    else {
      $self->_insert_child( $contact_id, $object, 'Email' );
    }
  }

  return 1;
}

# The API only allows the submission of one element at a time, unfortunately.
sub write_phones {
  my ( $self, $contact_id, @objects ) = @_;

  for my $object ( @objects ) {
    # If the child object has an ID, it must be updated
    if (my $ob_id = $object->id) {
      if ( $object->is_deleted ) {
        $self->_delete_child( $contact_id, $object->id, 'Phone' );
      } else {
        $self->_update_child( $contact_id, $object, 'Phone' );
      }
    }
    # Otherwise it must be inserted
    else {
      $self->_insert_child( $contact_id, $object, 'Phone' );
    }
  }

  return 1;
}

# The API only allows the submission of one element at a time, unfortunately.
sub write_addresses {
  my ( $self, $contact_id, @objects ) = @_;

  for my $object ( @objects ) {
    # If the child object has an ID, it must be updated
    if (my $ob_id = $object->id) {
      if ( $object->is_deleted ) {
        $self->_delete_child( $contact_id, $object->id, 'Location' );
      } else {
        $self->_update_child( $contact_id, $object, 'Location' );
      }
    }
    # Otherwise it must be inserted
    else {
      $self->_insert_child( $contact_id, $object, 'Location' );
    }
  }

  return 1;
}

sub delete_contacts {
  my ( $self, @contact_ids ) = @_;
  for my $id ( @contact_ids ) {
    $self->_write_request( 'DELETE', "/Contacts/Contact($id)" );
  }
  return 1;
}

sub delete_emails {
  my ( $self, $contact_id, @object_ids ) = @_;
  for my $object_id ( @object_ids ) {
    $self->_delete_child( $contact_id, $object_id, 'Email' );
  }
  return 1;
}

sub delete_phones {
  my ( $self, $contact_id, @object_ids ) = @_;
  for my $object_id ( @object_ids ) {
    $self->_delete_child( $contact_id, $object_id, 'Phone' );
  }
  return 1;
}

sub delete_addresses {
  my ( $self, $contact_id, @object_ids ) = @_;
  for my $object_id ( @object_ids ) {
    $self->_delete_child( $contact_id, $object_id, 'Location' );
  }
  return 1;
}

sub _update_child {
  my ( $self, $contact_id, $object, $type ) = @_;
  my $xml = $self->{'_xs'}->XMLout( $object->updateable_copy, RootName => ucfirst $type );
  my $uri = sprintf '/Contacts/Contact(%s)/%ss/%2$s(%s)', $contact_id, $type, $object->id;
  return $self->_write_request( 'PUT', $uri, $xml );
}

sub _insert_child {
  my ( $self, $contact_id, $object, $type ) = @_;
  my $xml = $self->{'_xs'}->XMLout( $object->createable_copy, RootName => ucfirst $type );
  my $uri = sprintf '/Contacts/Contact(%s)/%ss', $contact_id, $type;
  my $resp = $self->_write_request( 'POST', $uri, $xml );
  my ($id) = $resp->header('Location') =~ m/$type\((.+)\)/;
  $object->id( $id );
  return $resp;
}

sub _delete_child {
  my ( $self, $contact_id, $object_id, $type ) = @_;
  my $uri = sprintf '/Contacts/Contact(%s)/%ss/%2$s(%s)', $contact_id, $type, $object_id; 
  return $self->_write_request( 'DELETE', $uri );
}

sub _read_request {
  my ( $self, $relative_uri, $modified_date ) = @_;

  $relative_uri || die 'Call to _read_request requires a relative URI argument';

  # Build the request
  my $auth    = sprintf 'DelegatedToken dt="%s"',
                        $self->{'consent_token'}->delegation_token;
  my $uri     = sprintf "$CONTACTS_BASE_URL$relative_uri",
                        $self->{'consent_token'}->int_location_id;
  my $request = HTTP::Request->new('GET', $uri);
  $request->header( 'Authorization' => $auth );
  $request->header( 'Pragma' => 'no-cache' );
  $request->header( 'Cache-Control' => 'no-cache' );

  if ( $self->{'_debug'} ) {
    warn "About to GET $uri";
    warn "If-Modified-Since: " . ($modified_date || 'none');
    warn "Authorization: $auth";
  }

  if ( $modified_date ) {
    # make sure it's in the right format
    if ( $modified_date =~ /^\d+$/ ) {
      $modified_date = time2str( $modified_date );
    } elsif ( $modified_date !~ /^[A-Z][a-z]{2}, \d{2} [A-Z][a-z]{2} \d{4} \d{2}:\d{2}:\d{2} [A-Z]{3}$/ ) {
      $modified_date = time2str( str2time( $modified_date ) );
    }
    $request->header( 'If-Modified-Since' => $modified_date );
  }
  
  # Make the request to the server
  my $response = $self->{'_ua'}->request( $request );
  if ( !$response->is_success && $response->code != 304 ) { # "not modified"
    croak( $self->_get_error( $response ) );
  }
  return $response;
}

sub _write_request {
  my ( $self, $method, $relative_uri, $xml ) = @_;
  
  # Build the request
  my $auth    = sprintf 'DelegatedToken dt="%s"',
                        $self->{'consent_token'}->delegation_token;
  my $uri     = sprintf "$CONTACTS_BASE_URL$relative_uri",
                        $self->{'consent_token'}->int_location_id;
  my $request = HTTP::Request->new($method, $uri);
  $request->header( 'Authorization' => $auth );
  
  $self->{'_debug'} && warn "$method $uri";
  if ($xml) {
    $request->header( 'Content-Type', "application/xml; charset=utf-8");
    $request->content( $xml );
  }
  
  # Make the request to the server
  my $response = $self->{'_ua'}->request( $request );
  if ( !$response->is_success ) {
    croak( $self->_get_error( $response ) );
  }
  
  return $response;
}

sub _get_error {
  my ( $self, $response ) = @_;
  if ($response->code eq '405') {
    return $response->status_line . '. Allowed: ' . $response->header('Allow');
  }
  return $response->status_line;
}

1;
__END__

=head1 NAME

WWW::Live::Contacts - A Microsoft Live Contacts client

=head1 VERSION

1.0.1

=head1 DESCRIPTION

Provides access to the Microsoft Live Contacts web services API.

=head1 SYNOPSIS

  # Construct a client object
  my $client = WWW::Live::Contacts->new(
    consent_token => $token, # See WWW::Live::Auth
    %lwp_params              # Constructor parameters for LWP::UserAgent
  );

  # Set the proxy (if necessary)
  $client->proxy( 'http', 'http://proxy.mycompany.com' );

  # Retrieve contacts
  for my $contact ( $client->get_contacts()->entries() ) {
    print $contact->full_name();
  }

  # Add contacts
  my $contact = WWW::Live::Contacts::Contact->new();
  $contact->first( 'Andrew'    );
  $contact->last ( 'Jenkinson' );
  $client->write_contacts( $contact );

  # Update contacts
  $contact->work_email()->address( 'foo@bar.com' );
  $contact->add_address( $address );
  $contact->home_phone()->mark_deleted();
  $client->write_contacts( $contact );

  # Delete contacts
  $client->delete_contacts( $contact->id );
  # OR
  $contact->mark_deleted();
  $client->write_contacts( $contact );

=head1 METHODS

=head2 new

  Constructs a new client object representing the address book of a single user.
  Requires a consent token, and optionally accepts LWP::UserAgent parameters.

  my $client = WWW::Live::Contacts->new(
    consent_token => $token,
    %lwp_params
  );

=head2 proxy

  Passes proxy settings through to LWP::UserAgent. Note the proxy must accept
  HTTPS connections.

  $client->proxy( 'http://proxy.mycompany.com' );

=head2 get_contacts

  Gets the full set of contacts.

  my $collection = $client->get_contacts(
    filter         => 'LiveContacts(Contact(ID))', # fields to populate
    modified_since => $date                        # string or unix time
  );
  if ( $collection->is_modified ) {
    # ... do something with the contacts
  }

  Contacts are populated with data according to a given filter. If the filter is
  not specified, the API default is used. If some data has changed since the
  'modified_since' parameter, or no such parameter is specified, all contacts
  are returned. Otherwise no contacts are returned. This behaviour makes it
  possible to deduce if deletes have taken place.
  
  This method returns a WWW::Live::Contacts::Collection object holding the
  contacts and the last modified date of the collection.

=head2 get_contact

  Gets a single contact by its ID, with all available data.

  my $contact = $client->get_contact( $contact_ID );

=head2 write_contacts

  Inserts/updates/deletes the given contacts, according to their states.

  $client->write_contacts( $new_contact, $updated_contact );

  Each contact is processed in full, including all its children (emails etc).

=head2 write_emails

  Inserts/updates/deletes the given email addresses, according to their states.

  $client->write_emails( $contact_ID, @emails );

=head2 write_phones

  Inserts/updates/deletes the given phone numbers, according to their states.

  $client->write_phones( $contact_ID, @phones );

=head2 write_addresses

  Inserts/updates/deletes the given addresses, according to their states.

  $client->write_addresses( $contact_ID, @addresses );

=head2 delete_contacts

  Deletes one or more contacts.

  $client->delete_contacts( @contact_IDs );

=head2 delete_emails

  Deletes one or more email addresses.

  $client->delete_emails( $contact_ID, @email_IDs );

=head2 delete_phones

  Deletes one or more phone numbers.

  $client->delete_phones( $contact_ID, @phone_IDs );

=head2 delete_addresses

  Deletes one or more addresses.

  $client->delete_addresses( $contact_ID, @address_IDs );

=head1 AUTHOR

Andrew M. Jenkinson <jenkinson@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2008-2011 Andrew M. Jenkinson.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=head1 LIMITATIONS

The Windows Live Contacts API does not support inserting or updating multiple
"collection" entities in the same request. A collection entity is a data type
of which there can be more than one (e.g. contacts, emails, phones, addresses).
As a result, calls to the write_* methods are performed using several requests
and thus are NOT atomic. A delete of a single contact is an atomic action,
however.

=head1 DEPENDENCIES

L<WWW::Live::Auth>
L<LWP::UserAgent>
L<HTTP::Date>
L<Carp>

=head1 SEE ALSO

L<WWW::Live::Auth>

L<LWP::UserAgent>

=cut
