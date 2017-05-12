package perfSONAR_PS::Services::MA::SNMP;

use base 'perfSONAR_PS::Services::Base';

use fields 'LS_CLIENT', 'NAMESPACES', 'METADATADB', 'LOGGER';

use strict;
use warnings;

our $VERSION = 0.09;

=head1 NAME

perfSONAR_PS::Services::MA::SNMP - A module that provides methods for the 
perfSONAR-PS SNMP based Measurement Archive (MA).

=head1 DESCRIPTION

This module, in conjunction with other parts of the perfSONAR-PS framework,
handles specific messages from interested actors in search of SNMP data.  There
are three major message types that this service can act upon:

 - MetadataKeyRequest     - Given some metadata about a specific measurement, 
                            request a re-playable 'key' to faster access
                            underlying data.
 - SetupDataRequest       - Given either metadata or a key regarding a specific
                            measurement, retrieve data values.
 - MetadataStorageRequest - Store data into the archive (unsupported)
 
The module is capable of dealing with several characteristic and tool based
eventTypes related to the underlying data as well as the aforementioned message
types.  

=cut

use Log::Log4perl qw(get_logger);
use Module::Load;
use Digest::MD5 qw(md5_hex);
use English qw( -no_match_vars );
use Params::Validate qw(:all);
use Date::Manip;

use perfSONAR_PS::Services::MA::General;
use perfSONAR_PS::Common;
use perfSONAR_PS::Messages;
use perfSONAR_PS::Client::LS::Remote;
use perfSONAR_PS::Error_compat qw/:try/;
use perfSONAR_PS::DB::File;
use perfSONAR_PS::DB::RRD;
use perfSONAR_PS::DB::SQL;
use perfSONAR_PS::ParameterValidation;

my %ma_namespaces = (
    nmwg      => "http://ggf.org/ns/nmwg/base/2.0/",
    nmtm      => "http://ggf.org/ns/nmwg/time/2.0/",
    snmp      => "http://ggf.org/ns/nmwg/tools/snmp/2.0/",
    netutil   => "http://ggf.org/ns/nmwg/characteristic/utilization/2.0/",
    neterr    => "http://ggf.org/ns/nmwg/characteristic/errors/2.0/",
    netdisc   => "http://ggf.org/ns/nmwg/characteristic/discards/2.0/",
    select    => "http://ggf.org/ns/nmwg/ops/select/2.0/",
    average   => "http://ggf.org/ns/nmwg/ops/average/2.0/",
    perfsonar => "http://ggf.org/ns/nmwg/tools/org/perfsonar/1.0/",
    psservice => "http://ggf.org/ns/nmwg/tools/org/perfsonar/service/1.0/",
    nmwgt     => "http://ggf.org/ns/nmwg/topology/2.0/",
    nmwgtopo3 => "http://ggf.org/ns/nmwg/topology/base/3.0/",
    nmtb      => "http://ogf.org/schema/network/topology/base/20070828/",
    nmtl2     => "http://ogf.org/schema/network/topology/l2/20070828/",
    nmtl3     => "http://ogf.org/schema/network/topology/l3/20070828/",
    nmtl4     => "http://ogf.org/schema/network/topology/l4/20070828/",
    nmtopo    => "http://ogf.org/schema/network/topology/base/20070828/",
    nmtb      => "http://ogf.org/schema/network/topology/base/20070828/",
    nmwgr     => "http://ggf.org/ns/nmwg/result/2.0/"
);

=head1 API

The offered API is not meant for external use as many of the functions are
relied upon by internal aspects of the perfSONAR-PS framework.

=head2 init($self, $handler)

Called at startup by the daemon when this particular module is loaded into
the perfSONAR-PS deployment.  Checks the configuration file for the necessary
items and fills in others when needed. Initializes the backed metadata storage
(DBXML or a simple XML file) and builds the internal 'key hash' for the 
MetadataKey exchanges.  Finally the message handler loads the appropriate 
message types and eventTypes for this module.  Any other 'pre-startup' tasks
should be placed in this function.

Due to performance issues, the database access must be handled in two different
ways:

 - File Database - it is expensive to continuously open the file and store it as
                   a DOM for each access.  Therefore it is opened once by the
                   daemon and used by each connection.  A $self object can
                   be used for this.
 - XMLDB - File handles are opened and closed for each connection.

=cut

sub init {
    my ( $self, $handler ) = @_;
    $self->{LOGGER} = get_logger("perfSONAR_PS::Services::MA::SNMP");

    unless ( exists $self->{CONF}->{"snmp"}->{"metadata_db_type"}
        and $self->{CONF}->{"snmp"}->{"metadata_db_type"} )
    {
        $self->{LOGGER}->error("Value for 'metadata_db_type' is not set.");
        return -1;
    }

    if ( $self->{CONF}->{"snmp"}->{"metadata_db_type"} eq "file" ) {
        unless ( exists $self->{CONF}->{"snmp"}->{"metadata_db_file"}
            and $self->{CONF}->{"snmp"}->{"metadata_db_file"} )
        {
            $self->{LOGGER}->error("Value for 'metadata_db_file' is not set.");
            return -1;
        }
        else {
            if ( defined $self->{DIRECTORY} ) {
                unless ( $self->{CONF}->{"snmp"}->{"metadata_db_file"} =~ "^/" ) {
                    $self->{CONF}->{"snmp"}->{"metadata_db_file"} = $self->{DIRECTORY} . "/" . $self->{CONF}->{"snmp"}->{"metadata_db_file"};
                }
            }
        }
    }
    elsif ( $self->{CONF}->{"snmp"}->{"metadata_db_type"} eq "xmldb" ) {
        eval { load perfSONAR_PS::DB::XMLDB; };
        if ($EVAL_ERROR) {
            $self->{LOGGER}->error("Couldn't load perfSONAR_PS::DB::XMLDB: $EVAL_ERROR");
            return -1;
        }

        unless ( exists $self->{CONF}->{"snmp"}->{"metadata_db_file"}
            and $self->{CONF}->{"snmp"}->{"metadata_db_file"} )
        {
            $self->{LOGGER}->error("Value for 'metadata_db_file' is not set.");
            return -1;
        }
        unless ( exists $self->{CONF}->{"snmp"}->{"metadata_db_name"}
            and $self->{CONF}->{"snmp"}->{"metadata_db_name"} )
        {
            $self->{LOGGER}->error("Value for 'metadata_db_name' is not set.");
            return -1;
        }
        else {
            if ( defined $self->{DIRECTORY} ) {
                unless ( $self->{CONF}->{"snmp"}->{"metadata_db_name"} =~ "^/" ) {
                    $self->{CONF}->{"snmp"}->{"metadata_db_name"} = $self->{DIRECTORY} . "/" . $self->{CONF}->{"snmp"}->{"metadata_db_name"};
                }
            }
        }
    }
    else {
        $self->{LOGGER}->error("Wrong value for 'metadata_db_type' set.");
        return -1;
    }

    unless ( exists $self->{CONF}->{"snmp"}->{"rrdtool"}
        and $self->{CONF}->{"snmp"}->{"rrdtool"} )
    {
        $self->{LOGGER}->error("Value for 'rrdtool' is not set.");
        return -1;
    }

    unless ( exists $self->{CONF}->{"snmp"}->{"default_resolution"}
        and $self->{CONF}->{"snmp"}->{"default_resolution"} )
    {
        $self->{CONF}->{"snmp"}->{"default_resolution"} = "300";
        $self->{LOGGER}->warn("Setting 'default_resolution' to '300'.");
    }

    unless ( exists $self->{CONF}->{"snmp"}->{"enable_registration"}
        and $self->{CONF}->{"snmp"}->{"enable_registration"} )
    {
        $self->{CONF}->{"snmp"}->{"enable_registration"} = 0;
    }

    if ( $self->{CONF}->{"snmp"}->{"enable_registration"} ) {
        unless ( exists $self->{CONF}->{"snmp"}->{"service_accesspoint"}
            and $self->{CONF}->{"snmp"}->{"service_accesspoint"} )
        {
            $self->{LOGGER}->error("No access point specified for SNMP service");
            return -1;
        }

        unless ( exists $self->{CONF}->{"snmp"}->{"ls_instance"}
            and $self->{CONF}->{"snmp"}->{"ls_instance"} )
        {
            if ( defined $self->{CONF}->{"ls_instance"}
                and $self->{CONF}->{"ls_instance"} )
            {
                $self->{CONF}->{"snmp"}->{"ls_instance"} = $self->{CONF}->{"ls_instance"};
            }
            else {
                $self->{LOGGER}->error("No LS instance specified for SNMP service");
                return -1;
            }
        }

        unless ( exists $self->{CONF}->{"snmp"}->{"ls_registration_interval"}
            and $self->{CONF}->{"snmp"}->{"ls_registration_interval"} )
        {
            if ( defined $self->{CONF}->{"ls_registration_interval"}
                and $self->{CONF}->{"ls_registration_interval"} )
            {
                $self->{CONF}->{"snmp"}->{"ls_registration_interval"} = $self->{CONF}->{"ls_registration_interval"};
            }
            else {
                $self->{LOGGER}->warn("Setting registration interval to 30 minutes");
                $self->{CONF}->{"snmp"}->{"ls_registration_interval"} = 1800;
            }
        }

        unless ( exists $self->{CONF}->{"snmp"}->{"service_accesspoint"}
            and $self->{CONF}->{"snmp"}->{"service_accesspoint"} )
        {
            $self->{CONF}->{"snmp"}->{"service_accesspoint"} = "http://localhost:" . $self->{PORT} . "/" . $self->{ENDPOINT};
            $self->{LOGGER}->warn( "Setting 'service_accesspoint' to 'http://localhost:" . $self->{PORT} . "/" . $self->{ENDPOINT} . "'." );
        }

        unless ( exists $self->{CONF}->{"snmp"}->{"service_description"}
            and $self->{CONF}->{"snmp"}->{"service_description"} )
        {
            $self->{CONF}->{"snmp"}->{"service_description"} = "perfSONAR_PS SNMP MA";
            $self->{LOGGER}->warn("Setting 'service_description' to 'perfSONAR_PS SNMP MA'.");
        }

        unless ( exists $self->{CONF}->{"snmp"}->{"service_name"}
            and $self->{CONF}->{"snmp"}->{"service_name"} )
        {
            $self->{CONF}->{"snmp"}->{"service_name"} = "SNMP MA";
            $self->{LOGGER}->warn("Setting 'service_name' to 'SNMP MA'.");
        }

        unless ( exists $self->{CONF}->{"snmp"}->{"service_type"}
            and $self->{CONF}->{"snmp"}->{"service_type"} )
        {
            $self->{CONF}->{"snmp"}->{"service_type"} = "MA";
            $self->{LOGGER}->warn("Setting 'service_type' to 'MA'.");
        }
    }

    $handler->registerMessageHandler( "SetupDataRequest",   $self );
    $handler->registerMessageHandler( "MetadataKeyRequest", $self );

    my $error = q{};
    if ( $self->{CONF}->{"snmp"}->{"metadata_db_type"} eq "file" ) {
        $self->{METADATADB} = new perfSONAR_PS::DB::File( { file => $self->{CONF}->{"snmp"}->{"metadata_db_file"} } );
        $self->{METADATADB}->openDB( { error => \$error } );
        unless ( $self->{METADATADB} ) {
            $self->{LOGGER}->error("Couldn't initialize store file: $error");
            return -1;
        }
    }
    elsif ( $self->{CONF}->{"snmp"}->{"metadata_db_type"} eq "xmldb" ) {
        my $error      = q{};
        my $metadatadb = $self->prepareDatabases;
        unless ($metadatadb) {
            $self->{LOGGER}->error( "There was an error opening \"" . $self->{CONF}->{"ls"}->{"metadata_db_name"} . "/" . $self->{CONF}->{"ls"}->{"metadata_db_file"} . "\": " . $error );
            return -1;
        }

        if ( $self->{CONF}->{"snmp"}->{"db_autoload"} and $self->{CONF}->{"snmp"}->{"autoload_metadata_db_file"} ) {
            my $status = $self->loadXMLDB( { metadatadb => $metadatadb } );
            return -1 if $status == -1;
        }

        $metadatadb->closeDB( { error => \$error } );
        $self->{METADATADB} = q{};
    }
    else {
        $self->{LOGGER}->error("Wrong value for 'metadata_db_type' set.");
        return -1;
    }

    unless ( $self->buildHashedKeys == 0 ) {
        $self->{LOGGER}->error("Error building key database.");
        return -1;
    }

    return 0;
}

