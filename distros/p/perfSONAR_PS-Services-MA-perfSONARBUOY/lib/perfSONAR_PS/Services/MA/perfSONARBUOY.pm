package perfSONAR_PS::Services::MA::perfSONARBUOY;

use base 'perfSONAR_PS::Services::Base';

use fields 'LS_CLIENT', 'NAMESPACES', 'METADATADB', 'LOGGER';

use strict;
use warnings;

our $VERSION = 0.09;

=head1 NAME

perfSONAR_PS::Services::MA::perfSONARBUOY - A module that provides methods for
the perfSONARBUOY MA.  perfSONARBUOY exposes data formerly collected by the 
AMI framework, including BWCTL and OWAMP data.  This data is stored in a 
database backend (commonly MySQL).  The webservices interface provided by this
MA currently exposes only iperf data collected via BWCTL.

=head1 DESCRIPTION

This module, in conjunction with other parts of the perfSONAR-PS framework,
handles specific messages from interested actors in search of BWCTL/OWAMP data.
There are three major message types that this service can act upon:

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
use Sys::Hostname;
use Fcntl ':flock';
use Date::Manip;
use Math::BigInt;

use perfSONAR_PS::OWP;
use perfSONAR_PS::OWP::Utils;
use perfSONAR_PS::Services::MA::General;
use perfSONAR_PS::Common;
use perfSONAR_PS::Messages;
use perfSONAR_PS::Client::LS::Remote;
use perfSONAR_PS::Error_compat qw/:try/;
use perfSONAR_PS::DB::File;
use perfSONAR_PS::DB::SQL;
use perfSONAR_PS::ParameterValidation;

