package WWW::Salesforce;

use strict;
use warnings;

use SOAP::Lite;    # ( +trace => 'all', readable => 1, );#, outputxml => 1, );
use DateTime;
# use Data::Dumper;
use WWW::Salesforce::Constants;
use WWW::Salesforce::Deserializer;
use WWW::Salesforce::Serializer;

our $VERSION = '0.302';
$VERSION = eval $VERSION;

our $SF_PROXY       = 'https://login.salesforce.com/services/Soap/u/8.0';
our $SF_URI         = 'urn:partner.soap.sforce.com';
our $SF_PREFIX      = 'sforce';
our $SF_SOBJECT_URI = 'urn:sobject.partner.soap.sforce.com';
our $SF_URIM        = 'http://soap.sforce.com/2006/04/metadata';
our $SF_APIVERSION  = '23.0';
# set webproxy if firewall blocks port 443 to SF_PROXY
our $WEB_PROXY  = ''; # e.g., http://my.proxy.com:8080


=encoding utf8

=head1 NAME

WWW::Salesforce - this class provides a simple abstraction layer between SOAP::Lite and Salesforce.com.

=head1 SYNOPSIS

    use WWW::Salesforce;
    my $sforce = eval { WWW::Salesforce->login( username => 'foo',
                                                password => 'bar' ); };
    die "Could not login to SFDC: $@" if $@;

    # eval, eval, eval.  WWW::Salesforce uses a SOAP connection to
    # salesforce.com, so things can go wrong unexpectedly.  Be prepared
    # by eval'ing and handling any exceptions that occur.

=head1 DESCRIPTION

This class provides a simple abstraction layer between SOAP::Lite and Salesforce.com. Because SOAP::Lite does not support complexTypes, and document/literal encoding is limited, this module works around those limitations and provides a more intuitive interface a developer can interact with.

=head1 CONSTRUCTORS

=head2 new( HASH )

Synonym for C<login>

=cut

sub new {
    return login(@_);
}


=head2 login( HASH )

The C<login> method returns an object of type WWW::Salesforce if the login attempt was successful, and C<0> otherwise. Upon a successful login, the C<sessionId> is saved and the serverUrl set properly so that developers need not worry about setting these values manually. Upon failure, the method dies with an error string.

The following are the accepted input parameters:

=over

=item username

A Salesforce.com username.

=item password

The password for the user indicated by C<username>.

=back

=cut

sub login {
    my $class = shift;
    my (%params) = @_;

    unless ( defined $params{'username'} and length $params{'username'} ) {
        die("WWW::Salesforce::login() requires a username");
    }
    unless ( defined $params{'password'} and length $params{'password'} ) {
        die("WWW::Salesforce::login() requires a password");
    }
    my $self = {
        sf_user      => $params{'username'},
        sf_pass      => $params{'password'},
        sf_serverurl => $SF_PROXY,
        sf_sid       => undef,                 #session ID
    };
    $self->{'sf_serverurl'} = $params{'serverurl'}
      if ( $params{'serverurl'} && length( $params{'serverurl'} ) );
    bless $self, $class;

    my $client = $self->_get_client();
    my $r      = $client->login(
        SOAP::Data->name( 'username' => $self->{'sf_user'} ),
        SOAP::Data->name( 'password' => $self->{'sf_pass'} )
    );
    unless ($r) {
        die sprintf( "could not login, user %s, pass %s",
            $self->{'sf_user'}, $self->{'sf_pass'} );
    }
    if ( $r->fault() ) {
        die( $r->faultstring() );
    }

    $self->{'sf_sid'}       = $r->valueof('//loginResponse/result/sessionId');
    $self->{'sf_uid'}       = $r->valueof('//loginResponse/result/userId');
    $self->{'sf_serverurl'} = $r->valueof('//loginResponse/result/serverUrl');
    $self->{'sf_metadataServerUrl'} = $r->valueof('//loginResponse/result/metadataServerUrl');
    return $self;
}



=head1 METHODS

=head2 convertLead( HASH )

The C<convertLead> method returns an object of type SOAP::SOM if the login attempt was successful, and 0 otherwise.

Converts a Lead into an Account, Contact, or (optionally) an Opportunity

The following are the accepted input parameters:

=over

=item %hash_of_array_references

    leadId => [ 2345, 5678, ],
    contactId => [ 9876, ],

=back

=cut

sub convertLead {
    my $self = shift;
    my (%in) = @_;

    if ( !keys %in ) {
        die("Expected a hash of arrays.");
    }

    #take in data to be passed in our call
    my @data;
    for my $key ( keys %in ) {
        if ( ref( $in{$key} ) eq 'ARRAY' ) {
            for my $elem ( @{ $in{$key} } ) {
                my $dat = SOAP::Data->name( $key => $elem );
                push @data, $dat;
            }
        }
        else {
            my $dat = SOAP::Data->name( $key => $in{$key} );
            push @data, $dat;
        }
    }
    if ( scalar @data < 1 || scalar @data > 200 ) {
        die("convertLead converts up to 200 objects, no more.");
    }

    #got the data lined up, make the call
    my $client = $self->_get_client(1);
    my $r      = $client->convertLead(
        SOAP::Data->name( "leadConverts" => \SOAP::Data->value(@data) ),
        $self->_get_session_header() );

    unless ($r) {
        die "cound not convertLead";
    }
    if ( $r->fault() ) {
        die( $r->faultstring() );
    }
    return $r;
}

=head2 create( HASH )

Adds one new individual objects to your organization's data. This takes as input a HASH containing the fields (the keys of the hash) and the values of the record you wish to add to your organization.
The hash must contain the 'type' key in order to identify the type of the record to add.