=head2 prepareDatabases($self, { doc })

Opens the XMLDB and returns the handle if there was not an error.  The optional
argument can be used to pass an error message to the given message and 
return this in response to a request.

=cut

sub prepareDatabases {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { doc => 0 } );

    my $error = q{};
    my $metadatadb = new perfSONAR_PS::DB::XMLDB( { env => $self->{CONF}->{"snmp"}->{"metadata_db_name"}, cont => $self->{CONF}->{"snmp"}->{"metadata_db_file"}, ns => \%ma_namespaces, } );
    unless ( $metadatadb->openDB( { txn => q{}, error => \$error } ) == 0 ) {
        throw perfSONAR_PS::Error_compat( "error.ls.xmldb", "There was an error opening \"" . $self->{CONF}->{"ls"}->{"metadata_db_name"} . "/" . $self->{CONF}->{"ls"}->{"metadata_db_file"} . "\": " . $error );
        return;
    }
    return $metadatadb;
}

=head2 loadXMLDB( { metadatadb } ) 

If the deployment has an existing store file, but would like to utilize an XML
DB instance, this function will load the old data into an existing XML DB.  This
operation is non-destructive.

=cut

sub loadXMLDB {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { metadatadb => 1 } );

    my $sourceError = q{};
    my $sourceDB = new perfSONAR_PS::DB::File( { file => $self->{CONF}->{"snmp"}->{"autoload_metadata_db_file"} } );
    $sourceDB->openDB( { error => \$sourceError } );
    unless ($sourceDB) {
        $self->{LOGGER}->error("Couldn't initialize store file: $sourceError");
        return -1;
    }

    my $dom = $sourceDB->getDOM;
    if ($dom) {
        my $error     = q{};
        my $errorFlag = 0;
        my $dbTr      = q{};
        $dbTr = $parameters->{metadatadb}->getTransaction( { error => \$error } );
        unless ($dbTr) {
            $parameters->{metadatadb}->abortTransaction( { txn => $dbTr, error => \$error } ) if $dbTr;
            undef $dbTr;
            $self->{LOGGER}->error( "Database error: \"" . $error . "\", aborting." );
            return -1;
        }

        foreach my $data ( $dom->getDocumentElement->getChildrenByTagNameNS( "http://ggf.org/ns/nmwg/base/2.0/", "data" ) ) {
            my $dHash = md5_hex( $data->toString );
            $parameters->{metadatadb}->insertIntoContainer( { content => $parameters->{metadatadb}->wrapStore( { content => $data->toString, type => "MAStore" } ), name => $dHash, txn => $dbTr, error => \$error } );
            $self->{LOGGER}->debug( "Inserting \"" . $data->toString . "\" as \"" . $dHash . "\"." );

            my $metadata = $dom->getDocumentElement->find( "./nmwg:metadata[\@id=\"" . $data->getAttribute("metadataIdRef") . "\"]" )->get_node(1);
            my $mdHash   = md5_hex( $metadata->toString );
            $parameters->{metadatadb}->insertIntoContainer( { content => $parameters->{metadatadb}->wrapStore( { content => $metadata->toString, type => "MAStore" } ), name => $mdHash, txn => $dbTr, error => \$error } );
            $self->{LOGGER}->debug( "Inserting \"" . $metadata->toString . "\" as \"" . $mdHash . "\"." );
        }

        if ($errorFlag) {
            $parameters->{metadatadb}->abortTransaction( { txn => $dbTr, error => \$error } ) if $dbTr;
            undef $dbTr;
            $self->{LOGGER}->error( "Database error: \"" . $error . "\", aborting." );
            return -1;
        }
        else {
            my $status = $parameters->{metadatadb}->commitTransaction( { txn => $dbTr, error => \$error } );
            if ( $status == 0 ) {
                undef $dbTr;
            }
            else {
                $parameters->{metadatadb}->abortTransaction( { txn => $dbTr, error => \$error } ) if $dbTr;
                undef $dbTr;
                $self->{LOGGER}->error( "Database error: \"" . $error . "\", aborting." );
                return -1;
            }
        }
    }
    else {
        $self->{LOGGER}->error( "Source file \"" . $self->{CONF}->{"snmp"}->{"autoload_metadata_db_file"} . "\" error, aborting." );
        return -1;
    }
    return 0;
}

=head2 buildHashedKeys($self {})

With the backend storage known we can search through looking for key
structures.  Once we have these in hand each will be examined and Digest::MD5
will be utilized to create MD5 hex based fingerprints of each key.  We then 
map these to the key ids in the metadata database for easy lookup.

=cut