my %ma_namespaces = (
    nmwg      => "http://ggf.org/ns/nmwg/base/2.0/",
    nmtm      => "http://ggf.org/ns/nmwg/time/2.0/",
    ifevt     => "http://ggf.org/ns/nmwg/event/status/base/2.0/",
    iperf     => "http://ggf.org/ns/nmwg/tools/iperf/2.0/",
    bwctl     => "http://ggf.org/ns/nmwg/tools/bwctl/2.0/",
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
    nmwgr     => "http://ggf.org/ns/nmwg/result/2.0/",
    owamp     => "http://ggf.org/ns/nmwg/tools/owamp/2.0/"
);

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
    $self->{LOGGER} = get_logger("perfSONAR_PS::Services::MA::perfSONARBUOY");

    unless ( exists $self->{CONF}->{"perfsonarbuoy"}->{"owmesh"}
        and $self->{CONF}->{"perfsonarbuoy"}->{"owmesh"} )
    {
        $self->{LOGGER}->error("Value for 'owmesh' is not set.");
        return -1;
    }
    else {
        if ( defined $self->{DIRECTORY} ) {
            unless ( $self->{CONF}->{"perfsonarbuoy"}->{"owmesh"} =~ "^/" ) {
                $self->{CONF}->{"perfsonarbuoy"}->{"owmesh"} = $self->{DIRECTORY} . "/" . $self->{CONF}->{"perfsonarbuoy"}->{"owmesh"};
            }
        }
    }

    unless ( exists $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"}
        and $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} )
    {
        $self->{LOGGER}->error("Value for 'metadata_db_type' is not set.");
        return -1;
    }

    if ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "file" ) {
        unless ( exists $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_file"}
            and $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_file"} )
        {
            $self->{LOGGER}->error("Value for 'metadata_db_file' is not set.");
            return -1;
        }
        else {
            if ( defined $self->{DIRECTORY} ) {
                unless ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_file"} =~ "^/" ) {
                    $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_file"} = $self->{DIRECTORY} . "/" . $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_file"};
                }
            }
        }
    }
    elsif ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "xmldb" ) {
        eval { load perfSONAR_PS::DB::XMLDB; };
        if ($EVAL_ERROR) {
            $self->{LOGGER}->error("Couldn't load perfSONAR_PS::DB::XMLDB: $EVAL_ERROR");
            return -1;
        }

        unless ( exists $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_file"}
            and $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_file"} )
        {
            $self->{LOGGER}->error("Value for 'metadata_db_file' is not set.");
            return -1;
        }
        unless ( exists $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_name"}
            and $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_name"} )
        {
            $self->{LOGGER}->error("Value for 'metadata_db_name' is not set.");
            return -1;
        }
        else {
            if ( defined $self->{DIRECTORY} ) {
                unless ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_name"} =~ "^/" ) {
                    $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_name"} = $self->{DIRECTORY} . "/" . $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_name"};
                }
            }
        }
    }
    else {
        $self->{LOGGER}->error("Wrong value for 'metadata_db_type' set.");
        return -1;
    }

    unless ( exists $self->{CONF}->{"perfsonarbuoy"}->{"enable_registration"}
        and $self->{CONF}->{"perfsonarbuoy"}->{"enable_registration"} )
    {
        $self->{CONF}->{"perfsonarbuoy"}->{"enable_registration"} = 0;
    }

    if ( $self->{CONF}->{"perfsonarbuoy"}->{"enable_registration"} ) {
        unless ( exists $self->{CONF}->{"perfsonarbuoy"}->{"service_accesspoint"}
            and $self->{CONF}->{"perfsonarbuoy"}->{"service_accesspoint"} )
        {
            $self->{LOGGER}->error("No access point specified for perfSONARBUOY service");
            return -1;
        }

        unless ( exists $self->{CONF}->{"perfsonarbuoy"}->{"ls_instance"}
            and $self->{CONF}->{"perfsonarbuoy"}->{"ls_instance"} )
        {
            if ( defined $self->{CONF}->{"ls_instance"}
                and $self->{CONF}->{"ls_instance"} )
            {
                $self->{CONF}->{"perfsonarbuoy"}->{"ls_instance"} = $self->{CONF}->{"ls_instance"};
            }
            else {
                $self->{LOGGER}->error("No LS instance specified for perfSONARBUOY service");
                return -1;
            }
        }

        unless ( exists $self->{CONF}->{"perfsonarbuoy"}->{"ls_registration_interval"}
            and $self->{CONF}->{"perfsonarbuoy"}->{"ls_registration_interval"} )
        {
            if ( defined $self->{CONF}->{"ls_registration_interval"}
                and $self->{CONF}->{"ls_registration_interval"} )
            {
                $self->{CONF}->{"perfsonarbuoy"}->{"ls_registration_interval"} = $self->{CONF}->{"ls_registration_interval"};
            }
            else {
                $self->{LOGGER}->warn("Setting registration interval to 30 minutes");
                $self->{CONF}->{"perfsonarbuoy"}->{"ls_registration_interval"} = 1800;
            }
        }

        unless ( exists $self->{CONF}->{"perfsonarbuoy"}->{"service_accesspoint"}
            and $self->{CONF}->{"perfsonarbuoy"}->{"service_accesspoint"} )
        {
            $self->{CONF}->{"perfsonarbuoy"}->{"service_accesspoint"} = "http://localhost:" . $self->{PORT} . "/" . $self->{ENDPOINT};
            $self->{LOGGER}->warn( "Setting 'service_accesspoint' to 'http://localhost:" . $self->{PORT} . "/" . $self->{ENDPOINT} . "'." );
        }

        unless ( exists $self->{CONF}->{"perfsonarbuoy"}->{"service_description"}
            and $self->{CONF}->{"perfsonarbuoy"}->{"service_description"} )
        {
            $self->{CONF}->{"perfsonarbuoy"}->{"service_description"} = "perfSONAR_PS perfSONARBUOY MA";
            $self->{LOGGER}->warn("Setting 'service_description' to 'perfSONAR_PS perfSONARBUOY MA'.");
        }

        unless ( exists $self->{CONF}->{"perfsonarbuoy"}->{"service_name"}
            and $self->{CONF}->{"perfsonarbuoy"}->{"service_name"} )
        {
            $self->{CONF}->{"perfsonarbuoy"}->{"service_name"} = "perfSONARBUOY MA";
            $self->{LOGGER}->warn("Setting 'service_name' to 'perfSONARBUOY MA'.");
        }

        unless ( exists $self->{CONF}->{"perfsonarbuoy"}->{"service_type"}
            and $self->{CONF}->{"perfsonarbuoy"}->{"service_type"} )
        {
            $self->{CONF}->{"perfsonarbuoy"}->{"service_type"} = "MA";
            $self->{LOGGER}->warn("Setting 'service_type' to 'MA'.");
        }
    }

    $handler->registerMessageHandler( "SetupDataRequest",   $self );
    $handler->registerMessageHandler( "MetadataKeyRequest", $self );

    my $error = q{};
    if ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "file" ) {
        unless ( $self->createStorage( {} ) == 0 ) {
            $self->{LOGGER}->error("Couldn't load the store file.");
            return -1;
        }

        $self->{METADATADB} = new perfSONAR_PS::DB::File( { file => $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_file"} } );
        $self->{METADATADB}->openDB( { error => \$error } );
        unless ( $self->{METADATADB} ) {
            $self->{LOGGER}->error("Couldn't initialize store file: $error");
            return -1;
        }
    }
    elsif ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "xmldb" ) {
        my $error      = q{};
        my $metadatadb = $self->prepareDatabases;
        unless ($metadatadb) {
            $self->{LOGGER}->error( "There was an error opening \"" . $self->{CONF}->{"ls"}->{"metadata_db_name"} . "/" . $self->{CONF}->{"ls"}->{"metadata_db_file"} . "\": " . $error );
            return -1;
        }

        unless ( $self->createStorage( { metadatadb => $metadatadb } ) == 0 ) {
            $self->{LOGGER}->error("Couldn't load the XMLDB.");
            return -1;
        }

        $metadatadb->closeDB( { error => \$error } );
        $self->{METADATADB} = q{};
    }
    else {
        $self->{LOGGER}->error("Wrong value for 'metadata_db_type' set.");
        return -1;
    }

    return 0;
}

=head2 createStorage($self { metadatadb } )

Given the information in the AMI databases, construct appropriate metadata
structures into either a file or the XMLDB.  This allows us to maintain the 
query mechanisms as defined by the other services.  Also performs the steps
necessary for building the 'key' cache that will speed up access to the data
by providing a fast handle that points directly to a key.

=cut