Returns a SOAP::Lite object.  Success of this operation can be gleaned from
the envelope result.

    $r->envelope->{Body}->{createResponse}->{result}->{success};

=cut

sub create {
    my $self = shift;
    my (%in) = @_;

    if ( !keys %in ) {
        die("Expected a hash of arrays.");
    }
    my $client = $self->_get_client(1);
    my $method =
      SOAP::Data->name("create")->prefix($SF_PREFIX)->uri($SF_URI)
      ->attr( { 'xmlns:sfons' => $SF_SOBJECT_URI } );

    my $type = $in{'type'};
    delete( $in{'type'} );

    my @elems;
    foreach my $key ( keys %in ) {
        push @elems,
          SOAP::Data->prefix('sfons')->name( $key => $in{$key} )
          ->type( WWW::Salesforce::Constants->type( $type, $key ) );
    }

    my $r = $client->call(
        $method => SOAP::Data->name( 'sObjects' => \SOAP::Data->value(@elems) )
          ->attr( { 'xsi:type' => 'sfons:' . $type } ),
        $self->_get_session_header()
    );
    unless ($r) {
        die "could not call method $method";
    }
    if ( $r->fault() ) {
        die( $r->faultstring() );
    }
    return $r;
}


=head2 delete( ARRAY )

Deletes one or more individual objects from your organization's data.
This subroutine takes as input an array of SCALAR values, where each SCALAR is an C<sObjectId>.

=cut

sub delete {
    my $self = shift;

    my $client = $self->_get_client(1);
    my $method = SOAP::Data->name("delete")->prefix($SF_PREFIX)->uri($SF_URI);

    my @elems;
    foreach my $id (@_) {
        push @elems, SOAP::Data->name( 'ids' => $id )->type('tns:ID');
    }

    if ( scalar @elems < 1 || scalar @elems > 200 ) {
        die("delete takes anywhere from 1 to 200 ids to delete.");
    }

    my $r = $client->call(
        $method => @elems,
        $self->_get_session_header()
    );
    unless ($r) {
        die "could not call method $method";
    }
    if ( $r->fault() ) {
        die( $r->faultstring() );
    }
    return $r;
}


=head2 describeGlobal()

Retrieves a list of available objects for your organization's data.
You can then iterate through this list and use C<describeSObject()> to obtain metadata about individual objects.
This method calls the Salesforce L<describeGlobal method|https://developer.salesforce.com/docs/atlas.en-us.api.meta/api/sforce_api_calls_describeglobal.htm>.

=cut

sub describeGlobal {
    my $self = shift;

    my $client = $self->_get_client(1);
    my $method =
      SOAP::Data->name("describeGlobal")->prefix($SF_PREFIX)->uri($SF_URI);

    my $r = $client->call( $method, $self->_get_session_header() );
    unless ($r) {
        die "could not call method $method";
    }
    if ( $r->fault() ) {
        die( $r->faultstring() );
    }
    return $r;
}

=head2 describeLayout( HASH )

Describes metadata about a given page layout, including layouts for edit and display-only views and record type mappings.

=over

=item type

The type of the object you wish to have described.

=back

=cut

sub describeLayout {
    my $self = shift;
    my (%in) = @_;

    if ( !defined $in{'type'} or !length $in{'type'} ) {
        die("Expected hash with key 'type'");
    }
    my $client = $self->_get_client(1);
    my $method =
      SOAP::Data->name("describeLayout")->prefix($SF_PREFIX)->uri($SF_URI);
    my $r = $client->call(
        $method =>
          SOAP::Data->prefix($SF_PREFIX)->name( 'sObjectType' => $in{'type'} )
          ->type('xsd:string'),
        $self->_get_session_header()
    );
    unless ($r) {
        die "could not call method $method";
    }
    if ( $r->fault() ) {
        die( $r->faultstring() );
    }
    return $r;
}


=head2 describeSObject( HASH )

Describes metadata (field list and object properties) for the specified object.

=over

=item type

The type of the object you wish to have described.

=back

=cut

sub describeSObject {
    my $self = shift;
    my (%in) = @_;

    if ( !defined $in{'type'} or !length $in{'type'} ) {
        die("Expected hash with key 'type'");
    }

    my $client = $self->_get_client(1);
    my $method =
      SOAP::Data->name("describeSObject")->prefix($SF_PREFIX)->uri($SF_URI);

    my $r = $client->call(
        $method =>
          SOAP::Data->prefix($SF_PREFIX)->name( 'sObjectType' => $in{'type'} )
          ->type('xsd:string'),
        $self->_get_session_header()
    );
    unless ($r) {
        die "could not call method $method";
    }
    if ( $r->fault() ) {
        die( $r->faultstring() );
    }
    return $r;
}

=head2 describeSObjects( type => ['Account','Contact','CustomObject__c'] )

An array based version of describeSObject; describes metadata (field list and object properties) for the specified object or array of objects.

=cut

sub describeSObjects {
    my $self = shift;
    my %in   = @_;

    if (  !defined $in{type}
        or ref $in{type} ne 'ARRAY'
        or !scalar @{ $in{type} } )
    {
        die "Expected hash with key 'type' containing array reference";
    }

    my $client = $self->_get_client(1);
    my $method =
      SOAP::Data->name("describeSObjects")->prefix($SF_PREFIX)->uri($SF_URI);

    my $r = $client->call(
        $method => SOAP::Data->prefix($SF_PREFIX)->name('sObjectType')
          ->value( @{ $in{'type'} } )->type('xsd:string'),
        $self->_get_session_header()
    );

    unless ($r) {
        die "could not execute method $method";
    }
    if ( $r->fault() ) {
        die( $r->faultstring() );
    }
    return $r;
}