sub buildHashedKeys {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, {} );

    if ( $self->{CONF}->{"snmp"}->{"metadata_db_type"} eq "file" ) {
        my $results = $self->{METADATADB}->querySet( { query => "/nmwg:store/nmwg:data" } );
        if ( $results->size() > 0 ) {
            foreach my $data ( $results->get_nodelist ) {
                if ( $data->getAttribute("id") ) {
                    my $hash = md5_hex( $data->toString );
                    $self->{CONF}->{"snmp"}->{"hashToId"}->{$hash} = $data->getAttribute("id");
                    $self->{CONF}->{"snmp"}->{"idToHash"}->{ $data->getAttribute("id") } = $hash;
                    $self->{LOGGER}->debug( "Key id $hash maps to data element " . $data->getAttribute("id") );
                }
            }
        }
    }
    elsif ( $self->{CONF}->{"snmp"}->{"metadata_db_type"} eq "xmldb" ) {
        my $metadatadb = $self->prepareDatabases( { doc => $parameters->{output} } );
        my $error = q{};
        unless ($metadatadb) {
            $self->{LOGGER}->error("Database could not be opened.");
            return -1;
        }

        my $parser = XML::LibXML->new();
        my @results = $metadatadb->query( { query => "/nmwg:store[\@type=\"MAStore\"]/nmwg:data", txn => q{}, error => \$error } );

        my $len = $#results;
        if ( $len == -1 ) {
            $self->{LOGGER}->error("Nothing returned for database search.");
            return -1;
        }

        for my $x ( 0 .. $len ) {
            my $hash = md5_hex( $results[$x] );
            my $data = $parser->parse_string( $results[$x] );
            $self->{CONF}->{"snmp"}->{"hashToId"}->{$hash} = $data->getDocumentElement->getAttribute("id");
            $self->{CONF}->{"snmp"}->{"idToHash"}->{ $data->getDocumentElement->getAttribute("id") } = $hash;
            $self->{LOGGER}->debug( "Key id $hash maps to data element " . $data->getDocumentElement->getAttribute("id") );
        }
    }
    else {
        $self->{LOGGER}->error("Wrong value for 'metadata_db_type' set.");
        return -1;
    }
    return 0;
}

=head2 needLS($self {})

This particular service (SNMP MA) should register with a lookup service.  This
function simply returns the value set in the configuration file (either yes or
no, depending on user preference) to let other parts of the framework know if
LS registration is required.

=cut

sub needLS {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, {} );

    return ( $self->{CONF}->{"snmp"}->{"enable_registration"} );
}

=head2 registerLS($self $sleep_time)

Given the service information (specified in configuration) and the contents of
our metadata database, we can contact the specified LS and register ourselves.
We then sleep for some amount of time and do it again.

=cut

sub registerLS {
    my ( $self, $sleep_time ) = validateParamsPos( @_, 1, { type => SCALARREF }, );

    #    my ( $self, @args ) = @_;
    #    my $parameters = validateParams( @args, { sleep_time => 0 } );

    my ( $status, $res );
    my $ls = q{};

    if ( !defined $self->{LS_CLIENT} ) {
        my %ls_conf = (
            SERVICE_TYPE        => $self->{CONF}->{"snmp"}->{"service_type"},
            SERVICE_NAME        => $self->{CONF}->{"snmp"}->{"service_name"},
            SERVICE_DESCRIPTION => $self->{CONF}->{"snmp"}->{"service_description"},
            SERVICE_ACCESSPOINT => $self->{CONF}->{"snmp"}->{"service_accesspoint"},
        );
        $self->{LS_CLIENT} = new perfSONAR_PS::Client::LS::Remote( $self->{CONF}->{"snmp"}->{"ls_instance"}, \%ls_conf, $self->{NAMESPACES} );
    }

    $ls = $self->{LS_CLIENT};

    my $error         = q{};
    my @resultsString = ();
    if ( $self->{CONF}->{"snmp"}->{"metadata_db_type"} eq "file" ) {
        @resultsString = $self->{METADATADB}->query( { query => "/nmwg:store/nmwg:metadata", error => \$error } );
    }
    elsif ( $self->{CONF}->{"snmp"}->{"metadata_db_type"} eq "xmldb" ) {
        my $metadatadb = $self->prepareDatabases;
        unless ($metadatadb) {
            $self->{LOGGER}->error("Database could not be opened.");
            return -1;
        }
        @resultsString = $metadatadb->query( { query => "/nmwg:store[\@type=\"MAStore\"]/nmwg:metadata", txn => q{}, error => \$error } );
        $metadatadb->closeDB( { error => \$error } );
    }
    else {
        $self->{LOGGER}->error("Wrong value for 'metadata_db_type' set.");
        return -1;
    }

    if ( $#resultsString == -1 ) {
        $self->{LOGGER}->error("No data to register with LS");
        return -1;
    }
    $ls->registerStatic( \@resultsString );
    return 0;
}

=head2 handleMessageBegin($self, { ret_message, messageId, messageType, msgParams, request, retMessageType, retMessageNamespaces })

Stub function that is currently unused.  Will be used to interact with the 
daemon's message handler.

=cut

sub handleMessageBegin {
    my ( $self, $ret_message, $messageId, $messageType, $msgParams, $request, $retMessageType, $retMessageNamespaces ) = @_;

    #   my ($self, @args) = @_;
    #      my $parameters = validateParams(@args,
    #            {
    #                ret_message => 1,
    #                messageId => 1,
    #                messageType => 1,
    #                msgParams => 1,
    #                request => 1,
    #                retMessageType => 1,
    #                retMessageNamespaces => 1
    #            });

    return 0;
}

=head2 handleMessageEnd($self, { ret_message, messageId })

Stub function that is currently unused.  Will be used to interact with the 
daemon's message handler.

=cut

sub handleMessageEnd {
    my ( $self, $ret_message, $messageId ) = @_;

    #   my ($self, @args) = @_;
    #      my $parameters = validateParams(@args,
    #            {
    #                ret_message => 1,
    #                messageId => 1
    #            });

    return 0;
}

=head2 handleEvent($self, { output, messageId, messageType, messageParameters, eventType, subject, filterChain, data, rawRequest, doOutputMetadata })

Current workaround to the daemon's message handler.  All messages that enter
will be routed based on the message type.  The appropriate solution to this
problem is to route on eventType and message type and will be implemented in
future releases.

=cut