sub createStorage {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { metadatadb => 0 } );

    # XXX: jason 3/4/08
    # have owmesh file specify the host instead, this assumes the mysql database
    #  lives on the same host as the MA currently.
    #
    my %defaults = (
        DBHOST  => hostname(),
        CONFDIR => $self->{CONF}->{"perfsonarbuoy"}->{"owmesh"}
    );
    my $conf = new perfSONAR_PS::OWP::Conf(%defaults);

    my $dbsource = $conf->{'BWCENTRALDBTYPE'} . ":" . $conf->{'BWCENTRALDBNAME'} . ":" . $conf->{'DBHOST'};

    my @dbSchema_nodes = ( "node_id", "node_name", "uptime_addr", "uptime_port" );
    my @dbSchema_meshes = ( "mesh_id", "mesh_name", "mesh_desc", "tool_name", "addr_type" );
    my @dbSchema_node_mesh_map = ( "mesh_id", "node_id" );
    my $db = new perfSONAR_PS::DB::SQL( { name => $dbsource, schema => \@dbSchema_nodes, user => $conf->{'BWCENTRALDBUSER'}, pass => $conf->{'BWCENTRALDBPASS'} } );
    $db->openDB;

    my $result_nodes = $db->query( { query => "select * from nodes" } );
    my %nodes        = ();
    my $data_len     = $#{$result_nodes};
    for my $x ( 0 .. $data_len ) {
        my $data_len2 = $#{ $result_nodes->[$x] };
        my %temp      = ();
        for my $z ( 1 .. $data_len2 ) {
            $temp{ $dbSchema_nodes[$z] } = $result_nodes->[$x][$z];
        }
        $nodes{ $x + 1 } = \%temp;
    }

    $db->setSchema( { schema => \@dbSchema_meshes } );
    my $result_meshes = $db->query( { query => "select * from meshes" } );
    my %meshes = ();
    $data_len = $#{$result_meshes};
    for my $x ( 0 .. $data_len ) {
        my $data_len2 = $#{ $result_meshes->[$x] };
        my %temp      = ();
        for my $z ( 1 .. $data_len2 ) {
            $temp{ $dbSchema_meshes[$z] } = $result_meshes->[$x][$z];
        }
        $meshes{ $x + 1 } = \%temp;
    }

    $db->setSchema( { schema => \@dbSchema_node_mesh_map } );
    my $result_node_mesh_map = $db->query( { query => "select * from node_mesh_map" } );
    $db->closeDB;

    if ( $#{$result_nodes} == -1 or $#{$result_meshes} == -1 or $#{$result_node_mesh_map} == -1 ) {
        $self->{LOGGER}->error("Database query returned 0 results, aborting.");
        return -1;
    }

    my $error     = q{};
    my $errorFlag = 0;
    my $dbTr      = q{};
    if ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "xmldb" ) {

        unless ( exists $parameters->{metadatadb} and $parameters->{metadatadb} ) {
            $parameters->{metadatadb} = $self->prepareDatabases;
            unless ( $parameters->{metadatadb} ) {
                $self->{LOGGER}->error( "There was an error opening \"" . $self->{CONF}->{"ls"}->{"metadata_db_name"} . "/" . $self->{CONF}->{"ls"}->{"metadata_db_file"} . "\": " . $error );
                return -1;
            }
        }

        $dbTr = $parameters->{metadatadb}->getTransaction( { error => \$error } );
        unless ($dbTr) {
            $parameters->{metadatadb}->abortTransaction( { txn => $dbTr, error => \$error } ) if $dbTr;
            undef $dbTr;
            $self->{LOGGER}->error( "Database error: \"" . $error . "\", aborting." );
            return -1;
        }
    }
    elsif ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "file" ) {
        my $fh = new IO::File "> " . $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_file"};
        if ( defined $fh ) {
            print $fh "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
            print $fh "<nmwg:store xmlns:nmwg=\"http://ggf.org/ns/nmwg/base/2.0/\"\n";
            print $fh "            xmlns:nmwgt=\"http://ggf.org/ns/nmwg/topology/2.0/\"\n";
            print $fh "            xmlns:iperf= \"http://ggf.org/ns/nmwg/tools/iperf/2.0/\">\n\n";
            $fh->close;
        }
        else {
            $self->{LOGGER}->error("File cannot be written.");
            return -1;
        }
    }
    else {
        $self->{LOGGER}->error("Wrong value for 'metadata_db_type' set.");
        return -1;
    }

    my $id = 1;
    $data_len = $#{$result_node_mesh_map};
    for my $x ( 0 .. $data_len ) {
        for my $y ( 0 .. $data_len ) {
            if (    $meshes{ $result_node_mesh_map->[$x][0] }->{"mesh_name"} eq $meshes{ $result_node_mesh_map->[$y][0] }->{"mesh_name"}
                and $nodes{ $result_node_mesh_map->[$x][1] }->{"node_name"} ne $nodes{ $result_node_mesh_map->[$y][1] }->{"node_name"} )
            {
                my $metadata = q{};
                $metadata = "<nmwg:metadata xmlns:nmwg=\"http://ggf.org/ns/nmwg/base/2.0/\" id=\"metadata-" . $id . "\">\n";
                $metadata .= "    <iperf:subject xmlns:iperf=\"http://ggf.org/ns/nmwg/tools/iperf/2.0/\" id=\"subject-" . $id . "\">\n";
                $metadata .= "      <nmwgt:endPointPair xmlns:nmwgt=\"http://ggf.org/ns/nmwg/topology/2.0/\">\n";
                if ( $meshes{ $result_node_mesh_map->[$x][0] }->{"addr_type"} eq "BWV6" ) {
                    $metadata .= "        <nmwgt:src type=\"ipv6\" value=\"" . $conf->{ "NODE-" . $nodes{ $result_node_mesh_map->[$x][1] }->{"node_name"} }->{"ADDRBWV6"} . "\" port=\"" . $nodes{ $result_node_mesh_map->[$x][1] }->{"uptime_port"} . "\" />\n";
                    $metadata .= "        <nmwgt:dst type=\"ipv6\" value=\"" . $conf->{ "NODE-" . $nodes{ $result_node_mesh_map->[$y][1] }->{"node_name"} }->{"ADDRBWV6"} . "\" port=\"" . $nodes{ $result_node_mesh_map->[$y][1] }->{"uptime_port"} . "\" />\n";
                }
                else {
                    $metadata .= "        <nmwgt:src type=\"ipv4\" value=\"" . $conf->{ "NODE-" . $nodes{ $result_node_mesh_map->[$x][1] }->{"node_name"} }->{"ADDRBWV4"} . "\" port=\"" . $nodes{ $result_node_mesh_map->[$x][1] }->{"uptime_port"} . "\" />\n";
                    $metadata .= "        <nmwgt:dst type=\"ipv4\" value=\"" . $conf->{ "NODE-" . $nodes{ $result_node_mesh_map->[$y][1] }->{"node_name"} }->{"ADDRBWV4"} . "\" port=\"" . $nodes{ $result_node_mesh_map->[$y][1] }->{"uptime_port"} . "\" />\n";
                }
                $metadata .= "      </nmwgt:endPointPair>\n";
                $metadata .= "    </iperf:subject>\n";
                $metadata .= "    <nmwg:eventType>http://ggf.org/ns/nmwg/tools/iperf/2.0</nmwg:eventType>\n";
                $metadata .= "    <nmwg:eventType>http://ggf.org/ns/nmwg/characteristics/bandwidth/acheiveable/2.0</nmwg:eventType>\n";
                $metadata .= "    <nmwg:parameters id=\"parameters-" . $id . "\">\n";

                if ( $conf->{ "MESH-" . $meshes{ $result_node_mesh_map->[$x][0] }->{"mesh_name"} }->{"BWWINDOWSIZE"} ) {
                    $metadata .= "      <nmwg:parameter name=\"windowSize\">" . $conf->{ "MESH-" . $meshes{ $result_node_mesh_map->[$x][0] }->{"mesh_name"} }->{"BWWINDOWSIZE"} . "</nmwg:parameter>\n";
                }
                elsif ( $conf->{"BWWINDOWSIZE"} ) {
                    $metadata .= "      <nmwg:parameter name=\"windowSize\">" . $conf->{"BWWINDOWSIZE"} . "</nmwg:parameter>\n";
                }

                if ( $conf->{ "MESH-" . $meshes{ $result_node_mesh_map->[$x][0] }->{"mesh_name"} }->{"BWBUFFERLEN"} ) {
                    $metadata .= "      <nmwg:parameter name=\"bufferLength\">" . $conf->{ "MESH-" . $meshes{ $result_node_mesh_map->[$x][0] }->{"mesh_name"} }->{"BWBUFFERLEN"} . "</nmwg:parameter>\n";
                }
                elsif ( $conf->{"BWBUFFERLEN"} ) {
                    $metadata .= "      <nmwg:parameter name=\"bufferLength\">" . $conf->{"BWBUFFERLEN"} . "</nmwg:parameter>\n";
                }

                if ( $conf->{ "MESH-" . $meshes{ $result_node_mesh_map->[$x][0] }->{"mesh_name"} }->{"BWTESTDURATION"} ) {
                    $metadata .= "      <nmwg:parameter name=\"timeDuration\">" . $conf->{ "MESH-" . $meshes{ $result_node_mesh_map->[$x][0] }->{"mesh_name"} }->{"BWTESTDURATION"} . "</nmwg:parameter>\n";
                }
                elsif ( $conf->{"BWTESTDURATION"} ) {
                    $metadata .= "      <nmwg:parameter name=\"timeDuration\">" . $conf->{"BWTESTDURATION"} . "</nmwg:parameter>\n";
                }

                if ( $conf->{ "MESH-" . $meshes{ $result_node_mesh_map->[$x][0] }->{"mesh_name"} }->{"BWREPORTINTERVAL"} ) {
                    $metadata .= "      <nmwg:parameter name=\"interval\">" . $conf->{ "MESH-" . $meshes{ $result_node_mesh_map->[$x][0] }->{"mesh_name"} }->{"BWREPORTINTERVAL"} . "</nmwg:parameter>\n";
                }
                elsif ( $conf->{"BWREPORTINTERVAL"} ) {
                    $metadata .= "      <nmwg:parameter name=\"interval\">" . $conf->{"BWREPORTINTERVAL"} . "</nmwg:parameter>\n";
                }

                if ( $conf->{ "MESH-" . $meshes{ $result_node_mesh_map->[$x][0] }->{"mesh_name"} }->{"BWUDP"} ) {
                    $metadata .= "      <nmwg:parameter name=\"protocol\">UDP</nmwg:parameter>\n";
                    $metadata .= "      <nmwg:parameter name=\"bandwidthLimit\">" . $conf->{ "MESH-" . $meshes{ $result_node_mesh_map->[$x][0] }->{"mesh_name"} }->{"BWUDPBANDWIDTHLIMIT"} . "</nmwg:parameter>\n"
                        if ( $conf->{ "MESH-" . $meshes{ $result_node_mesh_map->[$x][0] }->{"mesh_name"} }->{"BWUDPBANDWIDTHLIMIT"} );
                }
                elsif ( $conf->{ "MESH-" . $meshes{ $result_node_mesh_map->[$x][0] }->{"mesh_name"} }->{"BWTCP"} ) {
                    $metadata .= "      <nmwg:parameter name=\"protocol\">TCP</nmwg:parameter>\n";
                }

                $metadata .= "    </nmwg:parameters>\n";
                $metadata .= "  </nmwg:metadata>";

                my $data = q{};
                $data = "<nmwg:data xmlns:nmwg=\"http://ggf.org/ns/nmwg/base/2.0/\" id=\"data-" . $id . "\" metadataIdRef=\"metadata-" . $id . "\">\n";
                $data .= "    <nmwg:key id=\"key-" . $id . "\">\n";
                $data .= "      <nmwg:parameters id=\"parameters-key-" . $id . "\">\n";
                $data .= "        <nmwg:parameter name=\"eventType\">http://ggf.org/ns/nmwg/tools/iperf/2.0</nmwg:parameter>\n";
                $data .= "        <nmwg:parameter name=\"eventType\">http://ggf.org/ns/nmwg/characteristics/bandwidth/acheiveable/2.0</nmwg:parameter>\n";
                $data .= "        <nmwg:parameter name=\"type\">mysql</nmwg:parameter>\n";
                $data .= "        <nmwg:parameter name=\"db\">" . $dbsource . "</nmwg:parameter>\n";
                $data .= "        <nmwg:parameter name=\"user\">" . $conf->{'BWCENTRALDBUSER'} . "</nmwg:parameter>\n" if $conf->{'BWCENTRALDBUSER'};
                $data .= "        <nmwg:parameter name=\"pass\">" . $conf->{'BWCENTRALDBPASS'} . "</nmwg:parameter>\n" if $conf->{'BWCENTRALDBPASS'};
                $data .= "        <nmwg:parameter name=\"table\">" . "BW_" . $meshes{ $result_node_mesh_map->[$x][0] }->{"mesh_name"} . "_" . $nodes{ $result_node_mesh_map->[$x][1] }->{"node_name"} . "_" . $nodes{ $result_node_mesh_map->[$y][1] }->{"node_name"} . "</nmwg:parameter>\n";
                $data .= "      </nmwg:parameters>\n";
                $data .= "    </nmwg:key>\n";
                $data .= "  </nmwg:data>";

                if ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "xmldb" ) {
                    my $dHash  = md5_hex($data);
                    my $mdHash = md5_hex($metadata);
                    $parameters->{metadatadb}->insertIntoContainer( { content => $parameters->{metadatadb}->wrapStore( { content => $metadata, type => "MAStore" } ), name => $mdHash, txn => $dbTr, error => \$error } );
                    $errorFlag++ if $error;
                    $parameters->{metadatadb}->insertIntoContainer( { content => $parameters->{metadatadb}->wrapStore( { content => $data, type => "MAStore" } ), name => $dHash, txn => $dbTr, error => \$error } );
                    $errorFlag++ if $error;

                    $self->{CONF}->{"perfsonarbuoy"}->{"hashToId"}->{$dHash} = "data-" . $id;
                    $self->{CONF}->{"perfsonarbuoy"}->{"idToHash"}->{ "data-" . $id } = $dHash;
                    $self->{LOGGER}->debug( "Key id $dHash maps to data element data-" . $id );
                }
                elsif ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "file" ) {
                    my $fh = new IO::File ">> " . $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_file"};
                    if ( defined $fh ) {
                        print $fh $metadata . "\n" . $data . "\n";
                        $fh->close;
                    }
                    else {
                        $self->{LOGGER}->error("File cannot be written.");
                        return -1;
                    }

                    my $dHash = md5_hex($data);
                    $self->{CONF}->{"perfsonarbuoy"}->{"hashToId"}->{$dHash} = "data-" . $id;
                    $self->{CONF}->{"perfsonarbuoy"}->{"idToHash"}->{ "data-" . $id } = $dHash;
                    $self->{LOGGER}->debug( "Key id $dHash maps to data element data-" . $id );
                }
                $id++;
            }
        }
    }

    if ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "xmldb" ) {
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
    elsif ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "file" ) {
        my $fh = new IO::File ">> " . $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_file"};
        if ( defined $fh ) {
            print $fh "</nmwg:store>\n";
            $fh->close;
        }
        else {
            $self->{LOGGER}->error("File cannot be written.");
            return -1;
        }
    }
    else {
        $self->{LOGGER}->error("Wrong value for 'metadata_db_type' set.");
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
    my $metadatadb = new perfSONAR_PS::DB::XMLDB( { env => $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_name"}, cont => $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_file"}, ns => \%ma_namespaces, } );
    unless ( $metadatadb->openDB( { txn => q{}, error => \$error } ) == 0 ) {
        throw perfSONAR_PS::Error_compat( "error.ls.xmldb", "There was an error opening \"" . $self->{CONF}->{"ls"}->{"metadata_db_name"} . "/" . $self->{CONF}->{"ls"}->{"metadata_db_file"} . "\": " . $error );
        return;
    }
    return $metadatadb;
}