=head2 describeTabs()

Use the C<describeTabs> call to obtain information about the standard and custom apps to which the logged-in user has access. The C<describeTabs> call returns the minimum required metadata that can be used to render apps in another user interface. Typically this call is used by partner applications to render Salesforce data in another user interface.

=cut

sub describeTabs {
    my $self   = shift;
    my $client = $self->_get_client(1);
    my $method =
      SOAP::Data->name("describeTabs")->prefix($SF_PREFIX)->uri($SF_URI);

    my $r = $client->call( $method, $self->_get_session_header() );
    unless ($r) {
        die "could not call method $method";
    }
    if ( $r->fault() ) {
        die( $r->faultstring() );
    }
    return $r;
}

# TODO: remove in version 0.400
sub get_client {
    warn "The method: get_client() has always been private. It is now deprecated and will be removed in version 0.400.";
    return shift->_get_client(@_);
}

# TODO: remove in version 0.400
sub get_session_header {
    warn "The method: get_session_header() has always been private. It is now deprecated and will be removed in version 0.400.";
    return shift->_get_session_header(@_);
}


=head2 get_session_id()

Gets the Salesforce SID

=cut

sub get_session_id {
    my ($self) = @_;

    return $self->{sf_sid};
}


=head2 get_user_id()

Gets the Salesforce UID

=cut

sub get_user_id {
    my ($self) = @_;

    return $self->{sf_uid};
}


=head2 get_username()

Gets the Salesforce Username

=cut

sub get_username {
    my ($self) = @_;

    return $self->{sf_user};
}


=head2 getDeleted( HASH )

Retrieves the list of individual objects that have been deleted within the given time span for the specified object.

=over

=item type

Identifies the type of the object you wish to find deletions for.

=item start

A string identifying the start date/time for the query

=item end

A string identifying the end date/time for the query

=back

=cut

sub getDeleted {
    my $self = shift;
    my (%in) = @_;

    if ( !defined $in{'type'} || !length $in{'type'} ) {
        die("Expected hash with key of 'type'");
    }
    if ( !defined $in{'start'} || !length $in{'start'} ) {
        die("Expected hash with key of 'start' which is a date");
    }
    if ( !defined $in{'end'} || !length $in{'end'} ) {
        die("Expected hash with key of 'end' which is a date");
    }

    my $client = $self->_get_client(1);
    my $method =
      SOAP::Data->name("getDeleted")->prefix($SF_PREFIX)->uri($SF_URI);
    my $r = $client->call(
        $method =>
          SOAP::Data->prefix($SF_PREFIX)->name( 'sObjectType' => $in{'type'} )
          ->type('xsd:string'),
        SOAP::Data->prefix($SF_PREFIX)->name( 'startDate' => $in{'start'} )
          ->type('xsd:dateTime'),
        SOAP::Data->prefix($SF_PREFIX)
          ->name( 'endDate' => $in{'end'} )
          ->type('xsd:dateTime'),
        $self->_get_session_header()
    );
    unless ($r) {
        die "could not call method $method";
    }
    if ( $r->fault() ) {
        die( $r->faultstring() );
    }
    return $r;
}


=head2 getServerTimestamp()

Retrieves the current system timestamp (GMT) from the Salesforce web service.

=cut

sub getServerTimestamp {
    my $self   = shift;
    my $client = $self->_get_client(1);
    my $r      = $client->getServerTimestamp( $self->_get_session_header() );
    unless ($r) {
        die "could not getServerTimestamp";
    }
    if ( $r->fault() ) {
        die( $r->faultstring() );
    }
    return $r;
}

=head2 getUpdated( HASH )

Retrieves the list of individual objects that have been updated (added or changed) within the given time span for the specified object.

=over

=item type

Identifies the type of the object you wish to find updates for.

=item start

A string identifying the start date/time for the query

=item end

A string identifying the end date/time for the query

=back

=cut

sub getUpdated {
    my $self = shift;
    my (%in) = @_;

    if ( !defined $in{'type'} || !length $in{'type'} ) {
        die("Expected hash with key of 'type'");
    }
    if ( !defined $in{'start'} || !length $in{'start'} ) {
        die("Expected hash with key of 'start' which is a date");
    }
    if ( !defined $in{'end'} || !length $in{'end'} ) {
        die("Expected hash with key of 'end' which is a date");
    }

    my $client = $self->_get_client(1);
    my $method =
      SOAP::Data->name("getUpdated")->prefix($SF_PREFIX)->uri($SF_URI);
    my $r = $client->call(
        $method =>
          SOAP::Data->prefix($SF_PREFIX)->name( 'sObjectType' => $in{'type'} )
          ->type('xsd:string'),
        SOAP::Data->prefix($SF_PREFIX)->name( 'startDate' => $in{'start'} )
          ->type('xsd:dateTime'),
        SOAP::Data->prefix($SF_PREFIX)
          ->name( 'endDate' => $in{'end'} )
          ->type('xsd:dateTime'),
        $self->_get_session_header()
    );
    unless ($r) {
        die "could not call method $method";
    }
    if ( $r->fault() ) {
        die( $r->faultstring() );
    }
    return $r;
}


=head2 getUserInfo( HASH )

Retrieves personal information for the user associated with the current session.

=over

=item user

A user ID

=back

=cut

sub getUserInfo {
    my $self   = shift;
    my $client = $self->_get_client(1);
    my $r      = $client->getUserInfo( $self->_get_session_header() );
    unless ($r) {
        die "could not getUserInfo";
    }
    if ( $r->fault() ) {
        die( $r->faultstring() );
    }
    return $r;
}