sub handleEvent {
    my ( $self, @args ) = @_;
    my $parameters = validateParams(
        @args,
        {
            output            => 1,
            messageId         => 1,
            messageType       => 1,
            messageParameters => 1,
            eventType         => 1,
            subject           => 1,
            filterChain       => 1,
            data              => 1,
            rawRequest        => 1,
            doOutputMetadata  => 1,
        }
    );

    my @subjects = @{ $parameters->{subject} };
    my @filters  = @{ $parameters->{filterChain} };
    my $md       = $subjects[0];

    # this module outputs its own metadata so it needs to turn off the daemon's
    # metadata output routines.
    ${ $parameters->{doOutputMetadata} } = 0;

    my %timeSettings = ();

    # go through the main subject and select filters looking for parameters.
    my $new_timeSettings = getFilterParameters( { m => $md, namespaces => $parameters->{rawRequest}->getNamespaces(), default_resolution => $self->{CONF}->{"snmp"}->{"default_resolution"} } );

    $timeSettings{"CF"}                   = $new_timeSettings->{"CF"}                   if ( defined $new_timeSettings->{"CF"} );
    $timeSettings{"RESOLUTION"}           = $new_timeSettings->{"RESOLUTION"}           if ( defined $new_timeSettings->{"RESOLUTION"} and $timeSettings{"RESOLUTION_SPECIFIED"} );
    $timeSettings{"RESOLUTION_SPECIFIED"} = $new_timeSettings->{"RESOLUTION_SPECIFIED"} if ( $new_timeSettings->{"RESOLUTION_SPECIFIED"} );

    if ( exists $new_timeSettings->{"START"}->{"value"} ) {
        if ( exists $new_timeSettings->{"START"}->{"type"} and lc( $new_timeSettings->{"START"}->{"type"} ) eq "unix" ) {
            $new_timeSettings->{"START"}->{"internal"} = $new_timeSettings->{"START"}->{"value"};
        }
        elsif ( exists $new_timeSettings->{"START"}->{"type"} and lc( $new_timeSettings->{"START"}->{"type"} ) eq "iso" ) {
            $new_timeSettings->{"START"}->{"internal"} = UnixDate( $new_timeSettings->{"START"}->{"value"}, "%s" );
        }
        else {
            $new_timeSettings->{"START"}->{"internal"} = $new_timeSettings->{"START"}->{"value"};
        }
    }
    $timeSettings{"START"} = $new_timeSettings->{"START"};

    if ( exists $new_timeSettings->{"END"}->{"value"} ) {
        if ( exists $new_timeSettings->{"END"}->{"type"} and lc( $new_timeSettings->{"END"}->{"type"} ) eq "unix" ) {
            $new_timeSettings->{"END"}->{"internal"} = $new_timeSettings->{"END"}->{"value"};
        }
        elsif ( exists $new_timeSettings->{"START"}->{"type"} and lc( $new_timeSettings->{"END"}->{"type"} ) eq "iso" ) {
            $new_timeSettings->{"END"}->{"internal"} = UnixDate( $new_timeSettings->{"END"}->{"value"}, "%s" );
        }
        else {
            $new_timeSettings->{"END"}->{"internal"} = $new_timeSettings->{"END"}->{"value"};
        }
    }
    $timeSettings{"END"} = $new_timeSettings->{"END"};

    if ( $#filters > -1 ) {
        foreach my $filter_arr (@filters) {
            my @filters = @{$filter_arr};
            my $filter  = $filters[-1];

            $new_timeSettings = getFilterParameters( { m => $filter, namespaces => $parameters->{rawRequest}->getNamespaces(), default_resolution => $self->{CONF}->{"snmp"}->{"default_resolution"} } );

            $timeSettings{"CF"}                   = $new_timeSettings->{"CF"}                   if ( defined $new_timeSettings->{"CF"} );
            $timeSettings{"RESOLUTION"}           = $new_timeSettings->{"RESOLUTION"}           if ( defined $new_timeSettings->{"RESOLUTION"} and $new_timeSettings->{"RESOLUTION_SPECIFIED"} );
            $timeSettings{"RESOLUTION_SPECIFIED"} = $new_timeSettings->{"RESOLUTION_SPECIFIED"} if ( $new_timeSettings->{"RESOLUTION_SPECIFIED"} );

            if ( exists $new_timeSettings->{"START"}->{"value"} ) {
                if ( exists $new_timeSettings->{"START"}->{"type"} and lc( $new_timeSettings->{"START"}->{"type"} ) eq "unix" ) {
                    $new_timeSettings->{"START"}->{"internal"} = $new_timeSettings->{"START"}->{"value"};
                }
                elsif ( exists $new_timeSettings->{"START"}->{"type"} and lc( $new_timeSettings->{"START"}->{"type"} ) eq "iso" ) {
                    $new_timeSettings->{"START"}->{"internal"} = UnixDate( $new_timeSettings->{"START"}->{"value"}, "%s" );
                }
                else {
                    $new_timeSettings->{"START"}->{"internal"} = $new_timeSettings->{"START"}->{"value"};
                }
            }
            else {
                $new_timeSettings->{"START"}->{"internal"} = q{};
            }

            if ( exists $new_timeSettings->{"END"}->{"value"} ) {
                if ( exists $new_timeSettings->{"END"}->{"type"} and lc( $new_timeSettings->{"END"}->{"type"} ) eq "unix" ) {
                    $new_timeSettings->{"END"}->{"internal"} = $new_timeSettings->{"END"}->{"value"};
                }
                elsif ( exists $new_timeSettings->{"END"}->{"type"} and lc( $new_timeSettings->{"END"}->{"type"} ) eq "iso" ) {
                    $new_timeSettings->{"END"}->{"internal"} = UnixDate( $new_timeSettings->{"END"}->{"value"}, "%s" );
                }
                else {
                    $new_timeSettings->{"END"}->{"internal"} = $new_timeSettings->{"END"}->{"value"};
                }
            }
            else {
                $new_timeSettings->{"END"}->{"internal"} = q{};
            }

            # we conditionally replace the START/END settings since under the
            # theory of filter, if a later element specifies an earlier start
            # time, the later start time that appears higher in the filter chain
            # would have filtered out all times earlier than itself leaving
            # nothing to exist between the earlier start time and the later
            # start time. XXX I'm not sure how the resolution and the
            # consolidation function should work in this context.

            if ( exists $new_timeSettings->{"START"}->{"internal"} and ( ( not exists $timeSettings{"START"}->{"internal"} ) or $new_timeSettings->{"START"}->{"internal"} > $timeSettings{"START"}->{"internal"} ) ) {
                $timeSettings{"START"} = $new_timeSettings->{"START"};
            }

            if ( exists $new_timeSettings->{"END"}->{"internal"} and ( ( not exists $timeSettings{"END"}->{"internal"} ) or $new_timeSettings->{"END"}->{"internal"} < $timeSettings{"END"}->{"internal"} ) ) {
                $timeSettings{"END"} = $new_timeSettings->{"END"};
            }
        }
    }

    # If no resolution was listed in the filters, go with the default
    if ( not defined $timeSettings{"RESOLUTION"} ) {
        $timeSettings{"RESOLUTION"}           = $self->{CONF}->{"snmp"}->{"default_resolution"};
        $timeSettings{"RESOLUTION_SPECIFIED"} = 0;
    }

    my $cf         = q{};
    my $resolution = q{};
    my $start      = q{};
    my $end        = q{};

    $cf         = $timeSettings{"CF"}                  if ( $timeSettings{"CF"} );
    $resolution = $timeSettings{"RESOLUTION"}          if ( $timeSettings{"RESOLUTION"} );
    $start      = $timeSettings{"START"}->{"internal"} if ( $timeSettings{"START"}->{"internal"} );
    $end        = $timeSettings{"END"}->{"internal"}   if ( $timeSettings{"END"}->{"internal"} );

    $self->{LOGGER}->debug("Request filter parameters: cf: $cf resolution: $resolution start: $start end: $end");

    if ( $parameters->{messageType} eq "MetadataKeyRequest" ) {
        return $self->maMetadataKeyRequest(
            {
                output             => $parameters->{output},
                metadata           => $md,
                filters            => \@filters,
                time_settings      => \%timeSettings,
                request            => $parameters->{rawRequest},
                message_parameters => $parameters->{messageParameters}
            }
        );
    }
    elsif ( $parameters->{messageType} eq "SetupDataRequest" ) {
        return $self->maSetupDataRequest(
            {
                output             => $parameters->{output},
                metadata           => $md,
                filters            => \@filters,
                time_settings      => \%timeSettings,
                request            => $parameters->{rawRequest},
                message_parameters => $parameters->{messageParameters}
            }
        );
    }
    else {
        throw perfSONAR_PS::Error_compat( "error.ma.message_type", "Invalid Message Type" );
        return;
    }
    return;
}

=head2 maMetadataKeyRequest($self, { output, metadata, time_settings, filters, request, message_parameters })

Main handler of MetadataKeyRequest messages.  Based on contents (i.e. was a
key sent in the request, or not) this will route to one of two functions:

 - metadataKeyRetrieveKey          - Handles all requests that enter with a 
                                     key present.  
 - metadataKeyRetrieveMetadataData - Handles all other requests
 
The goal of this message type is to return a pointer (i.e. a 'key') to the data
so that the more expensive operation of XPath searching the database is avoided
with a simple hashed key lookup.  The key currently can be replayed repeatedly
currently because it is not time sensitive.  

=cut

sub maMetadataKeyRequest {
    my ( $self, @args ) = @_;
    my $parameters = validateParams(
        @args,
        {
            output             => 1,
            metadata           => 1,
            time_settings      => 1,
            filters            => 1,
            request            => 1,
            message_parameters => 1
        }
    );

    my $mdId  = q{};
    my $dId   = q{};
    my $error = q{};
    if ( $self->{CONF}->{"snmp"}->{"metadata_db_type"} eq "xmldb" ) {
        $self->{METADATADB} = $self->prepareDatabases( { doc => $parameters->{output} } );
        unless ( $self->{METADATADB} ) {
            throw perfSONAR_PS::Error_compat("Database could not be opened.");
            return;
        }
    }
    unless ( ( $self->{CONF}->{"snmp"}->{"metadata_db_type"} eq "file" )
        or ( $self->{CONF}->{"snmp"}->{"metadata_db_type"} eq "xmldb" ) )
    {
        throw perfSONAR_PS::Error_compat("Wrong value for 'metadata_db_type' set.");
        return;
    }

    my $nmwg_key = find( $parameters->{metadata}, "./nmwg:key", 1 );
    if ($nmwg_key) {
        $self->metadataKeyRetrieveKey(
            {
                metadatadb         => $self->{METADATADB},
                key                => $nmwg_key,
                metadata           => $parameters->{metadata},
                filters            => $parameters->{filters},
                request_namespaces => $parameters->{request}->getNamespaces(),
                output             => $parameters->{output}
            }
        );
    }
    else {
        $self->metadataKeyRetrieveMetadataData(
            {
                metadatadb         => $self->{METADATADB},
                time_settings      => $parameters->{time_settings},
                metadata           => $parameters->{metadata},
                filters            => $parameters->{filters},
                request_namespaces => $parameters->{request}->getNamespaces(),
                output             => $parameters->{output}
            }
        );

    }
    if ( $self->{CONF}->{"snmp"}->{"metadata_db_type"} eq "xmldb" ) {
        $self->{METADATADB}->closeDB( { error => \$error } );
    }
    return;
}

=head2 metadataKeyRetrieveKey($self, { metadatadb, key, metadata, filters, request_namespaces, output })

Because the request entered with a key, we must handle it in this particular
function.  We first attempt to extract the 'maKey' hash and check for validity.
An invalid or missing key will trigger an error instantly.  If the key is found
we see if any chaining needs to be done (and appropriately 'cook' the key), then
return the response.

=cut