=head2 needLS($self {})

This particular service (perfSONARBUOY MA) should register with a lookup
service.  This function simply returns the value set in the configuration file
(either yes or no, depending on user preference) to let other parts of the
framework know if LS registration is required.

=cut

sub needLS {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, {} );

    return ( $self->{CONF}->{"perfsonarbuoy"}->{"enable_registration"} );
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
            SERVICE_TYPE        => $self->{CONF}->{"perfsonarbuoy"}->{"service_type"},
            SERVICE_NAME        => $self->{CONF}->{"perfsonarbuoy"}->{"service_name"},
            SERVICE_DESCRIPTION => $self->{CONF}->{"perfsonarbuoy"}->{"service_description"},
            SERVICE_ACCESSPOINT => $self->{CONF}->{"perfsonarbuoy"}->{"service_accesspoint"},
        );
        $self->{LS_CLIENT} = new perfSONAR_PS::Client::LS::Remote( $self->{CONF}->{"perfsonarbuoy"}->{"ls_instance"}, \%ls_conf, $self->{NAMESPACES} );
    }

    $ls = $self->{LS_CLIENT};

    my $error         = q{};
    my @resultsString = ();
    if ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "file" ) {
        @resultsString = $self->{METADATADB}->query( { query => "/nmwg:store/nmwg:metadata", error => \$error } );
    }
    elsif ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "xmldb" ) {
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
    my $new_timeSettings = getFilterParameters( { m => $md, namespaces => $parameters->{rawRequest}->getNamespaces(), default_resolution => $self->{CONF}->{"perfsonarbuoy"}->{"default_resolution"} } );

    $timeSettings{"CF"}                   = $new_timeSettings->{"CF"}                   if ( defined $new_timeSettings->{"CF"} );
    $timeSettings{"RESOLUTION"}           = $new_timeSettings->{"RESOLUTION"}           if ( defined $new_timeSettings->{"RESOLUTION"} and $timeSettings{"RESOLUTION_SPECIFIED"} );
    $timeSettings{"RESOLUTION_SPECIFIED"} = $new_timeSettings->{"RESOLUTION_SPECIFIED"} if ( $new_timeSettings->{"RESOLUTION_SPECIFIED"} );

    if ( exists $new_timeSettings->{"START"}->{"value"} ) {
        if ( exists $new_timeSettings->{"START"}->{"type"} and lc( $new_timeSettings->{"START"}->{"type"} ) eq "unix" ) {
            $new_timeSettings->{"START"}->{"internal"} = time2owptime( $new_timeSettings->{"START"}->{"value"} )->bstr();
        }
        elsif ( exists $new_timeSettings->{"START"}->{"type"} and lc( $new_timeSettings->{"START"}->{"type"} ) eq "iso" ) {
            $new_timeSettings->{"START"}->{"internal"} = time2owptime( UnixDate( $new_timeSettings->{"START"}->{"value"}, "%s" ) )->bstr();
        }
        else {
            $new_timeSettings->{"START"}->{"internal"} = time2owptime( $new_timeSettings->{"START"}->{"value"} )->bstr();
        }
    }
    $timeSettings{"START"} = $new_timeSettings->{"START"};

    if ( exists $new_timeSettings->{"END"}->{"value"} ) {
        if ( exists $new_timeSettings->{"END"}->{"type"} and lc( $new_timeSettings->{"END"}->{"type"} ) eq "unix" ) {
            $new_timeSettings->{"END"}->{"internal"} = time2owptime( $new_timeSettings->{"END"}->{"value"} )->bstr();
        }
        elsif ( exists $new_timeSettings->{"START"}->{"type"} and lc( $new_timeSettings->{"END"}->{"type"} ) eq "iso" ) {
            $new_timeSettings->{"END"}->{"internal"} = time2owptime( UnixDate( $new_timeSettings->{"END"}->{"value"}, "%s" ) )->bstr();
        }
        else {
            $new_timeSettings->{"END"}->{"internal"} = time2owptime( $new_timeSettings->{"END"}->{"value"} )->bstr();
        }
    }
    $timeSettings{"END"} = $new_timeSettings->{"END"};

    if ( $#filters > -1 ) {
        foreach my $filter_arr (@filters) {
            my @filters = @{$filter_arr};
            my $filter  = $filters[-1];

            $new_timeSettings = getFilterParameters( { m => $filter, namespaces => $parameters->{rawRequest}->getNamespaces(), default_resolution => $self->{CONF}->{"perfsonarbuoy"}->{"default_resolution"} } );

            $timeSettings{"CF"}                   = $new_timeSettings->{"CF"}                   if ( defined $new_timeSettings->{"CF"} );
            $timeSettings{"RESOLUTION"}           = $new_timeSettings->{"RESOLUTION"}           if ( defined $new_timeSettings->{"RESOLUTION"} and $new_timeSettings->{"RESOLUTION_SPECIFIED"} );
            $timeSettings{"RESOLUTION_SPECIFIED"} = $new_timeSettings->{"RESOLUTION_SPECIFIED"} if ( $new_timeSettings->{"RESOLUTION_SPECIFIED"} );

            if ( exists $new_timeSettings->{"START"}->{"value"} ) {
                if ( exists $new_timeSettings->{"START"}->{"type"} and lc( $new_timeSettings->{"START"}->{"type"} ) eq "unix" ) {
                    $new_timeSettings->{"START"}->{"internal"} = time2owptime( $new_timeSettings->{"START"}->{"value"} )->bstr();
                }
                elsif ( exists $new_timeSettings->{"START"}->{"type"} and lc( $new_timeSettings->{"START"}->{"type"} ) eq "iso" ) {
                    $new_timeSettings->{"START"}->{"internal"} = time2owptime( UnixDate( $new_timeSettings->{"START"}->{"value"}, "%s" ) )->bstr();
                }
                else {
                    $new_timeSettings->{"START"}->{"internal"} = time2owptime( $new_timeSettings->{"START"}->{"value"} )->bstr();
                }
            }
            else {
                $new_timeSettings->{"START"}->{"internal"} = q{};
            }

            if ( exists $new_timeSettings->{"END"}->{"value"} ) {
                if ( exists $new_timeSettings->{"END"}->{"type"} and lc( $new_timeSettings->{"END"}->{"type"} ) eq "unix" ) {
                    $new_timeSettings->{"END"}->{"internal"} = time2owptime( $new_timeSettings->{"END"}->{"value"} )->bstr();
                }
                elsif ( exists $new_timeSettings->{"END"}->{"type"} and lc( $new_timeSettings->{"END"}->{"type"} ) eq "iso" ) {
                    $new_timeSettings->{"END"}->{"internal"} = time2owptime( UnixDate( $new_timeSettings->{"END"}->{"value"}, "%s" ) )->bstr();
                }
                else {
                    $new_timeSettings->{"END"}->{"internal"} = time2owptime( $new_timeSettings->{"END"}->{"value"} )->bstr();
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
        $timeSettings{"RESOLUTION"}           = $self->{CONF}->{"perfsonarbuoy"}->{"default_resolution"};
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
    if ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "xmldb" ) {
        $self->{METADATADB} = $self->prepareDatabases( { doc => $parameters->{output} } );
        unless ( $self->{METADATADB} ) {
            throw perfSONAR_PS::Error_compat("Database could not be opened.");
            return;
        }
    }
    unless ( ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "file" )
        or ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "xmldb" ) )
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
        my $msg = "Key error in metadata storage: cannot find 'maKey' in request message.";
        $self->{LOGGER}->error($msg);
        throw perfSONAR_PS::Error_compat( "error.ma.storage_result", $msg );
        return;
    }

    my $hashId = $self->{CONF}->{"perfsonarbuoy"}->{"hashToId"}->{$hashKey};
    unless ($hashId) {
        my $msg = "Key error in metadata storage: 'maKey' cannot be found.";
        $self->{LOGGER}->error($msg);
        throw perfSONAR_PS::Error_compat( "error.ma.storage_result", $msg );
        return;
    }

    my $query = q{};
    if ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "file" ) {
        $query = "/nmwg:store/nmwg:data[\@id=\"" . $hashId . "\"]";
    }
    elsif ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "xmldb" ) {
        $query = "/nmwg:store[\@type=\"MAStore\"]/nmwg:data[\@id=\"" . $hashId . "\"]";
    }

    if ( $parameters->{metadatadb}->count( { query => $query } ) != 1 ) {
        my $msg = "Key error in metadata storage: 'maKey' should exist, but matching data not found in database.";
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
    if ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "file" ) {
        $queryString = "/nmwg:store/nmwg:metadata[" . getMetadataXQuery( { node => $parameters->{metadata} } ) . "]";
    }
    elsif ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "xmldb" ) {
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

    if ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "file" ) {
        $queryString = "/nmwg:store/nmwg:data";
    }
    elsif ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "xmldb" ) {
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
            my $hashKey = $self->{CONF}->{"perfsonarbuoy"}->{"idToHash"}->{$hashId};
            unless ($hashKey) {
                my $msg = "Key error in metadata storage: 'maKey' cannot be found.";
                $self->{LOGGER}->error($msg);
                throw perfSONAR_PS::Error_compat( "error.ma.storage", $msg );
            }

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
        my $msg = "Database \"" . $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_file"} . "\" returned 0 results for search";
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
with the database of choice (i.e. mysql, sqlite, others?).  

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
    if ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "xmldb" ) {
        $self->{METADATADB} = $self->prepareDatabases( { doc => $parameters->{output} } );
        unless ( $self->{METADATADB} ) {
            throw perfSONAR_PS::Error_compat("Database could not be opened.");
            return;
        }
    }
    unless ( ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "file" )
        or ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "xmldb" ) )
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
        my $msg = "Key error in metadata storage: cannot find 'maKey' in request message.";
        $self->{LOGGER}->error($msg);
        throw perfSONAR_PS::Error_compat( "error.ma.storage_result", $msg );
        return;
    }

    my $hashId = $self->{CONF}->{"perfsonarbuoy"}->{"hashToId"}->{$hashKey};
    $self->{LOGGER}->debug("Received hash key $hashKey which maps to $hashId");
    unless ($hashId) {
        my $msg = "Key error in metadata storage: 'maKey' cannot be found.";
        $self->{LOGGER}->error($msg);
        throw perfSONAR_PS::Error_compat( "error.ma.storage_result", $msg );
        return;
    }

    my $query = q{};
    if ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "file" ) {
        $query = "/nmwg:store/nmwg:data[\@id=\"" . $hashId . "\"]";
    }
    elsif ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "xmldb" ) {
        $query = "/nmwg:store[\@type=\"MAStore\"]/nmwg:data[\@id=\"" . $hashId . "\"]";
    }

    $results = $parameters->{metadatadb}->querySet( { query => $query } );
    if ( $results->size() != 1 ) {
        my $msg = "Key error in metadata storage: 'maKey' should exist, but matching data not found in database.";
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
    if ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "file" ) {
        $queryString = "/nmwg:store/nmwg:metadata[" . getMetadataXQuery( { node => $parameters->{metadata} } ) . "]";
    }
    elsif ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "xmldb" ) {
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

    if ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "file" ) {
        $queryString = "/nmwg:store/nmwg:data";
    }
    elsif ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "xmldb" ) {
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
        my $msg = "Database \"" . $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_file"} . "\" returned 0 results for search";
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
    if ( lc($type) eq "mysql" or lc($type) eq "sql" ) {
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

    my $timeType = "iso";
    if ( defined $parameters->{message_parameters}->{"timeType"} ) {
        if ( lc( $parameters->{message_parameters}->{"timeType"} ) eq "unix" ) {
            $timeType = "unix";
        }
        elsif ( lc( $parameters->{message_parameters}->{"timeType"} ) eq "iso" ) {
            $timeType = "iso";
        }
    }

    unless ( $parameters->{d} ) {
        $self->{LOGGER}->error("No data element.");
        throw perfSONAR_PS::Error_compat( "error.ma.storage", "No data element found." );
    }

    my $dbconnect = extract( find( $parameters->{d}, "./nmwg:key//nmwg:parameter[\@name=\"db\"]",    1 ), 1 );
    my $dbtable   = extract( find( $parameters->{d}, "./nmwg:key//nmwg:parameter[\@name=\"table\"]", 1 ), 1 );
    my $dbuser    = extract( find( $parameters->{d}, "./nmwg:key//nmwg:parameter[\@name=\"user\"]",  1 ), 1 );
    my $dbpass    = extract( find( $parameters->{d}, "./nmwg:key//nmwg:parameter[\@name=\"pass\"]",  1 ), 1 );

    unless ( $dbconnect and $dbtable ) {
        $self->{LOGGER}->error( "Data element " . $parameters->{d}->getAttribute("id") . " is missing some SQL elements" );
        throw perfSONAR_PS::Error_compat( "error.ma.storage", "Unable to open associated database" );
    }

    my $query = {};
    if ( $parameters->{time_settings}->{"START"}->{"internal"} or $parameters->{time_settings}->{"END"}->{"internal"} ) {
        $query = "select * from " . $dbtable . " where";
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
        $query = "select * from " . $dbtable . ";";
    }

    my @dbSchema = ( "ti", "time", "throughput", "jitter", "lost", "sent" );

    my $datadb = new perfSONAR_PS::DB::SQL( { name => $dbconnect, schema => \@dbSchema, user => $dbuser, pass => $dbpass } );

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
        my $prefix = "iperf";
        my $uri    = "http://ggf.org/ns/nmwg/tools/iperf/2.0/";

        startData( $parameters->{output}, $id, $parameters->{mid}, undef );
        my $len = $#{$result};
        for my $a ( 0 .. $len ) {
            my %attrs = ();
            if ( $timeType eq "unix" ) {
                $attrs{"timeType"} = "unix";
                $attrs{ $dbSchema[1] . "Value" } = owptime2exacttime( $result->[$a][1] );
            }
            else {
                $attrs{"timeType"} = "iso";
                $attrs{ $dbSchema[1] . "Value" } = owpexactgmstring( $result->[$a][1] );
            }

            $attrs{ $dbSchema[2] } = $result->[$a][2] if $result->[$a][2];
            $attrs{ $dbSchema[3] } = $result->[$a][3] if $result->[$a][3];
            $attrs{ $dbSchema[4] } = $result->[$a][4] if $result->[$a][4];
            $attrs{ $dbSchema[5] } = $result->[$a][5] if $result->[$a][5];

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
L<Params::Validate>, L<Sys::Hostname>, L<Fcntl>, L<Date::Manip>,
L<Math::BigInt>, L<perfSONAR_PS::OWP>, L<perfSONAR_PS::OWP::Utils>,
L<perfSONAR_PS::Services::MA::General>, L<perfSONAR_PS::Common>,
L<perfSONAR_PS::Messages>, L<perfSONAR_PS::Client::LS::Remote>,
L<perfSONAR_PS::Error_compat>, L<perfSONAR_PS::DB::File>,
L<perfSONAR_PS::DB::SQL>

To join the 'perfSONAR-PS' mailing list, please visit:

  https://mail.internet2.edu/wws/info/i2-perfsonar

The perfSONAR-PS subversion repository is located at:

  https://svn.internet2.edu/svn/perfSONAR-PS

Questions and comments can be directed to the author, or the mailing list.
Bugs, feature requests, and improvements can be directed here:

  https://bugs.internet2.edu/jira/browse/PSPS

=head1 VERSION

$Id: perfSONARBUOY.pm 1856 2008-03-18 17:03:46Z zurawski $

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