=head2 logout()

Ends the session for the logged-in user issuing the call. No arguments are needed.
Useful to avoid hitting the limit of ten open sessions per login.
L<Logout API Call|http://www.salesforce.com/us/developer/docs/api/Content/sforce_api_calls_logout.htm>

=cut

sub logout {
    my $self = shift;

    my $client = $self->_get_client(1);
    my $method =
      SOAP::Data->name("logout")->prefix($SF_PREFIX)->uri($SF_URI);
    my $r = $client->call( $method, $self->_get_session_header() );
    unless ($r) {
        die "could not call method $method";
    }
    if ( $r->fault() ) {
        die( $r->faultstring() );
    }
    return $r;
}



=head2 query( HASH )

Executes a query against the specified object and returns data that matches the specified criteria.

=over

=item query

The query string to use for the query. The query string takes the form of a I<basic> SQL statement. For example, "SELECT Id,Name FROM Account".

=item limit

This sets the batch size, or size of the result returned. This is helpful in producing paginated results, or fetch small sets of data at a time.

=back

=cut

sub query {
    my $self = shift;
    my (%in) = @_;
    if ( !defined $in{'query'} || !length $in{'query'} ) {
        die("A query is needed for the query() method.");
    }
    if ( !defined $in{'limit'} || $in{'limit'} !~ m/^\d+$/ ) {
        $in{'limit'} = 500;
    }
    if ( $in{'limit'} < 1 || $in{'limit'} > 2000 ) {
        die("A query's limit cannot exceed 2000. 500 is default.");
    }

    my $limit = SOAP::Header->name(
        'QueryOptions' => \SOAP::Header->name( 'batchSize' => $in{'limit'} ) )
      ->prefix($SF_PREFIX)->uri($SF_URI);
    my $client = $self->_get_client();
    my $r = $client->query( SOAP::Data->type( 'string' => $in{'query'} ),
        $limit, $self->_get_session_header() );

    unless ($r) {
        die "could not query " . $in{'query'};
    }
    if ( $r->fault() ) {
        die( $r->faultstring() );
    }
    return $r;
}


=head2 queryAll( HASH )

Executes a query against the specified object and returns data that matches the
specified criteria including archived and deleted objects.

=over

=item query

The query string to use for the query. The query string takes the form of a I<basic> SQL statement. For example, "SELECT Id,Name FROM Account".

=item limit

This sets the batch size, or size of the result returned. This is helpful in producing paginated results, or fetch small sets of data at a time.

=back

=cut

sub queryAll {
    my $self = shift;
    my (%in) = @_;
    if ( !defined $in{'query'} || !length $in{'query'} ) {
        die("A query is needed for the query() method.");
    }
    if ( !defined $in{'limit'} || $in{'limit'} !~ m/^\d+$/ ) {
        $in{'limit'} = 500;
    }
    if ( $in{'limit'} < 1 || $in{'limit'} > 2000 ) {
        die("A query's limit cannot exceed 2000. 500 is default.");
    }

    my $limit = SOAP::Header->name(
        'QueryOptions' => \SOAP::Header->name( 'batchSize' => $in{'limit'} ) )
      ->prefix($SF_PREFIX)->uri($SF_URI);
    my $client = $self->_get_client();
    my $r = $client->queryAll( SOAP::Data->name( 'queryString' => $in{'query'} ),
        $limit, $self->_get_session_header() );

    unless ($r) {
        die "could not query " . $in{'query'};
    }
    if ( $r->fault() ) {
        die( $r->faultstring() );
    }
    return $r;
}


=head2 queryMore( HASH )

Retrieves the next batch of objects from a C<query> or C<queryAll>.

=over

=item queryLocator

The handle or string returned by C<query>. This identifies the result set and cursor for fetching the next set of rows from a result set.

=item limit

This sets the batch size, or size of the result returned. This is helpful in producing paginated results, or fetch small sets of data at a time.

=back

=cut

sub queryMore {
    my $self = shift;
    my (%in) = @_;
    if ( !defined $in{'queryLocator'} || !length $in{'queryLocator'} ) {
        die("A hash expected with key 'queryLocator'");
    }
    $in{'limit'} = 500
      if ( !defined $in{'limit'} || $in{'limit'} !~ m/^\d+$/ );
    if ( $in{'limit'} < 1 || $in{'limit'} > 2000 ) {
        die("A query's limit cannot exceed 2000. 500 is default.");
    }

    my $limit = SOAP::Header->name(
        'QueryOptions' => \SOAP::Header->name( 'batchSize' => $in{'limit'} ) )
      ->prefix($SF_PREFIX)->uri($SF_URI);
    my $client = $self->_get_client();
    my $r      = $client->queryMore(
        SOAP::Data->name( 'queryLocator' => $in{'queryLocator'} ),
        $limit, $self->_get_session_header() );

    unless ($r) {
        die "could not queryMore " . $in{'queryLocator'};
    }

    if ( $r->fault() ) {
        die( $r->faultstring() );
    }
    return $r;
}

=head2 resetPassword( HASH )

Changes a user's password to a server-generated value.

=over

=item userId

A user Id.

=back

=cut

sub resetPassword {
    my $self = shift;
    my (%in) = @_;

    if ( !defined $in{'userId'} || !length $in{'userId'} ) {
        die("A hash expected with key 'userId'");
    }

    my $client = $self->_get_client(1);
    my $method =
      SOAP::Data->name("resetPassword")->prefix($SF_PREFIX)->uri($SF_URI);
    my $r = $client->call(
        $method =>
          SOAP::Data->prefix($SF_PREFIX)->name( 'userId' => $in{'userId'} )
          ->type('xsd:string'),
        $self->_get_session_header()
    );

    unless ($r) {
        die "could not call method $method";
    }
    if ( $r->fault() ) {
        die( $r->faultstring() );
    }
    return $r;
}