sub metadataKeyRetrieveKey {
    my ( $self, @args ) = @_;
    my $parameters = validateParams(
        @args,
        {
            metadatadb         => 1,
            key                => 1,
            metadata           => 1,
            filters            => 1,
            request_namespaces => 1,
            output             => 1
        }
    );

    my $mdId    = "metadata." . genuid();
    my $dId     = "data." . genuid();
    my $hashKey = extract( find( $parameters->{key}, ".//nmwg:parameter[\@name=\"maKey\"]", 1 ), 0 );
    unless ($hashKey) {
        my $msg = "Key error in metadata storage.";
        $self->{LOGGER}->error($msg);
        throw perfSONAR_PS::Error_compat( "error.ma.storage_result", $msg );
        return;
    }

    my $hashId = $self->{CONF}->{"snmp"}->{"hashToId"}->{$hashKey};
    unless ($hashId) {
        my $msg = "Key error in metadata storage.";
        $self->{LOGGER}->error($msg);
        throw perfSONAR_PS::Error_compat( "error.ma.storage_result", $msg );
        return;
    }

    my $query = q{};
    if ( $self->{CONF}->{"snmp"}->{"metadata_db_type"} eq "file" ) {
        $query = "/nmwg:store/nmwg:data[\@id=\"" . $hashId . "\"]";
    }
    elsif ( $self->{CONF}->{"snmp"}->{"metadata_db_type"} eq "xmldb" ) {
        $query = "/nmwg:store[\@type=\"MAStore\"]/nmwg:data[\@id=\"" . $hashId . "\"]";
    }

    if ( $parameters->{metadatadb}->count( { query => $query } ) != 1 ) {
        my $msg = "Key error in metadata storage.";
        $self->{LOGGER}->error($msg);
        throw perfSONAR_PS::Error_compat( "error.ma.storage_result", $msg );
        return;
    }

    my $mdIdRef;
    my @filters = @{ $parameters->{filters} };
    if ( $#filters > -1 ) {
        $mdIdRef = $filters[-1][0]->getAttribute("id");
    }
    else {
        $mdIdRef = $parameters->{metadata}->getAttribute("id");
    }

    createMetadata( $parameters->{output}, $mdId, $mdIdRef, $parameters->{key}->toString, undef );
    my $key2 = $parameters->{key}->cloneNode(1);
    my $params = find( $key2, ".//nmwg:parameters", 1 );
    $self->addSelectParameters( { parameter_block => $params, filters => $parameters->{filters} } );
    createData( $parameters->{output}, $dId, $mdId, $key2->toString, undef );
    return;
}

=head2 metadataKeyRetrieveMetadataData($self, $metadatadb, $metadata, $chain,
                                       $id, $request_namespaces, $output)

Similar to 'metadataKeyRetrieveKey' we are looking to return a valid key.  The
input will be partially or fully specified metadata.  If this matches something
in the database we will return a key matching the description (in the form of
an MD5 fingerprint).  If this metadata was a part of a chain the chaining will
be resolved and used to augment (i.e. 'cook') the key.

=cut

sub metadataKeyRetrieveMetadataData {
    my ( $self, @args ) = @_;
    my $parameters = validateParams(
        @args,
        {
            metadatadb         => 1,
            time_settings      => 1,
            metadata           => 1,
            filters            => 1,
            request_namespaces => 1,
            output             => 1
        }
    );

    my $mdId        = q{};
    my $dId         = q{};
    my $queryString = q{};
    if ( $self->{CONF}->{"snmp"}->{"metadata_db_type"} eq "file" ) {
        $queryString = "/nmwg:store/nmwg:metadata[" . getMetadataXQuery( { node => $parameters->{metadata} } ) . "]";
    }
    elsif ( $self->{CONF}->{"snmp"}->{"metadata_db_type"} eq "xmldb" ) {
        $queryString = "/nmwg:store[\@type=\"MAStore\"]/nmwg:metadata[" . getMetadataXQuery( { node => $parameters->{metadata} } ) . "]";
    }

    my $results             = $parameters->{metadatadb}->querySet( { query => $queryString } );
    my %et                  = ();
    my $eventTypes          = find( $parameters->{metadata}, "./nmwg:eventType", 0 );
    my $supportedEventTypes = find( $parameters->{metadata}, ".//nmwg:parameter[\@name=\"supportedEventType\" or \@name=\"eventType\"]", 0 );
    foreach my $e ( $eventTypes->get_nodelist ) {
        my $value = extract( $e, 0 );
        if ($value) {
            $et{$value} = 1;
        }
    }
    foreach my $se ( $supportedEventTypes->get_nodelist ) {
        my $value = extract( $se, 0 );
        if ($value) {
            $et{$value} = 1;
        }
    }

    if ( $self->{CONF}->{"snmp"}->{"metadata_db_type"} eq "file" ) {
        $queryString = "/nmwg:store/nmwg:data";
    }
    elsif ( $self->{CONF}->{"snmp"}->{"metadata_db_type"} eq "xmldb" ) {
        $queryString = "/nmwg:store[\@type=\"MAStore\"]/nmwg:data";
    }

    if ( $eventTypes->size() or $supportedEventTypes->size() ) {
        $queryString = $queryString . "[./nmwg:key/nmwg:parameters/nmwg:parameter[(\@name=\"supportedEventType\" or \@name=\"eventType\")";
        foreach my $e ( sort keys %et ) {
            $queryString = $queryString . " and (\@value=\"" . $e . "\" or text()=\"" . $e . "\")";
        }
        $queryString = $queryString . "]]";
    }
    my $dataResults = $parameters->{metadatadb}->querySet( { query => $queryString } );
    if ( $results->size() > 0 and $dataResults->size() > 0 ) {
        my %mds = ();
        foreach my $md ( $results->get_nodelist ) {
            my $curr_md_id = $md->getAttribute("id");
            next if not $curr_md_id;
            $mds{$curr_md_id} = $md;
        }

        foreach my $d ( $dataResults->get_nodelist ) {
            my $curr_d_mdIdRef = $d->getAttribute("metadataIdRef");
            next if ( not $curr_d_mdIdRef or not exists $mds{$curr_d_mdIdRef} );
            my $curr_md = $mds{$curr_d_mdIdRef};

            my $dId  = "data." . genuid();
            my $mdId = "metadata." . genuid();

            my $md_temp = $curr_md->cloneNode(1);
            $md_temp->setAttribute( "metadataIdRef", $curr_d_mdIdRef );
            $md_temp->setAttribute( "id",            $mdId );

            $parameters->{output}->addExistingXMLElement($md_temp);

            my $hashId  = $d->getAttribute("id");
            my $hashKey = $self->{CONF}->{"snmp"}->{"idToHash"}->{$hashId};

            next if ( not defined $hashKey );

            startData( $parameters->{output}, $dId, $mdId, undef );
            $parameters->{output}->startElement( { prefix => "nmwg", tag => "key", namespace => "http://ggf.org/ns/nmwg/base/2.0/" } );
            startParameters( $parameters->{output}, "params.0" );
            addParameter( $parameters->{output}, "maKey", $hashKey );

            my %attrs = ();
            $attrs{"type"} = $parameters->{time_settings}->{"START"}->{"type"} if $parameters->{time_settings}->{"START"}->{"type"};
            addParameter( $parameters->{output}, "startTime", $parameters->{time_settings}->{"START"}->{"value"}, \%attrs ) if ( defined $parameters->{time_settings}->{"START"}->{"value"} );

            %attrs = ();
            $attrs{"type"} = $parameters->{time_settings}->{"END"}->{"type"} if $parameters->{time_settings}->{"END"}->{"type"};
            addParameter( $parameters->{output}, "endTime", $parameters->{time_settings}->{"END"}->{"value"}, \%attrs ) if ( defined $parameters->{time_settings}->{"END"}->{"value"} );

            if ( defined $parameters->{time_settings}->{"RESOLUTION"} and $parameters->{time_settings}->{"RESOLUTION_SPECIFIED"} ) {
                addParameter( $parameters->{output}, "resolution", $parameters->{time_settings}->{"RESOLUTION"} );
            }
            addParameter( $parameters->{output}, "consolidationFunction", $parameters->{time_settings}->{"CF"} ) if ( defined $parameters->{time_settings}->{"CF"} );
            endParameters( $parameters->{output} );
            $parameters->{output}->endElement("key");
            endData( $parameters->{output} );
        }
    }
    else {
        my $msg = "Database \"" . $self->{CONF}->{"snmp"}->{"metadata_db_file"} . "\" returned 0 results for search";
        $self->{LOGGER}->error($msg);
        throw perfSONAR_PS::Error_compat( "error.ma.storage", $msg );
    }
    return;
}

=head2 maSetupDataRequest($self, $output, $md, $request, $message_parameters)

Main handler of SetupDataRequest messages.  Based on contents (i.e. was a
key sent in the request, or not) this will route to one of two functions:

 - setupDataRetrieveKey          - Handles all requests that enter with a 
                                   key present.  
 - setupDataRetrieveMetadataData - Handles all other requests
 
Chaining operations are handled internally, although chaining will eventually
be moved to the overall message handler as it is an important operation that
all services will need.

The goal of this message type is to return actual data, so after the metadata
section is resolved the appropriate data handler will be called to interact
with the database of choice (i.e. rrdtool, mysql, sqlite).  

=cut