=head2 retrieve( HASH )

=over

=item fields

A comma delimited list of field name you want retrieved.

=item type

The type of the object being queried.

=item ids

The ids (LIST) of the object you want returned.

=back

=cut

sub retrieve {
    my $self = shift;
    my (%in) = @_;

    $in{'limit'} = 500
      if ( !defined $in{'limit'} || $in{'limit'} !~ m/^\d+$/ );
    if ( $in{'limit'} < 1 || $in{'limit'} > 2000 ) {
        die("A query's limit cannot exceed 2000. 500 is default.");
    }
    if ( !defined $in{'fields'} || !length $in{'fields'} ) {
        die("Hash with key 'fields' expected.");
    }
    if ( !defined $in{'ids'} || !length $in{'ids'} ) {
        die("Hash with key 'ids' expected.");
    }
    if ( !defined $in{'type'} || !length $in{'type'} ) {
        die("Hash with key 'type' expected.");
    }

    my @elems;
    my $client = $self->_get_client(1);
    my $method = SOAP::Data->name("retrieve")->prefix($SF_PREFIX)->uri($SF_URI);
    foreach my $id ( @{ $in{'ids'} } ) {
        push( @elems,
            SOAP::Data->prefix($SF_PREFIX)->name( 'ids' => $id )
              ->type('xsd:string') );
    }
    my $r = $client->call(
        $method =>
          SOAP::Data->prefix($SF_PREFIX)->name( 'fieldList' => $in{'fields'} )
          ->type('xsd:string'),
        SOAP::Data->prefix($SF_PREFIX)->name( 'sObjectType' => $in{'type'} )
          ->type('xsd:string'),
        @elems,
        $self->_get_session_header()
    );

    unless ($r) {
        die "could not call method $method";
    }
    if ( $r->fault() ) {
        die( $r->faultstring() );
    }
    return $r;
}


=head2 search( HASH )

=over

=item searchString

The search string to be used in the query. For example,
C<< find {4159017000} in phone fields returning contact(id, phone, firstname, lastname), lead(id, phone, firstname, lastname), account(id, phone, name) >>

=back

=cut

sub search {
    my $self = shift;
    my (%in) = @_;

    if ( !defined $in{'searchString'} || !length $in{'searchString'} ) {
        die("Expected hash with key 'searchString'");
    }
    my $client = $self->_get_client(1);
    my $method = SOAP::Data->name("search")->prefix($SF_PREFIX)->uri($SF_URI);
    my $r      = $client->call(
        $method => SOAP::Data->prefix($SF_PREFIX)
          ->name( 'searchString' => $in{'searchString'} )->type('xsd:string'),
        $self->_get_session_header()
    );

    unless ($r) {
        die "could not search with " . $in{'searchString'};
    }
    if ( $r->fault() ) {
        die( $r->faultstring() );
    }
    return $r;
}


=head2 setPassword( HASH )

Sets the specified user's password to the specified value.

=over

=item userId

A user Id.

=item password

The new password to assign to the user identified by C<userId>.

=back

=cut

sub setPassword {
    my $self = shift;
    my (%in) = @_;

    if ( !defined $in{'userId'} || !length $in{'userId'} ) {
        die("Expected a hash with key 'userId'");
    }
    if ( !defined $in{'password'} || !length $in{'password'} ) {
        die("Expected a hash with key 'password'");
    }

    my $client = $self->_get_client(1);
    my $method =
      SOAP::Data->name("setPassword")->prefix($SF_PREFIX)->uri($SF_URI);
    my $r = $client->call(
        $method =>
          SOAP::Data->prefix($SF_PREFIX)->name( 'userId' => $in{'userId'} )
          ->type('xsd:string'),
        SOAP::Data->prefix($SF_PREFIX)->name( 'password' => $in{'password'} )
          ->type('xsd:string'),
        $self->_get_session_header()
    );

    unless ($r) {
        die "could not call method $method";
    }
    if ( $r->fault() ) {
        die( $r->faultstring() );
    }
    return $r;
}


=head2 sf_date

Converts a time in Epoch seconds to the date format that Salesforce likes

=cut

sub sf_date {
    my $self = shift;
    my $secs = shift || time;
    my $dt = DateTime->from_epoch(epoch=>$secs);
    $dt->set_time_zone('local');
    return $dt->strftime(q(%FT%T.%3N%z));
}


=head2 update(type => $type, HASHREF [, HASHREF ...])

Updates one or more existing objects in your organization's data. This subroutine takes as input a B<type> value which names the type of object to update (e.g. Account, User) and one or more perl HASH references containing the fields (the keys of the hash) and the values of the record that will be updated.

The hash must contain the 'Id' key in order to identify the record to update.

=cut