sub maSetupDataRequest {
    my ( $self, @args ) = @_;
    my $parameters = validateParams(
        @args,
        {
            output             => 1,
            metadata           => 1,
            filters            => 1,
            time_settings      => 1,
            request            => 1,
            message_parameters => 1
        }
    );

    my $mdId  = q{};
    my $dId   = q{};
    my $error = q{};
    if ( $self->{CONF}->{"snmp"}->{"metadata_db_type"} eq "xmldb" ) {
        $self->{METADATADB} = $self->prepareDatabases( { doc => $parameters->{output} } );
        unless ( $self->{METADATADB} ) {
            throw perfSONAR_PS::Error_compat("Database could not be opened.");
            return;
        }
    }
    unless ( ( $self->{CONF}->{"snmp"}->{"metadata_db_type"} eq "file" )
        or ( $self->{CONF}->{"snmp"}->{"metadata_db_type"} eq "xmldb" ) )
    {
        throw perfSONAR_PS::Error_compat("Wrong value for 'metadata_db_type' set.");
        return;
    }

    my $nmwg_key = find( $parameters->{metadata}, "./nmwg:key", 1 );
    if ($nmwg_key) {
        $self->setupDataRetrieveKey(
            {
                metadatadb         => $self->{METADATADB},
                metadata           => $nmwg_key,
                filters            => $parameters->{filters},
                message_parameters => $parameters->{message_parameters},
                time_settings      => $parameters->{time_settings},
                request_namespaces => $parameters->{request}->getNamespaces(),
                output             => $parameters->{output}
            }
        );
    }
    else {
        $self->setupDataRetrieveMetadataData(
            {
                metadatadb         => $self->{METADATADB},
                metadata           => $parameters->{metadata},
                filters            => $parameters->{filters},
                time_settings      => $parameters->{time_settings},
                message_parameters => $parameters->{message_parameters},
                output             => $parameters->{output}
            }
        );
    }
    if ( $self->{CONF}->{"snmp"}->{"metadata_db_type"} eq "xmldb" ) {
        $self->{METADATADB}->closeDB( { error => \$error } );
    }
    return;
}

=head2 setupDataRetrieveKey($self, $metadatadb, $metadata, $chain, $id,
                            $message_parameters, $request_namespaces, $output)

Because the request entered with a key, we must handle it in this particular
function.  We first attempt to extract the 'maKey' hash and check for validity.
An invalid or missing key will trigger an error instantly.  If the key is found
we see if any chaining needs to be done.  We finally call the handle data
function, passing along the useful pieces of information from the metadata
database to locate and interact with the backend storage (i.e. rrdtool, mysql, 
sqlite).  

=cut

sub setupDataRetrieveKey {
    my ( $self, @args ) = @_;
    my $parameters = validateParams(
        @args,
        {
            metadatadb         => 1,
            metadata           => 1,
            filters            => 1,
            time_settings      => 1,
            message_parameters => 1,
            request_namespaces => 1,
            output             => 1
        }
    );

    my $mdId    = q{};
    my $dId     = q{};
    my $results = q{};

    my $hashKey = extract( find( $parameters->{metadata}, ".//nmwg:parameter[\@name=\"maKey\"]", 1 ), 0 );
    unless ($hashKey) {
        my $msg = "Key error in metadata storage.";
        $self->{LOGGER}->error($msg);
        throw perfSONAR_PS::Error_compat( "error.ma.storage_result", $msg );
        return;
    }

    my $hashId = $self->{CONF}->{"snmp"}->{"hashToId"}->{$hashKey};
    $self->{LOGGER}->debug("Received hash key $hashKey which maps to $hashId");
    unless ($hashId) {
        my $msg = "Key error in metadata storage.";
        $self->{LOGGER}->error($msg);
        throw perfSONAR_PS::Error_compat( "error.ma.storage_result", $msg );
        return;
    }

    my $query = q{};
    if ( $self->{CONF}->{"snmp"}->{"metadata_db_type"} eq "file" ) {
        $query = "/nmwg:store/nmwg:data[\@id=\"" . $hashId . "\"]";
    }
    elsif ( $self->{CONF}->{"snmp"}->{"metadata_db_type"} eq "xmldb" ) {
        $query = "/nmwg:store[\@type=\"MAStore\"]/nmwg:data[\@id=\"" . $hashId . "\"]";
    }

    $results = $parameters->{metadatadb}->querySet( { query => $query } );
    if ( $results->size() != 1 ) {
        my $msg = "Key error in metadata storage.";
        $self->{LOGGER}->error($msg);
        throw perfSONAR_PS::Error_compat( "error.ma.storage_result", $msg );
        return;
    }

    my $sentKey      = $parameters->{metadata}->cloneNode(1);
    my $results_temp = $results->get_node(1)->cloneNode(1);
    my $storedKey    = find( $results_temp, "./nmwg:key", 1 );

    my %l_et = ();
    my $l_supportedEventTypes = find( $storedKey, ".//nmwg:parameter[\@name=\"supportedEventType\" or \@name=\"eventType\"]", 0 );
    foreach my $se ( $l_supportedEventTypes->get_nodelist ) {
        my $value = extract( $se, 0 );
        if ($value) {
            $l_et{$value} = 1;
        }
    }

    $mdId = "metadata." . genuid();
    $dId  = "data." . genuid();

    my $mdIdRef = $parameters->{metadata}->getAttribute("id");

    my @filters = @{ $parameters->{filters} };

    if ( $#filters > -1 ) {
        $self->addSelectParameters( { parameter_block => find( $sentKey, ".//nmwg:parameters", 1 ), filters => \@filters } );

        $mdIdRef = $filters[-1][0]->getAttribute("id");
    }

    createMetadata( $parameters->{output}, $mdId, $mdIdRef, $sentKey->toString, undef );
    $self->handleData(
        {
            id                 => $mdId,
            data               => $results_temp,
            output             => $parameters->{output},
            time_settings      => $parameters->{time_settings},
            et                 => \%l_et,
            message_parameters => $parameters->{message_parameters}
        }
    );

    return;
}

=head2 setupDataRetrieveMetadataData($self, $metadatadb, $metadata, $id, 
                                     $message_parameters, $output)

Similar to 'setupDataRetrieveKey' we are looking to return data.  The input
will be partially or fully specified metadata.  If this matches something in
the database we will return a data matching the description.  If this metadata
was a part of a chain the chaining will be resolved passed along to the data
handling function.

=cut

sub setupDataRetrieveMetadataData {
    my ( $self, @args ) = @_;
    my $parameters = validateParams(
        @args,
        {
            metadatadb         => 1,
            metadata           => 1,
            filters            => 1,
            time_settings      => 1,
            message_parameters => 1,
            output             => 1
        }
    );

    my $mdId = q{};
    my $dId  = q{};

    my $queryString = q{};
    if ( $self->{CONF}->{"snmp"}->{"metadata_db_type"} eq "file" ) {
        $queryString = "/nmwg:store/nmwg:metadata[" . getMetadataXQuery( { node => $parameters->{metadata} } ) . "]";
    }
    elsif ( $self->{CONF}->{"snmp"}->{"metadata_db_type"} eq "xmldb" ) {
        $queryString = "/nmwg:store[\@type=\"MAStore\"]/nmwg:metadata[" . getMetadataXQuery( { node => $parameters->{metadata} } ) . "]";
    }

    my $results = $parameters->{metadatadb}->querySet( { query => $queryString } );

    my %et                  = ();
    my $eventTypes          = find( $parameters->{metadata}, "./nmwg:eventType", 0 );
    my $supportedEventTypes = find( $parameters->{metadata}, ".//nmwg:parameter[\@name=\"supportedEventType\" or \@name=\"eventType\"]", 0 );
    foreach my $e ( $eventTypes->get_nodelist ) {
        my $value = extract( $e, 0 );
        if ($value) {
            $et{$value} = 1;
        }
    }
    foreach my $se ( $supportedEventTypes->get_nodelist ) {
        my $value = extract( $se, 0 );
        if ($value) {
            $et{$value} = 1;
        }
    }

    if ( $self->{CONF}->{"snmp"}->{"metadata_db_type"} eq "file" ) {
        $queryString = "/nmwg:store/nmwg:data";
    }
    elsif ( $self->{CONF}->{"snmp"}->{"metadata_db_type"} eq "xmldb" ) {
        $queryString = "/nmwg:store[\@type=\"MAStore\"]/nmwg:data";
    }

    if ( $eventTypes->size() or $supportedEventTypes->size() ) {
        $queryString = $queryString . "[./nmwg:key/nmwg:parameters/nmwg:parameter[(\@name=\"supportedEventType\" or \@name=\"eventType\")";
        foreach my $e ( sort keys %et ) {
            $queryString = $queryString . " and (\@value=\"" . $e . "\" or text()=\"" . $e . "\")";
        }
        $queryString = $queryString . "]]";
    }
    my $dataResults = $parameters->{metadatadb}->querySet( { query => $queryString } );

    my %used = ();
    for my $x ( 0 .. $dataResults->size() ) {
        $used{$x} = 0;
    }

    my $base_id = $parameters->{metadata}->getAttribute("id");
    my @filters = @{ $parameters->{filters} };
    if ( $#filters > -1 ) {
        my @filter_arr = @{ $filters[-1] };

        $base_id = $filter_arr[0]->getAttribute("id");
    }

    if ( $results->size() > 0 and $dataResults->size() > 0 ) {
        my %mds = ();
        foreach my $md ( $results->get_nodelist ) {
            next if not $md->getAttribute("id");

            my %l_et                  = ();
            my $l_eventTypes          = find( $md, "./nmwg:eventType", 0 );
            my $l_supportedEventTypes = find( $md, ".//nmwg:parameter[\@name=\"supportedEventType\" or \@name=\"eventType\"]", 0 );
            foreach my $e ( $l_eventTypes->get_nodelist ) {
                my $value = extract( $e, 0 );
                if ($value) {
                    $l_et{$value} = 1;
                }
            }
            foreach my $se ( $l_supportedEventTypes->get_nodelist ) {
                my $value = extract( $se, 0 );
                if ($value) {
                    $l_et{$value} = 1;
                }
            }

            my %hash = ();
            $hash{"md"}                     = $md;
            $hash{"et"}                     = \%l_et;
            $mds{ $md->getAttribute("id") } = \%hash;
        }

        foreach my $d ( $dataResults->get_nodelist ) {
            my $idRef = $d->getAttribute("metadataIdRef");

            next if ( not defined $idRef or not defined $mds{$idRef} );

            my $md_temp = $mds{$idRef}->{"md"}->cloneNode(1);
            my $d_temp  = $d->cloneNode(1);
            $mdId = "metadata." . genuid();
            $md_temp->setAttribute( "metadataIdRef", $base_id );
            $md_temp->setAttribute( "id",            $mdId );
            $parameters->{output}->addExistingXMLElement($md_temp);
            $self->handleData(
                {
                    id                 => $mdId,
                    data               => $d_temp,
                    output             => $parameters->{output},
                    time_settings      => $parameters->{time_settings},
                    et                 => $mds{$idRef}->{"et"},
                    message_parameters => $parameters->{message_parameters}
                }
            );
        }
    }
    else {
        my $msg = "Database \"" . $self->{CONF}->{"snmp"}->{"metadata_db_file"} . "\" returned 0 results for search";
        $self->{LOGGER}->error($msg);
        throw perfSONAR_PS::Error_compat( "error.ma.storage", $msg );
    }
    return;
}