sub update {
    my $self = shift;

    my ( $spec, $type ) = splice @_, 0, 2;
    if ( $spec ne 'type' || !$type ) {
        die("Expected a hash with key 'type' as first argument");
    }

    my %tmp      = ();
    my @sobjects = @_;
    if ( ref $sobjects[0] ne 'HASH' ) {
        %tmp      = @_;
        @sobjects = ( \%tmp );    # create an array of one
    }

    my @updates;
    foreach (@sobjects) {         # arg list is now an array of hash refs
        my %in = %{$_};

        my $id = $in{'id'};
        delete( $in{'id'} );
        if ( !$id ) {
            die("Expected a hash with key 'id'");
        }

        my @elems;
        my @fieldsToNull;
        push @elems,
          SOAP::Data->prefix($SF_PREFIX)->name( 'Id' => $id )
          ->type('sforce:ID');
        foreach my $key ( keys %in ) {
            if ( !defined $in{$key} ) {
                push @fieldsToNull, $key;
            }
            else {
                push @elems,
                  SOAP::Data->prefix($SF_PREFIX)->name( $key => $in{$key} )
                  ->type( WWW::Salesforce::Constants->type( $type, $key ) );
            }
        }
        for my $key ( @fieldsToNull ) {
            push @elems,
            SOAP::Data->prefix($SF_PREFIX)->name( fieldsToNull => $key )
            ->type( 'xsd:string' );
        }
        push @updates,
          SOAP::Data->name( 'sObjects' => \SOAP::Data->value(@elems) )
          ->attr( { 'xsi:type' => 'sforce:' . $type } );
    }

    my $client = $self->_get_client(1);
    my $method =
      SOAP::Data->name("update")->prefix($SF_PREFIX)->uri($SF_URI)
      ->attr( { 'xmlns:sfons' => $SF_SOBJECT_URI } );
    my $r = $client->call(
        $method => $self->_get_session_header(),
        @updates
    );
    unless ($r) {
        die "could not call method $method";
    }
    if ( $r->fault() ) {
        die( $r->faultstring() );
    }
    return $r;
}


=head2 upsert(type => $type, key => $key, HASHREF [, HASHREF ...])

Updates or inserts one or more objects in your organization's data.  If the data doesn't exist on Salesforce, it will be inserted.  If it already exists it will be updated.

This subroutine takes as input a B<type> value which names the type of object to update (e.g. Account, User).  It also takes a B<key> value which specifies the unique key Salesforce should use to determine if it needs to update or insert.  If B<key> is not given it will default to 'Id' which is Salesforce's own internal unique ID.  This key can be any of Salesforce's default fields or an custom field marked as an external key.

Finally, this method takes one or more perl HASH references containing the fields (the keys of the hash) and the values of the record that will be updated.

=cut

sub upsert {
    my $self = shift;
    my ( $spec, $type, $extern, $name, @sobjects ) = @_;

    if ( $spec ne 'type' || !$type ) {
        die("Expected a hash with key 'type' as first argument");
    }

    # Default to the 'id' field
    $name ||= 'id';

    my %tmp = ();
    if ( ref $sobjects[0] ne 'HASH' ) {
        %tmp      = @_;
        @sobjects = ( \%tmp );    # create an array of one
    }

    my @updates =
      ( SOAP::Data->prefix($SF_PREFIX)->name( 'externalIDFieldName' => $name )
          ->attr( { 'xsi:type' => 'xsd:string' } ) );

    foreach (@sobjects) {         # arg list is now an array of hash refs
        my %in = %{$_};

        my @elems;
        my @fieldsToNull;
        foreach my $key ( keys %in ) {
            if ( !defined $in{$key} ) {
                push @fieldsToNull, $key;
            }
            else {
                push @elems,
                SOAP::Data->prefix($SF_PREFIX)->name( $key => $in{$key} )
                ->type( WWW::Salesforce::Constants->type( $type, $key ) );
            }
        }
        for my $key ( @fieldsToNull ) {
            push @elems,
            SOAP::Data->prefix($SF_PREFIX)->name( fieldsToNull => $key )
            ->type( 'xsd:string' );
        }
        push @updates,
          SOAP::Data->name( 'sObjects' => \SOAP::Data->value(@elems) )
          ->attr( { 'xsi:type' => 'sforce:' . $type } );
    }

    my $client = $self->_get_client(1);
    my $method =
      SOAP::Data->name("upsert")->prefix($SF_PREFIX)->uri($SF_URI)
      ->attr( { 'xmlns:sfons' => $SF_SOBJECT_URI } );
    my $r = $client->call(
        $method => $self->_get_session_header(),
        @updates
    );
    unless ($r) {
        die "could not call method $method";
    }
    if ( $r->fault() ) {
        die( $r->faultstring() );
    }
    return $r;
}

# TODO: remove in version 0.400
sub get_clientM {
    warn "The method: get_clientM() has always been private. It is now deprecated and will be removed in version 0.400.";
    return shift->_get_client_meta(@_);
}

# TODO: remove in version 0.400
sub get_session_headerM {
    warn "The method: get_session_headerM() has always been private. It is now deprecated and will be removed in version 0.400.";
    return shift->_get_session_header_meta(@_);
}

=head2 describeMetadata()

Get some metadata info about your instance.

=cut

sub describeMetadata {
    my $self = shift;
    my $client = $self->_get_client_meta(1);
    my $method =
      SOAP::Data->name("describeMetadata")->prefix($SF_PREFIX)->uri($SF_URIM);

    my $r = $client->call(
          $method =>
          SOAP::Data->prefix($SF_PREFIX)->name( 'asOfVersion' )->value( $SF_APIVERSION ), $self->_get_session_header_meta() );
    unless ($r) {
        die "could not call method $method";
    }
    if ( $r->fault() ) {
        die( $r->faultstring() );
    }
    return $r->valueof('//describeMetadataResponse/result');
}


=head2 retrieveMetadata()

=cut

sub retrieveMetadata {
    my $self = shift;
    my %list = @_;
    my @req;
    foreach my $i (keys %list) {
       push (@req,SOAP::Data->name('types'=>
                        \SOAP::Data->value(
                            SOAP::Data->name('members'=>$list{$i}),
                            SOAP::Data->name('name'=>$i)
                        )
                    ));
    }
    my $client = $self->_get_client_meta(1);
    my $method =
      SOAP::Data->name('retrieve')->prefix($SF_PREFIX)->uri($SF_URIM);
    my $r = $client->call(
            $method,
            $self->_get_session_header_meta(),
SOAP::Data->name('retrieveRequest'=>
       \SOAP::Data->value(
       SOAP::Data->name( 'apiVersion'=>$SF_APIVERSION),
       SOAP::Data->name( 'singlePackage'=>'true'),
       SOAP::Data->name('unpackaged'=>
                   \SOAP::Data->value( @req
           ,SOAP::Data->name('version'=>$SF_APIVERSION))
         )
       )
     )
    );
    unless ($r) {
        die "could not call method $method";
    }
    if ( $r->fault() ) {
        die( $r->faultstring() );
    }
    $r = $r->valueof('//retrieveResponse/result');
    return $r;
}


=head2 checkAsyncStatus( $pid )

=cut

sub checkAsyncStatus {
    my $self = shift;
    my $pid = shift;
    #print "JOB - ID $pid\n";
    my $client = $self->_get_client_meta(1);
    my $method = SOAP::Data->name('checkStatus')->prefix($SF_PREFIX)->uri($SF_URIM);
    my $r;
    my $waitTimeMilliSecs = 1;
    my $Count =1 ;
    my $MAX_NUM_POLL_REQUESTS = 50;
    while (1) {
        sleep($waitTimeMilliSecs);
        $waitTimeMilliSecs *=2;
        $r = $client->call(
                $method,
                SOAP::Data->name('asyncProcessId'=>$pid)->type('xsd:ID'),
                $self->_get_session_header_meta()
        );
        unless ($r) {
            die "could not call method $method";
        }
        if ( $r->fault() ) {
            die( $r->faultstring() );
        }
        $r = $r->valueof('//checkStatusResponse/result');
        last if ($r->{'done'} eq 'true' || $Count >$MAX_NUM_POLL_REQUESTS);
        $Count++;
    }
    if ($r->{'done'} eq 'true') {
        return $self->checkRetrieveStatus($r->{'id'});
    }
    return;
}


=head2 checkRetrieveStatus( $pid )

=cut

sub checkRetrieveStatus {
    my $self = shift;
    my $pid = shift;
    my $client = $self->_get_client_meta(1);
    my $method = SOAP::Data->name('checkRetrieveStatus')->prefix($SF_PREFIX)->uri($SF_URIM);

    my $r = $client->call(
            $method,
            SOAP::Data->name('asyncProcessId'=>$pid),
            $self->_get_session_header_meta()
    );
    unless ($r) {
        die "could not call method $method";
    }
    if ( $r->fault() ) {
        die( $r->faultstring() );
    }
    return $r->valueof('//checkRetrieveStatusResponse/result');
}


=head2 getErrorDetails( RESULT )

Returns a hash with information about errors from API calls - only useful if ($res->valueof('//success') ne 'true')

  {
      'statusCode' => 'INVALID_FIELD_FOR_INSERT_UPDATE',
      'message' => 'Account: bad field names on insert/update call: type'
      ...
  }

=cut

sub getErrorDetails {
    my $self = shift;
    my $result = shift;
    return $result->valueof('//errors');
}


=head2 bye()

Synonym for C<logout>.

Ends the session for the logged-in user issuing the call. No arguments are needed.
Returns a reference to an array of hash refs

=cut

sub bye {
    my ( $self ) = @_;
    $self->logout() or die 'could not logout';
}


=head2 do_query( $query, [$limit] )

Returns a reference to an array of hash refs

=cut

sub do_query {
    my ( $self, $query, $limit ) = @_;

    if ( !defined $query || $query !~ m/^select/i ) {
        die('Param1 of do_query() should be a string SQL query');
    }

    $limit = 2000
      unless defined $limit
          and $limit =~ m/^\d+$/
          and $limit > 0
          and $limit < 2001;

    my @rows = ();    #to be returned

    my $res = $self->query( query => $query, limit => $limit );
    unless ($res) {
        die "could not execute query $query, limit $limit";
    }
    if ( $res->fault() ) {
        die( $res->faultstring() );
    }

    push @rows, $res->valueof('//queryResponse/result/records')
      if ( $res->valueof('//queryResponse/result/size') > 0 );

    #we get the results in batches of 2,000... so continue getting them
    #if there are more to get
    my $done = $res->valueof('//queryResponse/result/done');
    my $ql   = $res->valueof('//queryResponse/result/queryLocator');
    if ( $done eq 'false' ) {
        push @rows, @{$self->_retrieve_queryMore($ql, $limit)};
    }

    return \@rows;
}


=head2 do_queryAll( $query, [$limit] )

Returns a reference to an array of hash refs

=cut

sub do_queryAll {
    my ( $self, $query, $limit ) = @_;

    if ( !defined $query || $query !~ m/^select/i ) {
        die('Param1 of do_queryAll() should be a string SQL query');
    }

    $limit = 2000
      unless defined $limit
          and $limit =~ m/^\d+$/
          and $limit > 0
          and $limit < 2001;

    my @rows = ();    #to be returned

    my $res = $self->queryAll( query => $query, limit => $limit );
    unless ($res) {
        die "could not execute query $query, limit $limit";
    }
    if ( $res->fault() ) {
        die( $res->faultstring() );
    }

    push @rows, $res->valueof('//queryAllResponse/result/records')
      if ( $res->valueof('//queryAllResponse/result/size') > 0 );

    #we get the results in batches of 2,000... so continue getting them
    #if there are more to get
    my $done = $res->valueof('//queryAllResponse/result/done');
    my $ql   = $res->valueof('//queryAllResponse/result/queryLocator');
    if ( $done eq 'false' ) {
        push @rows, @{$self->_retrieve_queryMore($ql, $limit)};
    }

    return \@rows;
}