=head2 handleData($self, $id, $data, $output, $et, $message_parameters)

Directs the data retrieval operations based on a value found in the metadata
database's representation of the key (i.e. storage 'type').  Current offerings
only interact with rrd files and sql databases.

=cut

sub handleData {
    my ( $self, @args ) = @_;
    my $parameters = validateParams(
        @args,
        {
            id                 => 1,
            data               => 1,
            output             => 1,
            et                 => 1,
            time_settings      => 1,
            message_parameters => 1
        }
    );

    my $type = extract( find( $parameters->{data}, "./nmwg:key/nmwg:parameters/nmwg:parameter[\@name=\"type\"]", 1 ), 0 );
    if ( $type eq "rrd" ) {
        $self->retrieveRRD(
            {
                d                  => $parameters->{data},
                mid                => $parameters->{id},
                output             => $parameters->{output},
                time_settings      => $parameters->{time_settings},
                et                 => $parameters->{et},
                message_parameters => $parameters->{et}
            }

        );
    }
    elsif ( $type eq "sqlite" ) {
        $self->retrieveSQL(

            {
                d                  => $parameters->{data},
                mid                => $parameters->{id},
                output             => $parameters->{output},
                time_settings      => $parameters->{time_settings},
                et                 => $parameters->{et},
                message_parameters => $parameters->{et}
            }
        );
    }
    else {
        my $msg = "Database \"" . $type . "\" is not yet supported";
        $self->{LOGGER}->error($msg);
        getResultCodeData( $parameters->{output}, "data." . genuid(), $parameters->{id}, $msg, 1 );
    }
    return;
}

=head2 retrieveSQL($self, $d, $mid, $output, $et, $message_parameters)

Given some 'startup' knowledge such as the name of the database and any
credentials to connect with it, we start a connection and query the database
for given values.  These values are prepared into XML response content and
return in the response message.

=cut

sub retrieveSQL {
    my ( $self, @args ) = @_;
    my $parameters = validateParams(
        @args,
        {
            d                  => 1,
            mid                => 1,
            time_settings      => 1,
            output             => 1,
            et                 => 1,
            message_parameters => 1
        }
    );

    my $datumns  = 0;
    my $timeType = q{};

    if ( defined $parameters->{message_parameters}->{"eventNameSpaceSynchronization"}
        and lc( $parameters->{message_parameters}->{"eventNameSpaceSynchronization"} ) eq "true" )
    {
        $datumns = 1;
    }

    if ( defined $parameters->{message_parameters}->{"timeType"} ) {
        if ( lc( $parameters->{message_parameters}->{"timeType"} ) eq "unix" ) {
            $timeType = "unix";
        }
        elsif ( lc( $parameters->{message_parameters}->{"timeType"} ) eq "iso" ) {
            $timeType = "iso";
        }
    }

    $self->{LOGGER}->error("No data element") if ( not defined $parameters->{d} );

    my $file   = extract( find( $parameters->{d}, "./nmwg:key//nmwg:parameter[\@name=\"file\"]",  1 ), 1 );
    my $table  = extract( find( $parameters->{d}, "./nmwg:key//nmwg:parameter[\@name=\"table\"]", 1 ), 1 );
    my $dbuser = extract( find( $parameters->{d}, "./nmwg:key//nmwg:parameter[\@name=\"user\"]",  1 ), 1 );
    my $dbpass = extract( find( $parameters->{d}, "./nmwg:key//nmwg:parameter[\@name=\"pass\"]",  1 ), 1 );

    unless ( $file and $table ) {
        $self->{LOGGER}->error( "Data element " . $parameters->{d}->getAttribute("id") . " is missing some SQL elements" );
        throw perfSONAR_PS::Error_compat( "error.ma.storage", "Unable to open associated database" );
    }

    print "\n\nFILE: ", $file, "\n\n";

    my $backup = $file;
    if ( $backup =~ m/^DBI:SQLite:dbname=/mx ) {
        $backup =~ s/^DBI:SQLite:dbname=//mx;
    }
    if ( $self->{DIRECTORY} ) {
        if ( !( $backup =~ "^/" ) ) {
            $backup = $self->{DIRECTORY} . "/" . $backup;
        }
    }
    $file = "dbi:SQLite:dbname=" . $backup;

    print "\n\nFILE: ", $file, "\n\n";

    my $query = {};
    if ( $parameters->{time_settings}->{"START"}->{"internal"} or $parameters->{time_settings}->{"END"}->{"internal"} ) {
        $query = "select * from " . $table . " where id=\"" . $parameters->{d}->getAttribute("metadataIdRef") . "\" and";
        my $queryCount = 0;
        if ( $parameters->{time_settings}->{"START"}->{"internal"} ) {
            $query = $query . " time > " . $parameters->{time_settings}->{"START"}->{"internal"};
            $queryCount++;
        }
        if ( $parameters->{time_settings}->{"END"}->{"internal"} ) {
            if ($queryCount) {
                $query = $query . " and time < " . $parameters->{time_settings}->{"END"}->{"internal"} . ";";
            }
            else {
                $query = $query . " time < " . $parameters->{time_settings}->{"END"}->{"internal"} . ";";
            }
        }
    }
    else {
        $query = "select * from " . $table . " where id=\"" . $parameters->{d}->getAttribute("metadataIdRef") . "\";";
    }

    my @dbSchema = ( "id", "time", "value", "eventtype", "misc" );
    my $datadb = new perfSONAR_PS::DB::SQL( { name => $file, schema => \@dbSchema, user => $dbuser, pass => $dbpass } );

    $datadb->openDB;
    my $result = $datadb->query( { query => $query } );
    $datadb->closeDB;

    my $id = "data." . genuid();
    if ( $#{$result} == -1 ) {
        my $msg = "Query returned 0 results";
        $self->{LOGGER}->error($msg);
        getResultCodeData( $parameters->{output}, $id, $parameters->{mid}, $msg, 1 );
    }
    else {
        my $prefix = "nmwg";
        my $uri    = "http://ggf.org/ns/nmwg/base/2.0/";

        if ($datumns) {
            if ( defined $parameters->{et} and $parameters->{et} ne q{} ) {
                foreach my $e ( sort keys %{ $parameters->{et} } ) {
                    next if $e eq "http://ggf.org/ns/nmwg/tools/snmp/2.0/";
                    $uri = $e;
                }
            }
            if ( $uri ne "http://ggf.org/ns/nmwg/base/2.0" ) {
                foreach my $r ( sort keys %{ $self->{NAMESPACES} } ) {
                    if ( ( $uri . "/" ) eq $self->{NAMESPACES}->{$r} ) {
                        $prefix = $r;
                        last;
                    }
                }
                if ( !$prefix ) {
                    $prefix = "nmwg";
                    $uri    = "http://ggf.org/ns/nmwg/base/2.0/";
                }
            }
        }

        startData( $parameters->{output}, $id, $parameters->{mid}, undef );
        my $len = $#{$result};
        for my $a ( 0 .. $len ) {
            my %attrs = ();
            if ( $timeType eq "iso" ) {
                my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = gmtime( $result->[$a][1] );
                $attrs{"timeType"} = "ISO";
                $attrs{ $dbSchema[1] . "Value" } = sprintf "%04d-%02d-%02dT%02d:%02d:%02dZ\n", ( $year + 1900 ), ( $mon + 1 ), $mday, $hour, $min, $sec;
            }
            else {
                $attrs{"timeType"} = "unix";
                $attrs{ $dbSchema[1] . "Value" } = $result->[$a][1];
            }
            $attrs{ $dbSchema[2] } = $result->[$a][2];

            my @misc = split( /,/xm, $result->[$a][4] );
            foreach my $m (@misc) {
                my @pair = split( /=/xm, $m );
                $attrs{ $pair[0] } = $pair[1];
            }

            $parameters->{output}->createElement(
                prefix     => $prefix,
                namespace  => $uri,
                tag        => "datum",
                attributes => \%attrs
            );
        }
        endData( $parameters->{output} );
    }
    return;
}