#**************************************************************************
# _retrieve_queryMore
#  -- returns the next block of a running query set. Supports do_query
#     and do_queryAll
#
#**************************************************************************

sub _retrieve_queryMore {
    my ( $self, $ql, $limit ) = @_;

    my $done = 'false';
    my @results;

    while ($done eq 'false') {
        my $res = $self->queryMore(
            queryLocator => $ql,
            limit        => $limit
        );
        unless ($res) {
            die "could not execute queryMore $ql, limit $limit";
        }
        if ( $res->fault() ) {
            die( $res->faultstring() );
        }
        $done = $res->valueof('//queryMoreResponse/result/done');
        $ql   = $res->valueof('//queryMoreResponse/result/queryLocator');

        if ( $res->valueof('//queryMoreResponse/result/size') ) {
            push @results, $res->valueof('//queryMoreResponse/result/records');
        }
    }

    return \@results;

}

=head2 get_field_list( $table_name )

Returns a ref to an array of hash refs for each field name
Field name keyed as 'name'

=cut

sub get_field_list {
    my ( $self, $table_name ) = @_;

    if ( !defined $table_name || !length $table_name ) {
        die('Param1 of get_field_list() should be a string');
    }

    my $res = $self->describeSObject( 'type' => $table_name );
    unless ($res) {
        die "could not describeSObject for table $table_name";
    }
    if ( $res->fault() ) {
        die( $res->faultstring() );
    }

    my @fields = $res->valueof('//describeSObjectResponse/result/fields');
    return \@fields;
}


=head2 get_tables()

Returns a reference to an array of hash references
Each hash gives the properties for each Salesforce object

=cut

sub get_tables {
    my ($self) = @_;

    my $res = $self->describeGlobal();
    unless ($res) {
        die "could not describeGlobal()";
    }
    if ( $res->fault() ) {
        die( $res->faultstring() );
    }

    my @globals = $res->valueof('//describeGlobalResponse/result/sobjects');
    return \@globals;
}

# private methods
sub _get_client {
    my $self = shift;
    my ($readable) = @_;
    $readable = ($readable) ? 1 : 0;

    my $client
        = SOAP::Lite->readable($readable)
        ->deserializer(WWW::Salesforce::Deserializer->new)
        ->serializer(WWW::Salesforce::Serializer->new)
        ->on_action(sub { return '""' })->uri($SF_URI)->multirefinplace(1);

    if ($WEB_PROXY) {
        $client->proxy($self->{'sf_serverurl'},
            proxy => ['https' => $WEB_PROXY]);
    }
    else {
        $client->proxy($self->{'sf_serverurl'});
    }
    return $client;
}

sub _get_client_meta {
    my $self = shift;
    my ($readable) = @_;
    $readable = ($readable) ? 1 : 0;

    my $client
        = SOAP::Lite->readable($readable)
        ->deserializer(WWW::Salesforce::Deserializer->new)
        ->serializer(WWW::Salesforce::Serializer->new)
        ->on_action(sub { return '""' })->uri($SF_URI)->multirefinplace(1)
        ->proxy($self->{'sf_metadataServerUrl'})->soapversion('1.1');
    return $client;
}

sub _get_session_header {
    my ($self) = @_;
    return SOAP::Header->name('SessionHeader' =>
            \SOAP::Header->name('sessionId' => $self->{'sf_sid'}))
        ->uri($SF_URI)->prefix($SF_PREFIX);
}

sub _get_session_header_meta {
    my ($self) = @_;
    return SOAP::Header->name( 'SessionHeader' =>
            \SOAP::Header->name( 'sessionId' => $self->{'sf_sid'} ) )
        ->uri($SF_URIM)->prefix($SF_PREFIX);
}


1;
__END__


=head1 EXAMPLES

=head2 login()

    use WWW::Salesforce;
    my $sf = WWW::Salesforce->login( 'username' => $user,'password' => $pass )
        or die $@;

=head2 search()

    my $query = 'find {4159017000} in phone fields returning contact(id, phone, ';
    $query .= 'firstname, lastname), lead(id, phone, firstname, lastname), ';
    $query .= 'account(id, phone, name)';
    my $result = $sforce->search( 'searchString' => $query );

=head1 SUPPORT

Please visit Salesforce.com's user/developer forums online for assistance with
this module. You are free to contact the author directly if you are unable to
resolve your issue online.

=head1 CAVEATS

The C<describeSObjects> and C<describeTabs> API calls are not yet complete. These will be
completed in future releases.

Not enough test cases built into the install yet.  More to be added.

=head1 SEE ALSO

    L<DBD::Salesforce> by Jun Shimizu
    L<SOAP::Lite> by Byrne Reese

    Examples on Salesforce website:
    L<http://www.sforce.com/us/docs/sforce70/wwhelp/wwhimpl/js/html/wwhelp.htm>

=head1 HISTORY

This Perl module was originally provided and presented as part of
the first Salesforce.com dreamForce conference on Nov. 11, 2003 in
San Francisco.

=head1 AUTHORS

Byrne Reese - <byrne at majordojo dot com>

Chase Whitener <F<capoeirab@cpan.org>>

Fred Moyer <fred at redhotpenguin dot com>

=head1 CONTRIBUTORS

Michael Blanco

Garth Webb

Jun Shimizu

Ron Hess

Tony Stubblebine

=head1 COPYRIGHT & LICENSE

Copyright 2003-2004 Byrne Reese, Chase Whitener, Fred Moyer. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