=head2 retrieveRRD($self, $d, $mid, $output, $et, $message_parameters)

Given some 'startup' knowledge such as the name of the database and any
credentials to connect with it, we start a connection and query the database
for given values.  These values are prepared into XML response content and
return in the response message.

=cut

sub retrieveRRD {
    my ( $self, @args ) = @_;
    my $parameters = validateParams(
        @args,
        {
            d                  => 1,
            mid                => 1,
            time_settings      => 1,
            output             => 1,
            et                 => 1,
            message_parameters => 1
        }
    );

    my $timeSettings = $parameters->{time_settings};

    my ( $sec, $frac ) = Time::HiRes::gettimeofday;
    my $datumns  = 0;
    my $timeType = q{};

    if ( defined $parameters->{message_parameters}->{"eventNameSpaceSynchronization"}
        and lc( $parameters->{message_parameters}->{"eventNameSpaceSynchronization"} ) eq "true" )
    {
        $datumns = 1;
    }

    if ( defined $parameters->{message_parameters}->{"timeType"} ) {
        if ( lc( $parameters->{message_parameters}->{"timeType"} ) eq "unix" ) {
            $timeType = "unix";
        }
        elsif ( lc( $parameters->{message_parameters}->{"timeType"} ) eq "iso" ) {
            $timeType = "iso";
        }
    }

    my $file_element = find( $parameters->{d}, "./nmwg:key//nmwg:parameter[\@name=\"file\"]", 1 );

    my $rrd_file = extract( $file_element, 1 );

    if ( not $rrd_file ) {
        $self->{LOGGER}->error( "Data element " . $parameters->{d}->getAttribute("id") . " is missing some RRD file" );
        throw perfSONAR_PS::Error_compat( "error.ma.storage", "Unable to open associated RRD file" );
    }

    adjustRRDTime( { timeSettings => $timeSettings } );
    my $id = "data." . genuid();
    my %rrd_result = getDataRRD( { directory => $self->{DIRECTORY}, file => $rrd_file, timeSettings => $timeSettings, rrdtool => $self->{CONF}->{"snmp"}->{"rrdtool"} } );
    if ( $rrd_result{ERROR} ) {
        $self->{LOGGER}->error( "RRD error seen: " . $rrd_result{ERROR} );
        getResultCodeData( $parameters->{output}, $id, $parameters->{mid}, $rrd_result{ERROR}, 1 );
    }
    else {
        my $prefix = "nmwg";
        my $uri    = "http://ggf.org/ns/nmwg/base/2.0/";
        if ($datumns) {
            if ( defined $parameters->{et} and $parameters->{et} ne q{} ) {
                foreach my $e ( sort keys %{ $parameters->{et} } ) {
                    next if $e eq "http://ggf.org/ns/nmwg/tools/snmp/2.0/";
                    $uri = $e;
                }
            }
            if ( $uri ne "http://ggf.org/ns/nmwg/base/2.0" ) {
                foreach my $r ( sort keys %{ $self->{NAMESPACES} } ) {
                    if ( ( $uri . "/" ) eq $self->{NAMESPACES}->{$r} ) {
                        $prefix = $r;
                        last;
                    }
                }
                if ( !$prefix ) {
                    $prefix = "nmwg";
                    $uri    = "http://ggf.org/ns/nmwg/base/2.0/";
                }
            }
        }

        my $dataSource = extract( find( $parameters->{d}, "./nmwg:key//nmwg:parameter[\@name=\"dataSource\"]", 1 ), 0 );
        my $valueUnits = extract( find( $parameters->{d}, "./nmwg:key//nmwg:parameter[\@name=\"valueUnits\"]", 1 ), 0 );

        startData( $parameters->{output}, $id, $parameters->{mid}, undef );
        foreach my $a ( sort( keys(%rrd_result) ) ) {
            if ( $a < $sec ) {
                my %attrs = ();
                if ( $timeType eq "iso" ) {
                    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = gmtime($a);
                    $attrs{"timeType"} = "ISO";
                    $attrs{"timeValue"} = sprintf "%04d-%02d-%02dT%02d:%02d:%02dZ\n", ( $year + 1900 ), ( $mon + 1 ), $mday, $hour, $min, $sec;
                }
                else {
                    $attrs{"timeType"}  = "unix";
                    $attrs{"timeValue"} = $a;
                }
                $attrs{"value"}      = $rrd_result{$a}{$dataSource};
                $attrs{"valueUnits"} = $valueUnits;

                $parameters->{output}->createElement(
                    prefix     => $prefix,
                    namespace  => $uri,
                    tag        => "datum",
                    attributes => \%attrs
                );
            }
        }
        endData( $parameters->{output} );
    }
    return;
}

=head2 addSelectParameters($self, { parameter_block, filters })

Re-construct the parameters block.

=cut

sub addSelectParameters {
    my ( $self, @args ) = @_;
    my $parameters = validateParams(
        @args,
        {
            parameter_block => 1,
            filters         => 1,
        }
    );

    my $params       = $parameters->{parameter_block};
    my @filters      = @{ $parameters->{filters} };
    my %paramsByName = ();

    foreach my $p ( $params->childNodes ) {
        if ( $p->localname and $p->localname eq "parameter" and $p->getAttribute("name") ) {
            $paramsByName{ $p->getAttribute("name") } = $p;
        }
    }

    foreach my $filter_arr (@filters) {
        my @filters = @{$filter_arr};
        my $filter  = $filters[-1];

        $self->{LOGGER}->debug( "Filter: " . $filter->toString );

        my $select_params = find( $filter, "./select:parameters", 1 );
        if ($select_params) {
            foreach my $p ( $select_params->childNodes ) {
                if ( $p->localname and $p->localname eq "parameter" and $p->getAttribute("name") ) {
                    my $newChild = $p->cloneNode(1);
                    if ( $paramsByName{ $p->getAttribute("name") } ) {
                        $params->replaceChild( $newChild, $paramsByName{ $p->getAttribute("name") } );
                    }
                    else {
                        $params->addChild($newChild);
                    }
                    $paramsByName{ $p->getAttribute("name") } = $newChild;
                }
            }
        }
    }
    return;
}

1;

__END__

=head1 SEE ALSO

L<Log::Log4perl>, L<Module::Load>, L<Digest::MD5>, L<English>,
L<Params::Validate>, L<Date::Manip>, L<perfSONAR_PS::Services::MA::General>, 
L<perfSONAR_PS::Common>, L<perfSONAR_PS::Messages>,
L<perfSONAR_PS::Client::LS::Remote>, L<perfSONAR_PS::Error_compat>,
L<perfSONAR_PS::DB::File>, L<perfSONAR_PS::DB::RRD>, L<perfSONAR_PS::DB::SQL>

To join the 'perfSONAR-PS' mailing list, please visit:

  https://mail.internet2.edu/wws/info/i2-perfsonar

The perfSONAR-PS subversion repository is located at:

  https://svn.internet2.edu/svn/perfSONAR-PS

Questions and comments can be directed to the author, or the mailing list.
Bugs, feature requests, and improvements can be directed here:

  https://bugs.internet2.edu/jira/browse/PSPS

=head1 VERSION

$Id: SNMP.pm 1877 2008-03-27 16:33:01Z aaron $

=head1 AUTHOR

Jason Zurawski, zurawski@internet2.edu

=head1 LICENSE

You should have received a copy of the Internet2 Intellectual Property Framework
along with this software.  If not, see
<http://www.internet2.edu/membership/ip.html>

=head1 COPYRIGHT

Copyright (c) 2004-2008, Internet2 and the University of Delaware

All rights reserved.

=cut

