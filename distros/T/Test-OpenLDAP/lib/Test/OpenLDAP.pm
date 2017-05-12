package Test::OpenLDAP;

use strict;
use warnings;
use Config;
use POSIX();
use Data::UUID();
use FileHandle();
use DirHandle();
use File::Temp();
use URI::Escape();
use Net::LDAP();
use English qw( -no_match_vars );

=head1 NAME

Test::OpenLDAP - Creates a temporary instance of OpenLDAP's slapd daemon to run tests against.

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.05';

our @CARP_NOT = ('Test::OpenLDAP');
sub USER_READ_WRITE_PERMISSIONS         { return 600; }
sub USER_READ_WRITE_EXECUTE_PERMISSIONS { return 700; }
sub OPENLDAP_SLAPD_BINARY_NAME          { return 'slapd'; }
sub UID_INDEX                           { return 2; }
sub GID_INDEX                           { return 3; }
sub SPACE                               { return q[ ]; }
sub SECONDS_TO_WAIT_FOR_SLAPD_TO_START  { return 60; }
sub COMMA                               { return q[,]; }
sub LENGTH_OF_RANDOM_ADMIN_PASSWORD     { return 20; }
sub MAX_VALUE_OF_BYTE                   { return 255; }

=head1 SYNOPSIS

This module allows easy creation and tear down of a OpenLDAP slapd instance.  When the variable goes 
out of scope, the slapd instance is torn down and the file system objects it relies on are removed.

  my $slapd = Test::OpenLDAP->new(); # Test::OpenLDAP->new({ suffix => 'dc=foobar,dc=com' });

  my $ldap = Net::LDAP->new($slapd->uri()) or Carp::croak("Failed to connect:$@");

  my $mesg = $ldap->bind($slapd->admin_user(), password => $slapd->admin_password());

  ... add / modify / search entries

  $slapd->stop();

  $slapd->start();

  $slapd->DESTROY();


=head1 SUBROUTINES/METHODS

=head2 new

This method initialises and starts an OpenLDAP slapd instance, listening on a unix socket.  It then creates an admin user and password and returns the slapd instance to the user.
The method accepts a hash parameter of configuration options.  The only option it accepts at the moment is the 'suffix' option.

=cut

sub new {
    my ( $class, $params ) = @_;
    my $self = {};
    bless $self, $class;
    $self->{suffix} = $params->{suffix} || 'dc=example,dc=com';
    $self->{admin_user} = 'cn=root,' . $self->{suffix};
    my $string = q[];
    foreach ( 0 .. LENGTH_OF_RANDOM_ADMIN_PASSWORD() ) {
        $string .= chr int rand MAX_VALUE_OF_BYTE();
    }
    $self->{admin_password} = unpack 'H*', $string;
    $self->{root_directory} = File::Temp::mktemp(
        File::Spec->catfile(
            File::Spec->tmpdir(), 'perl_test_openldap_XXXXXXXXXXX'
        )
    );
    $self->{slapd_socket_path} =
      File::Spec->catfile( $self->{root_directory}, 'slapd.sock' );
    $self->{encoded_socket_path} =
      URI::Escape::uri_escape_utf8( $self->{slapd_socket_path} );
    $self->{slapd_pid_path} =
      File::Spec->catfile( $self->{root_directory}, 'slapd.pid' );
    $self->{slapd_d_directory} =
      File::Spec->catdir( $self->{root_directory}, 'slapd.d' );
    $self->{config_ldif_path} =
      File::Spec->catfile( $self->{slapd_d_directory}, 'cn=config.ldif' );
    $self->{cn_config_directory} =
      File::Spec->catdir( $self->{slapd_d_directory}, 'cn=config' );
    $self->{cn_schema_directory} =
      File::Spec->catdir( $self->{cn_config_directory}, 'cn=schema' );
    $self->{cn_schema_ldif_path} =
      File::Spec->catfile( $self->{cn_config_directory}, 'cn=schema.ldif' );
    $self->{cn_schema_core_ldif_path} =
      File::Spec->catfile( $self->{cn_schema_directory}, 'cn={1}core.ldif' );
    $self->{olc_database_config_path} =
      File::Spec->catfile( $self->{cn_config_directory},
        'olcDatabase={0}config.ldif' );
    $self->{olc_database_frontend_path} =
      File::Spec->catfile( $self->{cn_config_directory},
        'olcDatabase={-1}frontend.ldif' );
    $self->{olc_database_hdb_path} =
      File::Spec->catfile( $self->{cn_config_directory},
        'olcDatabase={1}hdb.ldif' );
    $self->{db_directory} = File::Spec->catdir( $self->{root_directory}, 'db' );

    mkdir $self->{root_directory}, oct USER_READ_WRITE_EXECUTE_PERMISSIONS()
      or Carp::croak("Failed to mkdir $self->{root_directory}:$OS_ERROR");
    mkdir $self->{slapd_d_directory}, oct USER_READ_WRITE_EXECUTE_PERMISSIONS()
      or Carp::croak("Failed to mkdir $self->{slapd_d_directory}:$OS_ERROR");
    mkdir $self->{cn_config_directory},
      oct USER_READ_WRITE_EXECUTE_PERMISSIONS()
      or Carp::croak("Failed to mkdir $self->{cn_config_directory}:$OS_ERROR");
    mkdir $self->{cn_schema_directory},
      oct USER_READ_WRITE_EXECUTE_PERMISSIONS()
      or Carp::croak("Failed to mkdir $self->{cn_schema_directory}:$OS_ERROR");
    mkdir $self->{db_directory}, oct USER_READ_WRITE_EXECUTE_PERMISSIONS()
      or Carp::croak("Failed to mkdir $self->{db_directory}:$OS_ERROR");
    $self->_create_config_ldif();
    $self->_create_schema_ldif();
    $self->_create_schema_core_ldif();
    $self->{olc_database_for_config} = '{0}config';
    $self->{config_database_rdn} =
      "olcDatabase=$self->{olc_database_for_config}";
    $self->_create_olc_database_config();
    $self->{olc_database_for_hdb} = '{1}hdb';
    $self->{database_hdb_rdn}     = "olcDatabase=$self->{olc_database_for_hdb}";
    $self->_create_olc_database_hdb();
    $self->{uri} = "ldapi://$self->{encoded_socket_path}/$self->{suffix}";
    $self->start();
    return $self;
}

=head2 skip

This method allows the user to skip tests requiring Test::OpenLDAP by checking to see if the slapd binary exists AND that the OS uses fork for process control.

=cut

sub skip {
    my ($class) = @_;
    if (   ( exists $Config{d_fork} )
        && ( defined $Config{d_fork} )
        && ( $Config{d_fork} eq 'define' ) )
    {
        my $path_sep          = $Config{path_sep};
        my @slapd_directories = split /$path_sep/smx,
          "$ENV{PATH}$path_sep/usr/lib/openldap";
        my $slapd_path;
        foreach my $directory (@slapd_directories) {
            my $possible =
              File::Spec->catfile( $directory, OPENLDAP_SLAPD_BINARY_NAME() );
            if ( -x $possible ) {
                $slapd_path = $possible;
            }
        }
        if ( !defined $slapd_path ) {
            return 'No slapd binary found in '
              . ( join COMMA(), @slapd_directories );
        }
    }
    else {
        return "'$OSNAME' does not use the fork call for process control";
    }
    return;
}

=head2 start

This methods starts the slapd process 

=cut

sub start {
    my ($self) = @_;
    if ( $self->{slapd_pid} ) {
        Carp::croak('slapd already started');
    }
    if ( $self->{slapd_pid} = fork ) {
        my $ldap;
        my $timeout = time + SECONDS_TO_WAIT_FOR_SLAPD_TO_START();
        while (( kill 0, $self->{slapd_pid} )
            && ( !$ldap )
            && ( time < $timeout ) )
        {
            $ldap = Net::LDAP->new( $self->uri() );
            if ( !$ldap ) {
                sleep 1;
            }
        }
        if ( !$ldap ) {
            Carp::croak('Failed to start slapd');
        }
    }
    else {
        eval {
            local $ENV{PATH} = "$ENV{PATH}$Config{path_sep}/usr/lib/openldap"
              ;    # adding /usr/lib/openldap for OpenSUSE deployments

            exec { OPENLDAP_SLAPD_BINARY_NAME() } OPENLDAP_SLAPD_BINARY_NAME(),
              '-d', '0', '-h', "ldapi://$self->{encoded_socket_path}", '-F',
              $self->_slapd_d_directory()
              or Carp::croak( q[Failed to exec ']
                  . OPENLDAP_SLAPD_BINARY_NAME()
                  . "':$OS_ERROR" );
        } or do {
            Carp::carp($EVAL_ERROR);
        };
        exit 1;
    }
    return $self;
}

sub _uuid {
    my ($self) = @_;
    my $ug = Data::UUID->new();
    return $ug->to_string( $ug->create() );
}

sub _term_signal {
    my @sig_nums  = split SPACE(), $Config{sig_num};
    my @sig_names = split SPACE(), $Config{sig_name};
    my %signals_by_name;
    my $sig_idx = 0;
    foreach my $sig_name (@sig_names) {
        $signals_by_name{$sig_name} = $sig_nums[$sig_idx];
        $sig_idx += 1;
    }
    return $signals_by_name{TERM};
}

=head2 start

This method stops the slapd process 

=cut

sub stop {
    my ($self) = @_;
    if ( defined $self->{slapd_pid} ) {
        if ( waitpid $self->{slapd_pid}, POSIX::WNOHANG() ) {
            delete $self->{slapd_pid};
            unlink $self->{slapd_socket_path}
              or ( $OS_ERROR == POSIX::ENOENT() )
              or Carp::croak(
                "Failed to unlink '$self->{slapd_socket_path}':$OS_ERROR");
            return;
        }
        else {
            kill _term_signal(), $self->{slapd_pid};
            waitpid $self->{slapd_pid}, 0;
            unlink $self->{slapd_socket_path}
              or ( $OS_ERROR == POSIX::ENOENT() )
              or Carp::croak(
                "Failed to unlink '$self->{slapd_socket_path}':$OS_ERROR");
            delete $self->{slapd_pid};
            return 1;
        }
    }
}

=head2 uri

This method gives the uri for the test code to connect to via a Net::LDAP->new() call.

=cut

sub uri {
    my ($self) = @_;
    return $self->{uri};
}

=head2 suffix

This method gives the dn used as the suffix for the slapd database.

=cut

sub suffix {
    my ($self) = @_;
    return $self->{suffix};
}

=head2 admin_user

This method gives the admin user name for the slapd database.

=cut

sub admin_user {
    my ($self) = @_;
    return $self->{admin_user};
}

=head2 admin_password

This method gives the admin password for the slapd database.

=cut

sub admin_password {
    my ($self) = @_;
    return $self->{admin_password};
}

sub _slapd_d_directory {
    my ($self) = @_;
    return $self->{slapd_d_directory};
}

sub _entry_csn {
    return POSIX::strftime( '%Y%m%d%H%M%S.000000Z#000000#000#000000',
        localtime time );
}

sub _create_config_ldif {
    my ($self)      = @_;
    my $write_flags = Fcntl::O_WRONLY() | Fcntl::O_CREAT() | Fcntl::O_EXCL();
    my $uuid        = lc $self->_uuid();
    my $entry_csn   = $self->_entry_csn();
    my $create_timestamp = POSIX::strftime( '%Y%m%d%H%M%SZ', gmtime time );
    my $handle = FileHandle->new( $self->{config_ldif_path},
        $write_flags, oct USER_READ_WRITE_PERMISSIONS() )
      or Carp::croak(
        "Failed to open '$self->{config_ldif_path}' for writing:$OS_ERROR");
    $handle->print(
        <<"__CONFIG_LDIF__") or Carp::croak("Failed to write to '$self->{config_ldif_path}':$OS_ERROR");
dn: cn=config
objectClass: olcGlobal
cn: config
olcConfigDir: $self->{slapd_d_directory}
olcAllows: bind_v2
olcAttributeOptions: lang-
olcAuthzPolicy: none
olcConcurrency: 0
olcConnMaxPending: 100
olcConnMaxPendingAuth: 1000
olcGentleHUP: FALSE
olcIdleTimeout: 0
olcIndexSubstrIfMaxLen: 4
olcIndexSubstrIfMinLen: 2
olcIndexSubstrAnyLen: 4
olcIndexSubstrAnyStep: 2
olcIndexIntLen: 4
olcLocalSSF: 71
olcPidFile: $self->{slapd_pid_path}
olcReadOnly: FALSE
olcReverseLookup: FALSE
olcSaslSecProps: noplain,noanonymous
olcSockbufMaxIncoming: 262143
olcSockbufMaxIncomingAuth: 16777215
olcThreads: 16
olcTLSVerifyClient: never
olcToolThreads: 1
olcWriteTimeout: 0
structuralObjectClass: olcGlobal
entryUUID: $uuid
creatorsName: cn=config
createTimestamp: $create_timestamp
entryCSN: $entry_csn
modifiersName: cn=config
modifyTimestamp: $create_timestamp
__CONFIG_LDIF__
    close $handle
      or Carp::croak("Failed to close '$self->{config_ldif_path}':$OS_ERROR");
    return;
}

sub _create_schema_ldif {
    my ($self)      = @_;
    my $write_flags = Fcntl::O_WRONLY() | Fcntl::O_CREAT() | Fcntl::O_EXCL();
    my $uuid        = lc $self->_uuid();
    my $entry_csn   = $self->_entry_csn();
    my $create_timestamp = POSIX::strftime( '%Y%m%d%H%M%SZ', gmtime time );
    my $handle = FileHandle->new( $self->{cn_schema_ldif_path},
        $write_flags, oct USER_READ_WRITE_PERMISSIONS() )
      or Carp::croak(
        "Failed to open '$self->{cn_schema_ldif_path}' for writing:$OS_ERROR");
    $handle->print(
        <<"__SCHEMA_LDIF__") or Carp::croak("Failed to write to '$self->{cn_schema_ldif_path}':$OS_ERROR");
dn: cn=schema
objectClass: olcSchemaConfig
cn: schema
olcObjectIdentifier: OLcfg 1.3.6.1.4.1.4203.1.12.2
olcObjectIdentifier: OLcfgAt OLcfg:3
olcObjectIdentifier: OLcfgGlAt OLcfgAt:0
olcObjectIdentifier: OLcfgBkAt OLcfgAt:1
olcObjectIdentifier: OLcfgDbAt OLcfgAt:2
olcObjectIdentifier: OLcfgOvAt OLcfgAt:3
olcObjectIdentifier: OLcfgCtAt OLcfgAt:4
olcObjectIdentifier: OLcfgOc OLcfg:4
olcObjectIdentifier: OLcfgGlOc OLcfgOc:0
olcObjectIdentifier: OLcfgBkOc OLcfgOc:1
olcObjectIdentifier: OLcfgDbOc OLcfgOc:2
olcObjectIdentifier: OLcfgOvOc OLcfgOc:3
olcObjectIdentifier: OLcfgCtOc OLcfgOc:4
olcObjectIdentifier: OMsyn 1.3.6.1.4.1.1466.115.121.1
olcObjectIdentifier: OMsBoolean OMsyn:7
olcObjectIdentifier: OMsDN OMsyn:12
olcObjectIdentifier: OMsDirectoryString OMsyn:15
olcObjectIdentifier: OMsIA5String OMsyn:26
olcObjectIdentifier: OMsInteger OMsyn:27
olcObjectIdentifier: OMsOID OMsyn:38
olcObjectIdentifier: OMsOctetString OMsyn:40
olcObjectIdentifier: olmAttributes 1.3.6.1.4.1.4203.666.1.55
olcObjectIdentifier: olmSubSystemAttributes olmAttributes:0
olcObjectIdentifier: olmGenericAttributes olmSubSystemAttributes:0
olcObjectIdentifier: olmDatabaseAttributes olmSubSystemAttributes:1
olcObjectIdentifier: olmObjectClasses 1.3.6.1.4.1.4203.666.3.16
olcObjectIdentifier: olmSubSystemObjectClasses olmObjectClasses:0
olcObjectIdentifier: olmGenericObjectClasses olmSubSystemObjectClasses:0
olcObjectIdentifier: olmDatabaseObjectClasses olmSubSystemObjectClasses:1
olcObjectIdentifier: olmBDBAttributes olmDatabaseAttributes:1
olcObjectIdentifier: olmBDBObjectClasses olmDatabaseObjectClasses:1
olcAttributeTypes: ( 2.5.4.0 NAME 'objectClass' DESC 'RFC4512: object classes 
 of the entity' EQUALITY objectIdentifierMatch SYNTAX 1.3.6.1.4.1.1466.115.121
 .1.38 )
olcAttributeTypes: ( 2.5.21.9 NAME 'structuralObjectClass' DESC 'RFC4512: stru
 ctural object class of entry' EQUALITY objectIdentifierMatch SYNTAX 1.3.6.1.4
 .1.1466.115.121.1.38 SINGLE-VALUE NO-USER-MODIFICATION USAGE directoryOperati
 on )
olcAttributeTypes: ( 2.5.18.1 NAME 'createTimestamp' DESC 'RFC4512: time which
  object was created' EQUALITY generalizedTimeMatch ORDERING generalizedTimeOr
 deringMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.24 SINGLE-VALUE NO-USER-MODIFIC
 ATION USAGE directoryOperation )
olcAttributeTypes: ( 2.5.18.2 NAME 'modifyTimestamp' DESC 'RFC4512: time which
  object was last modified' EQUALITY generalizedTimeMatch ORDERING generalized
 TimeOrderingMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.24 SINGLE-VALUE NO-USER-M
 ODIFICATION USAGE directoryOperation )
olcAttributeTypes: ( 2.5.18.3 NAME 'creatorsName' DESC 'RFC4512: name of creat
 or' EQUALITY distinguishedNameMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.12 SING
 LE-VALUE NO-USER-MODIFICATION USAGE directoryOperation )
olcAttributeTypes: ( 2.5.18.4 NAME 'modifiersName' DESC 'RFC4512: name of last
  modifier' EQUALITY distinguishedNameMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.
 12 SINGLE-VALUE NO-USER-MODIFICATION USAGE directoryOperation )
olcAttributeTypes: ( 2.5.18.9 NAME 'hasSubordinates' DESC 'X.501: entry has ch
 ildren' EQUALITY booleanMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.7 SINGLE-VALU
 E NO-USER-MODIFICATION USAGE directoryOperation )
olcAttributeTypes: ( 2.5.18.10 NAME 'subschemaSubentry' DESC 'RFC4512: name of
  controlling subschema entry' EQUALITY distinguishedNameMatch SYNTAX 1.3.6.1.
 4.1.1466.115.121.1.12 SINGLE-VALUE NO-USER-MODIFICATION USAGE directoryOperat
 ion )
olcAttributeTypes: ( 1.3.6.1.1.20 NAME 'entryDN' DESC 'DN of the entry' EQUALI
 TY distinguishedNameMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.12 SINGLE-VALUE N
 O-USER-MODIFICATION USAGE directoryOperation )
olcAttributeTypes: ( 1.3.6.1.1.16.4 NAME 'entryUUID' DESC 'UUID of the entry' 
 EQUALITY UUIDMatch ORDERING UUIDOrderingMatch SYNTAX 1.3.6.1.1.16.1 SINGLE-VA
 LUE NO-USER-MODIFICATION USAGE directoryOperation )
olcAttributeTypes: ( 1.3.6.1.4.1.4203.666.1.7 NAME 'entryCSN' DESC 'change seq
 uence number of the entry content' EQUALITY CSNMatch ORDERING CSNOrderingMatc
 h SYNTAX 1.3.6.1.4.1.4203.666.11.2.1{64} SINGLE-VALUE NO-USER-MODIFICATION US
 AGE directoryOperation )
olcAttributeTypes: ( 1.3.6.1.4.1.4203.666.1.13 NAME 'namingCSN' DESC 'change s
 equence number of the entry naming (RDN)' EQUALITY CSNMatch ORDERING CSNOrder
 ingMatch SYNTAX 1.3.6.1.4.1.4203.666.11.2.1{64} SINGLE-VALUE NO-USER-MODIFICA
 TION USAGE directoryOperation )
olcAttributeTypes: ( 1.3.6.1.4.1.4203.666.1.23 NAME 'syncreplCookie' DESC 'syn
 crepl Cookie for shadow copy' EQUALITY octetStringMatch ORDERING octetStringO
 rderingMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.40 SINGLE-VALUE NO-USER-MODIFI
 CATION USAGE dSAOperation )
olcAttributeTypes: ( 1.3.6.1.4.1.4203.666.1.25 NAME 'contextCSN' DESC 'the lar
 gest committed CSN of a context' EQUALITY CSNMatch ORDERING CSNOrderingMatch 
 SYNTAX 1.3.6.1.4.1.4203.666.11.2.1{64} NO-USER-MODIFICATION USAGE dSAOperatio
 n )
olcAttributeTypes: ( 1.3.6.1.4.1.1466.101.120.6 NAME 'altServer' DESC 'RFC4512
 : alternative servers' SYNTAX 1.3.6.1.4.1.1466.115.121.1.26 USAGE dSAOperatio
 n )
olcAttributeTypes: ( 1.3.6.1.4.1.1466.101.120.5 NAME 'namingContexts' DESC 'RF
 C4512: naming contexts' SYNTAX 1.3.6.1.4.1.1466.115.121.1.12 USAGE dSAOperati
 on )
olcAttributeTypes: ( 1.3.6.1.4.1.1466.101.120.13 NAME 'supportedControl' DESC 
 'RFC4512: supported controls' SYNTAX 1.3.6.1.4.1.1466.115.121.1.38 USAGE dSAO
 peration )
olcAttributeTypes: ( 1.3.6.1.4.1.1466.101.120.7 NAME 'supportedExtension' DESC
  'RFC4512: supported extended operations' SYNTAX 1.3.6.1.4.1.1466.115.121.1.3
 8 USAGE dSAOperation )
olcAttributeTypes: ( 1.3.6.1.4.1.1466.101.120.15 NAME 'supportedLDAPVersion' D
 ESC 'RFC4512: supported LDAP versions' SYNTAX 1.3.6.1.4.1.1466.115.121.1.27 U
 SAGE dSAOperation )
olcAttributeTypes: ( 1.3.6.1.4.1.1466.101.120.14 NAME 'supportedSASLMechanisms
 ' DESC 'RFC4512: supported SASL mechanisms' SYNTAX 1.3.6.1.4.1.1466.115.121.1
 .15 USAGE dSAOperation )
olcAttributeTypes: ( 1.3.6.1.4.1.4203.1.3.5 NAME 'supportedFeatures' DESC 'RFC
 4512: features supported by the server' EQUALITY objectIdentifierMatch SYNTAX
  1.3.6.1.4.1.1466.115.121.1.38 USAGE dSAOperation )
olcAttributeTypes: ( 1.3.6.1.4.1.4203.666.1.10 NAME 'monitorContext' DESC 'mon
 itor context' EQUALITY distinguishedNameMatch SYNTAX 1.3.6.1.4.1.1466.115.121
 .1.12 SINGLE-VALUE NO-USER-MODIFICATION USAGE dSAOperation )
olcAttributeTypes: ( 1.3.6.1.4.1.4203.1.12.2.1 NAME 'configContext' DESC 'conf
 ig context' EQUALITY distinguishedNameMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1
 .12 SINGLE-VALUE NO-USER-MODIFICATION USAGE dSAOperation )
olcAttributeTypes: ( 1.3.6.1.1.4 NAME 'vendorName' DESC 'RFC3045: name of impl
 ementation vendor' EQUALITY caseExactMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.
 15 SINGLE-VALUE NO-USER-MODIFICATION USAGE dSAOperation )
olcAttributeTypes: ( 1.3.6.1.1.5 NAME 'vendorVersion' DESC 'RFC3045: version o
 f implementation' EQUALITY caseExactMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.1
 5 SINGLE-VALUE NO-USER-MODIFICATION USAGE dSAOperation )
olcAttributeTypes: ( 2.5.18.5 NAME 'administrativeRole' DESC 'RFC3672: adminis
 trative role' EQUALITY objectIdentifierMatch SYNTAX 1.3.6.1.4.1.1466.115.121.
 1.38 USAGE directoryOperation )
olcAttributeTypes: ( 2.5.18.6 NAME 'subtreeSpecification' DESC 'RFC3672: subtr
 ee specification' SYNTAX 1.3.6.1.4.1.1466.115.121.1.45 SINGLE-VALUE USAGE dir
 ectoryOperation )
olcAttributeTypes: ( 2.5.21.1 NAME 'dITStructureRules' DESC 'RFC4512: DIT stru
 cture rules' EQUALITY integerFirstComponentMatch SYNTAX 1.3.6.1.4.1.1466.115.
 121.1.17 USAGE directoryOperation )
olcAttributeTypes: ( 2.5.21.2 NAME 'dITContentRules' DESC 'RFC4512: DIT conten
 t rules' EQUALITY objectIdentifierFirstComponentMatch SYNTAX 1.3.6.1.4.1.1466
 .115.121.1.16 USAGE directoryOperation )
olcAttributeTypes: ( 2.5.21.4 NAME 'matchingRules' DESC 'RFC4512: matching rul
 es' EQUALITY objectIdentifierFirstComponentMatch SYNTAX 1.3.6.1.4.1.1466.115.
 121.1.30 USAGE directoryOperation )
olcAttributeTypes: ( 2.5.21.5 NAME 'attributeTypes' DESC 'RFC4512: attribute t
 ypes' EQUALITY objectIdentifierFirstComponentMatch SYNTAX 1.3.6.1.4.1.1466.11
 5.121.1.3 USAGE directoryOperation )
olcAttributeTypes: ( 2.5.21.6 NAME 'objectClasses' DESC 'RFC4512: object class
 es' EQUALITY objectIdentifierFirstComponentMatch SYNTAX 1.3.6.1.4.1.1466.115.
 121.1.37 USAGE directoryOperation )
olcAttributeTypes: ( 2.5.21.7 NAME 'nameForms' DESC 'RFC4512: name forms ' EQU
 ALITY objectIdentifierFirstComponentMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.3
 5 USAGE directoryOperation )
olcAttributeTypes: ( 2.5.21.8 NAME 'matchingRuleUse' DESC 'RFC4512: matching r
 ule uses' EQUALITY objectIdentifierFirstComponentMatch SYNTAX 1.3.6.1.4.1.146
 6.115.121.1.31 USAGE directoryOperation )
olcAttributeTypes: ( 1.3.6.1.4.1.1466.101.120.16 NAME 'ldapSyntaxes' DESC 'RFC
 4512: LDAP syntaxes' EQUALITY objectIdentifierFirstComponentMatch SYNTAX 1.3.
 6.1.4.1.1466.115.121.1.54 USAGE directoryOperation )
olcAttributeTypes: ( 2.5.4.1 NAME ( 'aliasedObjectName' 'aliasedEntryName' ) D
 ESC 'RFC4512: name of aliased object' EQUALITY distinguishedNameMatch SYNTAX 
 1.3.6.1.4.1.1466.115.121.1.12 SINGLE-VALUE )
olcAttributeTypes: ( 2.16.840.1.113730.3.1.34 NAME 'ref' DESC 'RFC3296: subord
 inate referral URL' EQUALITY caseExactMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1
 .15 USAGE distributedOperation )
olcAttributeTypes: ( 1.3.6.1.4.1.4203.1.3.1 NAME 'entry' DESC 'OpenLDAP ACL en
 try pseudo-attribute' SYNTAX 1.3.6.1.4.1.4203.1.1.1 SINGLE-VALUE NO-USER-MODI
 FICATION USAGE dSAOperation )
olcAttributeTypes: ( 1.3.6.1.4.1.4203.1.3.2 NAME 'children' DESC 'OpenLDAP ACL
  children pseudo-attribute' SYNTAX 1.3.6.1.4.1.4203.1.1.1 SINGLE-VALUE NO-USE
 R-MODIFICATION USAGE dSAOperation )
olcAttributeTypes: ( 1.3.6.1.4.1.4203.666.1.8 NAME ( 'authzTo' 'saslAuthzTo' )
  DESC 'proxy authorization targets' EQUALITY authzMatch SYNTAX 1.3.6.1.4.1.42
 03.666.2.7 USAGE distributedOperation X-ORDERED 'VALUES' )
olcAttributeTypes: ( 1.3.6.1.4.1.4203.666.1.9 NAME ( 'authzFrom' 'saslAuthzFro
 m' ) DESC 'proxy authorization sources' EQUALITY authzMatch SYNTAX 1.3.6.1.4.
 1.4203.666.2.7 USAGE distributedOperation X-ORDERED 'VALUES' )
olcAttributeTypes: ( 1.3.6.1.4.1.1466.101.119.3 NAME 'entryTtl' DESC 'RFC2589:
  entry time-to-live' SYNTAX 1.3.6.1.4.1.1466.115.121.1.27 SINGLE-VALUE NO-USE
 R-MODIFICATION USAGE dSAOperation )
olcAttributeTypes: ( 1.3.6.1.4.1.1466.101.119.4 NAME 'dynamicSubtrees' DESC 'R
 FC2589: dynamic subtrees' SYNTAX 1.3.6.1.4.1.1466.115.121.1.12 NO-USER-MODIFI
 CATION USAGE dSAOperation )
olcAttributeTypes: ( 2.5.4.49 NAME 'distinguishedName' DESC 'RFC4519: common s
 upertype of DN attributes' EQUALITY distinguishedNameMatch SYNTAX 1.3.6.1.4.1
 .1466.115.121.1.12 )
olcAttributeTypes: ( 2.5.4.41 NAME 'name' DESC 'RFC4519: common supertype of n
 ame attributes' EQUALITY caseIgnoreMatch SUBSTR caseIgnoreSubstringsMatch SYN
 TAX 1.3.6.1.4.1.1466.115.121.1.15{32768} )
olcAttributeTypes: ( 2.5.4.3 NAME ( 'cn' 'commonName' ) DESC 'RFC4519: common 
 name(s) for which the entity is known by' SUP name )
olcAttributeTypes: ( 0.9.2342.19200300.100.1.1 NAME ( 'uid' 'userid' ) DESC 'R
 FC4519: user identifier' EQUALITY caseIgnoreMatch SUBSTR caseIgnoreSubstrings
 Match SYNTAX 1.3.6.1.4.1.1466.115.121.1.15{256} )
olcAttributeTypes: ( 1.3.6.1.1.1.1.0 NAME 'uidNumber' DESC 'RFC2307: An intege
 r uniquely identifying a user in an administrative domain' EQUALITY integerMa
 tch ORDERING integerOrderingMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.27 SINGLE
 -VALUE )
olcAttributeTypes: ( 1.3.6.1.1.1.1.1 NAME 'gidNumber' DESC 'RFC2307: An intege
 r uniquely identifying a group in an administrative domain' EQUALITY integerM
 atch ORDERING integerOrderingMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.27 SINGL
 E-VALUE )
olcAttributeTypes: ( 2.5.4.35 NAME 'userPassword' DESC 'RFC4519/2307: password
  of user' EQUALITY octetStringMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.40{128}
  )
olcAttributeTypes: ( 1.3.6.1.4.1.250.1.57 NAME 'labeledURI' DESC 'RFC2079: Uni
 form Resource Identifier with optional label' EQUALITY caseExactMatch SYNTAX 
 1.3.6.1.4.1.1466.115.121.1.15 )
olcAttributeTypes: ( 2.5.4.13 NAME 'description' DESC 'RFC4519: descriptive in
 formation' EQUALITY caseIgnoreMatch SUBSTR caseIgnoreSubstringsMatch SYNTAX 1
 .3.6.1.4.1.1466.115.121.1.15{1024} )
olcAttributeTypes: ( 2.5.4.34 NAME 'seeAlso' DESC 'RFC4519: DN of related obje
 ct' SUP distinguishedName )
olcAttributeTypes: ( OLcfgGlAt:78 NAME 'olcConfigFile' DESC 'File for slapd co
 nfiguration directives' EQUALITY caseIgnoreMatch SYNTAX OMsDirectoryString SI
 NGLE-VALUE )
olcAttributeTypes: ( OLcfgGlAt:79 NAME 'olcConfigDir' DESC 'Directory for slap
 d configuration backend' EQUALITY caseIgnoreMatch SYNTAX OMsDirectoryString S
 INGLE-VALUE )
olcAttributeTypes: ( OLcfgGlAt:1 NAME 'olcAccess' DESC 'Access Control List' E
 QUALITY caseIgnoreMatch SYNTAX OMsDirectoryString X-ORDERED 'VALUES' )
olcAttributeTypes: ( OLcfgGlAt:86 NAME 'olcAddContentAcl' DESC 'Check ACLs aga
 inst content of Add ops' SYNTAX OMsBoolean SINGLE-VALUE )
olcAttributeTypes: ( OLcfgGlAt:2 NAME 'olcAllows' DESC 'Allowed set of depreca
 ted features' EQUALITY caseIgnoreMatch SYNTAX OMsDirectoryString )
olcAttributeTypes: ( OLcfgGlAt:3 NAME 'olcArgsFile' DESC 'File for slapd comma
 nd line options' EQUALITY caseIgnoreMatch SYNTAX OMsDirectoryString SINGLE-VA
 LUE )
olcAttributeTypes: ( OLcfgGlAt:5 NAME 'olcAttributeOptions' EQUALITY caseIgnor
 eMatch SYNTAX OMsDirectoryString )
olcAttributeTypes: ( OLcfgGlAt:4 NAME 'olcAttributeTypes' DESC 'OpenLDAP attri
 buteTypes' EQUALITY caseIgnoreMatch SUBSTR caseIgnoreSubstringsMatch SYNTAX O
 MsDirectoryString X-ORDERED 'VALUES' )
olcAttributeTypes: ( OLcfgGlAt:6 NAME 'olcAuthIDRewrite' EQUALITY caseIgnoreMa
 tch SYNTAX OMsDirectoryString X-ORDERED 'VALUES' )
olcAttributeTypes: ( OLcfgGlAt:7 NAME 'olcAuthzPolicy' EQUALITY caseIgnoreMatc
 h SYNTAX OMsDirectoryString SINGLE-VALUE )
olcAttributeTypes: ( OLcfgGlAt:8 NAME 'olcAuthzRegexp' EQUALITY caseIgnoreMatc
 h SYNTAX OMsDirectoryString X-ORDERED 'VALUES' )
olcAttributeTypes: ( OLcfgGlAt:9 NAME 'olcBackend' DESC 'A type of backend' EQ
 UALITY caseIgnoreMatch SYNTAX OMsDirectoryString SINGLE-VALUE X-ORDERED 'SIBL
 INGS' )
olcAttributeTypes: ( OLcfgGlAt:10 NAME 'olcConcurrency' SYNTAX OMsInteger SING
 LE-VALUE )
olcAttributeTypes: ( OLcfgGlAt:11 NAME 'olcConnMaxPending' SYNTAX OMsInteger S
 INGLE-VALUE )
olcAttributeTypes: ( OLcfgGlAt:12 NAME 'olcConnMaxPendingAuth' SYNTAX OMsInteg
 er SINGLE-VALUE )
olcAttributeTypes: ( OLcfgGlAt:13 NAME 'olcDatabase' DESC 'The backend type fo
 r a database instance' SUP olcBackend SINGLE-VALUE X-ORDERED 'SIBLINGS' )
olcAttributeTypes: ( OLcfgGlAt:14 NAME 'olcDefaultSearchBase' SYNTAX OMsDN SIN
 GLE-VALUE )
olcAttributeTypes: ( OLcfgGlAt:15 NAME 'olcDisallows' EQUALITY caseIgnoreMatch
  SYNTAX OMsDirectoryString )
olcAttributeTypes: ( OLcfgGlAt:16 NAME 'olcDitContentRules' DESC 'OpenLDAP DIT
  content rules' EQUALITY caseIgnoreMatch SUBSTR caseIgnoreSubstringsMatch SYN
 TAX OMsDirectoryString X-ORDERED 'VALUES' )
olcAttributeTypes: ( OLcfgDbAt:0.20 NAME 'olcExtraAttrs' EQUALITY caseIgnoreMa
 tch SYNTAX OMsDirectoryString )
olcAttributeTypes: ( OLcfgGlAt:17 NAME 'olcGentleHUP' SYNTAX OMsBoolean SINGLE
 -VALUE )
olcAttributeTypes: ( OLcfgDbAt:0.17 NAME 'olcHidden' SYNTAX OMsBoolean SINGLE-
 VALUE )
olcAttributeTypes: ( OLcfgGlAt:18 NAME 'olcIdleTimeout' SYNTAX OMsInteger SING
 LE-VALUE )
olcAttributeTypes: ( OLcfgGlAt:19 NAME 'olcInclude' SUP labeledURI )
olcAttributeTypes: ( OLcfgGlAt:20 NAME 'olcIndexSubstrIfMinLen' SYNTAX OMsInte
 ger SINGLE-VALUE )
olcAttributeTypes: ( OLcfgGlAt:21 NAME 'olcIndexSubstrIfMaxLen' SYNTAX OMsInte
 ger SINGLE-VALUE )
olcAttributeTypes: ( OLcfgGlAt:22 NAME 'olcIndexSubstrAnyLen' SYNTAX OMsIntege
 r SINGLE-VALUE )
olcAttributeTypes: ( OLcfgGlAt:23 NAME 'olcIndexSubstrAnyStep' SYNTAX OMsInteg
 er SINGLE-VALUE )
olcAttributeTypes: ( OLcfgGlAt:84 NAME 'olcIndexIntLen' SYNTAX OMsInteger SING
 LE-VALUE )
olcAttributeTypes: ( OLcfgDbAt:0.4 NAME 'olcLastMod' SYNTAX OMsBoolean SINGLE-
 VALUE )
olcAttributeTypes: ( OLcfgGlAt:85 NAME 'olcLdapSyntaxes' DESC 'OpenLDAP ldapSy
 ntax' EQUALITY caseIgnoreMatch SUBSTR caseIgnoreSubstringsMatch SYNTAX OMsDir
 ectoryString X-ORDERED 'VALUES' )
olcAttributeTypes: ( OLcfgDbAt:0.5 NAME 'olcLimits' EQUALITY caseIgnoreMatch S
 YNTAX OMsDirectoryString X-ORDERED 'VALUES' )
olcAttributeTypes: ( OLcfgGlAt:93 NAME 'olcListenerThreads' SYNTAX OMsInteger 
 SINGLE-VALUE )
olcAttributeTypes: ( OLcfgGlAt:26 NAME 'olcLocalSSF' SYNTAX OMsInteger SINGLE-
 VALUE )
olcAttributeTypes: ( OLcfgGlAt:27 NAME 'olcLogFile' SYNTAX OMsDirectoryString 
 SINGLE-VALUE )
olcAttributeTypes: ( OLcfgGlAt:28 NAME 'olcLogLevel' EQUALITY caseIgnoreMatch 
 SYNTAX OMsDirectoryString )
olcAttributeTypes: ( OLcfgDbAt:0.6 NAME 'olcMaxDerefDepth' SYNTAX OMsInteger S
 INGLE-VALUE )
olcAttributeTypes: ( OLcfgDbAt:0.16 NAME 'olcMirrorMode' SYNTAX OMsBoolean SIN
 GLE-VALUE )
olcAttributeTypes: ( OLcfgGlAt:30 NAME 'olcModuleLoad' EQUALITY caseIgnoreMatc
 h SYNTAX OMsDirectoryString X-ORDERED 'VALUES' )
olcAttributeTypes: ( OLcfgGlAt:31 NAME 'olcModulePath' SYNTAX OMsDirectoryStri
 ng SINGLE-VALUE )
olcAttributeTypes: ( OLcfgDbAt:0.18 NAME 'olcMonitoring' SYNTAX OMsBoolean SIN
 GLE-VALUE )
olcAttributeTypes: ( OLcfgGlAt:32 NAME 'olcObjectClasses' DESC 'OpenLDAP objec
 t classes' EQUALITY caseIgnoreMatch SUBSTR caseIgnoreSubstringsMatch SYNTAX O
 MsDirectoryString X-ORDERED 'VALUES' )
olcAttributeTypes: ( OLcfgGlAt:33 NAME 'olcObjectIdentifier' EQUALITY caseIgno
 reMatch SUBSTR caseIgnoreSubstringsMatch SYNTAX OMsDirectoryString X-ORDERED 
 'VALUES' )
olcAttributeTypes: ( OLcfgGlAt:34 NAME 'olcOverlay' SUP olcDatabase SINGLE-VAL
 UE X-ORDERED 'SIBLINGS' )
olcAttributeTypes: ( OLcfgGlAt:35 NAME 'olcPasswordCryptSaltFormat' SYNTAX OMs
 DirectoryString SINGLE-VALUE )
olcAttributeTypes: ( OLcfgGlAt:36 NAME 'olcPasswordHash' EQUALITY caseIgnoreMa
 tch SYNTAX OMsDirectoryString )
olcAttributeTypes: ( OLcfgGlAt:37 NAME 'olcPidFile' SYNTAX OMsDirectoryString 
 SINGLE-VALUE )
olcAttributeTypes: ( OLcfgGlAt:38 NAME 'olcPlugin' EQUALITY caseIgnoreMatch SY
 NTAX OMsDirectoryString )
olcAttributeTypes: ( OLcfgGlAt:39 NAME 'olcPluginLogFile' SYNTAX OMsDirectoryS
 tring SINGLE-VALUE )
olcAttributeTypes: ( OLcfgGlAt:40 NAME 'olcReadOnly' SYNTAX OMsBoolean SINGLE-
 VALUE )
olcAttributeTypes: ( OLcfgGlAt:41 NAME 'olcReferral' SUP labeledURI SINGLE-VAL
 UE )
olcAttributeTypes: ( OLcfgDbAt:0.7 NAME 'olcReplica' SUP labeledURI EQUALITY c
 aseIgnoreMatch X-ORDERED 'VALUES' )
olcAttributeTypes: ( OLcfgGlAt:43 NAME 'olcReplicaArgsFile' SYNTAX OMsDirector
 yString SINGLE-VALUE )
olcAttributeTypes: ( OLcfgGlAt:44 NAME 'olcReplicaPidFile' SYNTAX OMsDirectory
 String SINGLE-VALUE )
olcAttributeTypes: ( OLcfgGlAt:45 NAME 'olcReplicationInterval' SYNTAX OMsInte
 ger SINGLE-VALUE )
olcAttributeTypes: ( OLcfgGlAt:46 NAME 'olcReplogFile' SYNTAX OMsDirectoryStri
 ng SINGLE-VALUE )
olcAttributeTypes: ( OLcfgGlAt:47 NAME 'olcRequires' EQUALITY caseIgnoreMatch 
 SYNTAX OMsDirectoryString )
olcAttributeTypes: ( OLcfgGlAt:48 NAME 'olcRestrict' EQUALITY caseIgnoreMatch 
 SYNTAX OMsDirectoryString )
olcAttributeTypes: ( OLcfgGlAt:49 NAME 'olcReverseLookup' SYNTAX OMsBoolean SI
 NGLE-VALUE )
olcAttributeTypes: ( OLcfgDbAt:0.8 NAME 'olcRootDN' EQUALITY distinguishedName
 Match SYNTAX OMsDN SINGLE-VALUE )
olcAttributeTypes: ( OLcfgGlAt:51 NAME 'olcRootDSE' EQUALITY caseIgnoreMatch S
 YNTAX OMsDirectoryString )
olcAttributeTypes: ( OLcfgDbAt:0.9 NAME 'olcRootPW' SYNTAX OMsDirectoryString 
 SINGLE-VALUE )
olcAttributeTypes: ( OLcfgGlAt:89 NAME 'olcSaslAuxprops' SYNTAX OMsDirectorySt
 ring SINGLE-VALUE )
olcAttributeTypes: ( OLcfgGlAt:53 NAME 'olcSaslHost' SYNTAX OMsDirectoryString
  SINGLE-VALUE )
olcAttributeTypes: ( OLcfgGlAt:54 NAME 'olcSaslRealm' SYNTAX OMsDirectoryStrin
 g SINGLE-VALUE )
olcAttributeTypes: ( OLcfgGlAt:56 NAME 'olcSaslSecProps' SYNTAX OMsDirectorySt
 ring SINGLE-VALUE )
olcAttributeTypes: ( OLcfgGlAt:58 NAME 'olcSchemaDN' EQUALITY distinguishedNam
 eMatch SYNTAX OMsDN SINGLE-VALUE )
olcAttributeTypes: ( OLcfgGlAt:59 NAME 'olcSecurity' EQUALITY caseIgnoreMatch 
 SYNTAX OMsDirectoryString )
olcAttributeTypes: ( OLcfgGlAt:81 NAME 'olcServerID' EQUALITY caseIgnoreMatch 
 SYNTAX OMsDirectoryString )
olcAttributeTypes: ( OLcfgGlAt:60 NAME 'olcSizeLimit' SYNTAX OMsDirectoryStrin
 g SINGLE-VALUE )
olcAttributeTypes: ( OLcfgGlAt:61 NAME 'olcSockbufMaxIncoming' SYNTAX OMsInteg
 er SINGLE-VALUE )
olcAttributeTypes: ( OLcfgGlAt:62 NAME 'olcSockbufMaxIncomingAuth' SYNTAX OMsI
 nteger SINGLE-VALUE )
olcAttributeTypes: ( OLcfgGlAt:83 NAME 'olcSortVals' DESC 'Attributes whose va
 lues will always be sorted' EQUALITY caseIgnoreMatch SYNTAX OMsDirectoryStrin
 g )
olcAttributeTypes: ( OLcfgDbAt:0.15 NAME 'olcSubordinate' SYNTAX OMsDirectoryS
 tring SINGLE-VALUE )
olcAttributeTypes: ( OLcfgDbAt:0.10 NAME 'olcSuffix' EQUALITY distinguishedNam
 eMatch SYNTAX OMsDN )
olcAttributeTypes: ( OLcfgDbAt:0.19 NAME 'olcSyncUseSubentry' DESC 'Store sync
  context in a subentry' SYNTAX OMsBoolean SINGLE-VALUE )
olcAttributeTypes: ( OLcfgDbAt:0.11 NAME 'olcSyncrepl' EQUALITY caseIgnoreMatc
 h SYNTAX OMsDirectoryString X-ORDERED 'VALUES' )
olcAttributeTypes: ( OLcfgGlAt:90 NAME 'olcTCPBuffer' DESC 'Custom TCP buffer 
 size' SYNTAX OMsDirectoryString )
olcAttributeTypes: ( OLcfgGlAt:66 NAME 'olcThreads' SYNTAX OMsInteger SINGLE-V
 ALUE )
olcAttributeTypes: ( OLcfgGlAt:67 NAME 'olcTimeLimit' SYNTAX OMsDirectoryStrin
 g )
olcAttributeTypes: ( OLcfgGlAt:68 NAME 'olcTLSCACertificateFile' SYNTAX OMsDir
 ectoryString SINGLE-VALUE )
olcAttributeTypes: ( OLcfgGlAt:69 NAME 'olcTLSCACertificatePath' SYNTAX OMsDir
 ectoryString SINGLE-VALUE )
olcAttributeTypes: ( OLcfgGlAt:70 NAME 'olcTLSCertificateFile' SYNTAX OMsDirec
 toryString SINGLE-VALUE )
olcAttributeTypes: ( OLcfgGlAt:71 NAME 'olcTLSCertificateKeyFile' SYNTAX OMsDi
 rectoryString SINGLE-VALUE )
olcAttributeTypes: ( OLcfgGlAt:72 NAME 'olcTLSCipherSuite' SYNTAX OMsDirectory
 String SINGLE-VALUE )
olcAttributeTypes: ( OLcfgGlAt:73 NAME 'olcTLSCRLCheck' SYNTAX OMsDirectoryStr
 ing SINGLE-VALUE )
olcAttributeTypes: ( OLcfgGlAt:82 NAME 'olcTLSCRLFile' SYNTAX OMsDirectoryStri
 ng SINGLE-VALUE )
olcAttributeTypes: ( OLcfgGlAt:74 NAME 'olcTLSRandFile' SYNTAX OMsDirectoryStr
 ing SINGLE-VALUE )
olcAttributeTypes: ( OLcfgGlAt:75 NAME 'olcTLSVerifyClient' SYNTAX OMsDirector
 yString SINGLE-VALUE )
olcAttributeTypes: ( OLcfgGlAt:77 NAME 'olcTLSDHParamFile' SYNTAX OMsDirectory
 String SINGLE-VALUE )
olcAttributeTypes: ( OLcfgGlAt:87 NAME 'olcTLSProtocolMin' SYNTAX OMsDirectory
 String SINGLE-VALUE )
olcAttributeTypes: ( OLcfgGlAt:80 NAME 'olcToolThreads' SYNTAX OMsInteger SING
 LE-VALUE )
olcAttributeTypes: ( OLcfgDbAt:0.12 NAME 'olcUpdateDN' SYNTAX OMsDN SINGLE-VAL
 UE )
olcAttributeTypes: ( OLcfgDbAt:0.13 NAME 'olcUpdateRef' SUP labeledURI EQUALIT
 Y caseIgnoreMatch )
olcAttributeTypes: ( OLcfgGlAt:88 NAME 'olcWriteTimeout' SYNTAX OMsInteger SIN
 GLE-VALUE )
olcAttributeTypes: ( OLcfgDbAt:0.1 NAME 'olcDbDirectory' DESC 'Directory for d
 atabase content' EQUALITY caseIgnoreMatch SYNTAX OMsDirectoryString SINGLE-VA
 LUE )
olcAttributeTypes: ( 1.3.6.1.4.1.4203.666.1.55.1 NAME 'monitoredInfo' DESC 'mo
 nitored info' EQUALITY caseIgnoreMatch SUBSTR caseIgnoreSubstringsMatch SYNTA
 X 1.3.6.1.4.1.1466.115.121.1.15{32768} NO-USER-MODIFICATION USAGE dSAOperatio
 n )
olcAttributeTypes: ( 1.3.6.1.4.1.4203.666.1.55.2 NAME 'managedInfo' DESC 'moni
 tor managed info' SUP name )
olcAttributeTypes: ( 1.3.6.1.4.1.4203.666.1.55.3 NAME 'monitorCounter' DESC 'm
 onitor counter' EQUALITY integerMatch ORDERING integerOrderingMatch SYNTAX 1.
 3.6.1.4.1.1466.115.121.1.27 NO-USER-MODIFICATION USAGE dSAOperation )
olcAttributeTypes: ( 1.3.6.1.4.1.4203.666.1.55.4 NAME 'monitorOpCompleted' DES
 C 'monitor completed operations' SUP monitorCounter NO-USER-MODIFICATION USAG
 E dSAOperation )
olcAttributeTypes: ( 1.3.6.1.4.1.4203.666.1.55.5 NAME 'monitorOpInitiated' DES
 C 'monitor initiated operations' SUP monitorCounter NO-USER-MODIFICATION USAG
 E dSAOperation )
olcAttributeTypes: ( 1.3.6.1.4.1.4203.666.1.55.6 NAME 'monitorConnectionNumber
 ' DESC 'monitor connection number' SUP monitorCounter NO-USER-MODIFICATION US
 AGE dSAOperation )
olcAttributeTypes: ( 1.3.6.1.4.1.4203.666.1.55.7 NAME 'monitorConnectionAuthzD
 N' DESC 'monitor connection authorization DN' EQUALITY distinguishedNameMatch
  SYNTAX 1.3.6.1.4.1.1466.115.121.1.12 NO-USER-MODIFICATION USAGE dSAOperation
  )
olcAttributeTypes: ( 1.3.6.1.4.1.4203.666.1.55.8 NAME 'monitorConnectionLocalA
 ddress' DESC 'monitor connection local address' SUP monitoredInfo NO-USER-MOD
 IFICATION USAGE dSAOperation )
olcAttributeTypes: ( 1.3.6.1.4.1.4203.666.1.55.9 NAME 'monitorConnectionPeerAd
 dress' DESC 'monitor connection peer address' SUP monitoredInfo NO-USER-MODIF
 ICATION USAGE dSAOperation )
olcAttributeTypes: ( 1.3.6.1.4.1.4203.666.1.55.10 NAME 'monitorTimestamp' DESC
  'monitor timestamp' EQUALITY generalizedTimeMatch ORDERING generalizedTimeOr
 deringMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.24 SINGLE-VALUE NO-USER-MODIFIC
 ATION USAGE dSAOperation )
olcAttributeTypes: ( 1.3.6.1.4.1.4203.666.1.55.11 NAME 'monitorOverlay' DESC '
 name of overlays defined for a given database' SUP monitoredInfo NO-USER-MODI
 FICATION USAGE dSAOperation )
olcAttributeTypes: ( 1.3.6.1.4.1.4203.666.1.55.12 NAME 'readOnly' DESC 'read/w
 rite status of a given database' EQUALITY booleanMatch SYNTAX 1.3.6.1.4.1.146
 6.115.121.1.7 SINGLE-VALUE USAGE dSAOperation )
olcAttributeTypes: ( 1.3.6.1.4.1.4203.666.1.55.13 NAME 'restrictedOperation' D
 ESC 'name of restricted operation for a given database' SUP managedInfo )
olcAttributeTypes: ( 1.3.6.1.4.1.4203.666.1.55.14 NAME 'monitorConnectionProto
 col' DESC 'monitor connection protocol' SUP monitoredInfo NO-USER-MODIFICATIO
 N USAGE dSAOperation )
olcAttributeTypes: ( 1.3.6.1.4.1.4203.666.1.55.15 NAME 'monitorConnectionOpsRe
 ceived' DESC 'monitor number of operations received by the connection' SUP mo
 nitorCounter NO-USER-MODIFICATION USAGE dSAOperation )
olcAttributeTypes: ( 1.3.6.1.4.1.4203.666.1.55.16 NAME 'monitorConnectionOpsEx
 ecuting' DESC 'monitor number of operations in execution within the connectio
 n' SUP monitorCounter NO-USER-MODIFICATION USAGE dSAOperation )
olcAttributeTypes: ( 1.3.6.1.4.1.4203.666.1.55.17 NAME 'monitorConnectionOpsPe
 nding' DESC 'monitor number of pending operations within the connection' SUP 
 monitorCounter NO-USER-MODIFICATION USAGE dSAOperation )
olcAttributeTypes: ( 1.3.6.1.4.1.4203.666.1.55.18 NAME 'monitorConnectionOpsCo
 mpleted' DESC 'monitor number of operations completed within the connection' 
 SUP monitorCounter NO-USER-MODIFICATION USAGE dSAOperation )
olcAttributeTypes: ( 1.3.6.1.4.1.4203.666.1.55.19 NAME 'monitorConnectionGet' 
 DESC 'number of times connection_get() was called so far' SUP monitorCounter 
 NO-USER-MODIFICATION USAGE dSAOperation )
olcAttributeTypes: ( 1.3.6.1.4.1.4203.666.1.55.20 NAME 'monitorConnectionRead'
  DESC 'number of times connection_read() was called so far' SUP monitorCounte
 r NO-USER-MODIFICATION USAGE dSAOperation )
olcAttributeTypes: ( 1.3.6.1.4.1.4203.666.1.55.21 NAME 'monitorConnectionWrite
 ' DESC 'number of times connection_write() was called so far' SUP monitorCoun
 ter NO-USER-MODIFICATION USAGE dSAOperation )
olcAttributeTypes: ( 1.3.6.1.4.1.4203.666.1.55.22 NAME 'monitorConnectionMask'
  DESC 'monitor connection mask' SUP monitoredInfo NO-USER-MODIFICATION USAGE 
 dSAOperation )
olcAttributeTypes: ( 1.3.6.1.4.1.4203.666.1.55.23 NAME 'monitorConnectionListe
 ner' DESC 'monitor connection listener' SUP monitoredInfo NO-USER-MODIFICATIO
 N USAGE dSAOperation )
olcAttributeTypes: ( 1.3.6.1.4.1.4203.666.1.55.24 NAME 'monitorConnectionPeerD
 omain' DESC 'monitor connection peer domain' SUP monitoredInfo NO-USER-MODIFI
 CATION USAGE dSAOperation )
olcAttributeTypes: ( 1.3.6.1.4.1.4203.666.1.55.25 NAME 'monitorConnectionStart
 Time' DESC 'monitor connection start time' SUP monitorTimestamp SINGLE-VALUE 
 NO-USER-MODIFICATION USAGE dSAOperation )
olcAttributeTypes: ( 1.3.6.1.4.1.4203.666.1.55.26 NAME 'monitorConnectionActiv
 ityTime' DESC 'monitor connection activity time' SUP monitorTimestamp SINGLE-
 VALUE NO-USER-MODIFICATION USAGE dSAOperation )
olcAttributeTypes: ( 1.3.6.1.4.1.4203.666.1.55.27 NAME 'monitorIsShadow' DESC 
 'TRUE if the database is shadow' EQUALITY booleanMatch SYNTAX 1.3.6.1.4.1.146
 6.115.121.1.7 SINGLE-VALUE USAGE dSAOperation )
olcAttributeTypes: ( 1.3.6.1.4.1.4203.666.1.55.28 NAME 'monitorUpdateRef' DESC
  'update referral for shadow databases' SUP monitoredInfo SINGLE-VALUE USAGE 
 dSAOperation )
olcAttributeTypes: ( 1.3.6.1.4.1.4203.666.1.55.29 NAME 'monitorRuntimeConfig' 
 DESC 'TRUE if component allows runtime configuration' EQUALITY booleanMatch S
 YNTAX 1.3.6.1.4.1.1466.115.121.1.7 SINGLE-VALUE USAGE dSAOperation )
olcAttributeTypes: ( 1.3.6.1.4.1.4203.666.1.55.30 NAME 'monitorSuperiorDN' DES
 C 'monitor superior DN' EQUALITY distinguishedNameMatch SYNTAX 1.3.6.1.4.1.14
 66.115.121.1.12 NO-USER-MODIFICATION USAGE dSAOperation )
olcAttributeTypes: ( OLcfgDbAt:1.11 NAME 'olcDbCacheFree' DESC 'Number of extr
 a entries to free when max is reached' SYNTAX OMsInteger SINGLE-VALUE )
olcAttributeTypes: ( OLcfgDbAt:1.1 NAME 'olcDbCacheSize' DESC 'Entry cache siz
 e in entries' SYNTAX OMsInteger SINGLE-VALUE )
olcAttributeTypes: ( OLcfgDbAt:1.2 NAME 'olcDbCheckpoint' DESC 'Database check
 point interval in kbytes and minutes' SYNTAX OMsDirectoryString SINGLE-VALUE 
 )
olcAttributeTypes: ( OLcfgDbAt:1.16 NAME 'olcDbChecksum' DESC 'Enable database
  checksum validation' SYNTAX OMsBoolean SINGLE-VALUE )
olcAttributeTypes: ( OLcfgDbAt:1.13 NAME 'olcDbCryptFile' DESC 'Pathname of fi
 le containing the DB encryption key' SYNTAX OMsDirectoryString SINGLE-VALUE )
olcAttributeTypes: ( OLcfgDbAt:1.14 NAME 'olcDbCryptKey' DESC 'DB encryption k
 ey' SYNTAX OMsOctetString SINGLE-VALUE )
olcAttributeTypes: ( OLcfgDbAt:1.3 NAME 'olcDbConfig' DESC 'BerkeleyDB DB_CONF
 IG configuration directives' SYNTAX OMsIA5String X-ORDERED 'VALUES' )
olcAttributeTypes: ( OLcfgDbAt:1.4 NAME 'olcDbNoSync' DESC 'Disable synchronou
 s database writes' SYNTAX OMsBoolean SINGLE-VALUE )
olcAttributeTypes: ( OLcfgDbAt:1.15 NAME 'olcDbPageSize' DESC 'Page size of sp
 ecified DB, in Kbytes' EQUALITY caseExactMatch SYNTAX OMsDirectoryString )
olcAttributeTypes: ( OLcfgDbAt:1.5 NAME 'olcDbDirtyRead' DESC 'Allow reads of 
 uncommitted data' SYNTAX OMsBoolean SINGLE-VALUE )
olcAttributeTypes: ( OLcfgDbAt:1.12 NAME 'olcDbDNcacheSize' DESC 'DN cache siz
 e' SYNTAX OMsInteger SINGLE-VALUE )
olcAttributeTypes: ( OLcfgDbAt:1.6 NAME 'olcDbIDLcacheSize' DESC 'IDL cache si
 ze in IDLs' SYNTAX OMsInteger SINGLE-VALUE )
olcAttributeTypes: ( OLcfgDbAt:0.2 NAME 'olcDbIndex' DESC 'Attribute index par
 ameters' EQUALITY caseIgnoreMatch SYNTAX OMsDirectoryString )
olcAttributeTypes: ( OLcfgDbAt:1.7 NAME 'olcDbLinearIndex' DESC 'Index attribu
 tes one at a time' SYNTAX OMsBoolean SINGLE-VALUE )
olcAttributeTypes: ( OLcfgDbAt:1.8 NAME 'olcDbLockDetect' DESC 'Deadlock detec
 tion algorithm' SYNTAX OMsDirectoryString SINGLE-VALUE )
olcAttributeTypes: ( OLcfgDbAt:0.3 NAME 'olcDbMode' DESC 'Unix permissions of 
 database files' SYNTAX OMsDirectoryString SINGLE-VALUE )
olcAttributeTypes: ( OLcfgDbAt:1.9 NAME 'olcDbSearchStack' DESC 'Depth of sear
 ch stack in IDLs' SYNTAX OMsInteger SINGLE-VALUE )
olcAttributeTypes: ( OLcfgDbAt:1.10 NAME 'olcDbShmKey' DESC 'Key for shared me
 mory region' SYNTAX OMsInteger SINGLE-VALUE )
olcAttributeTypes: ( OLcfgDbAt:0.14 NAME 'olcDbURI' DESC 'URI (list) for remot
 e DSA' SYNTAX OMsDirectoryString SINGLE-VALUE )
olcAttributeTypes: ( OLcfgDbAt:3.1 NAME 'olcDbStartTLS' DESC 'StartTLS' SYNTAX
  OMsDirectoryString SINGLE-VALUE )
olcAttributeTypes: ( OLcfgDbAt:3.2 NAME 'olcDbACLAuthcDn' DESC 'Remote ACL adm
 inistrative identity' OBSOLETE SYNTAX OMsDN SINGLE-VALUE )
olcAttributeTypes: ( OLcfgDbAt:3.3 NAME 'olcDbACLPasswd' DESC 'Remote ACL admi
 nistrative identity credentials' OBSOLETE SYNTAX OMsDirectoryString SINGLE-VA
 LUE )
olcAttributeTypes: ( OLcfgDbAt:3.4 NAME 'olcDbACLBind' DESC 'Remote ACL admini
 strative identity auth bind configuration' SYNTAX OMsDirectoryString SINGLE-V
 ALUE )
olcAttributeTypes: ( OLcfgDbAt:3.5 NAME 'olcDbIDAssertAuthcDn' DESC 'Remote Id
 entity Assertion administrative identity' OBSOLETE SYNTAX OMsDN SINGLE-VALUE 
 )
olcAttributeTypes: ( OLcfgDbAt:3.6 NAME 'olcDbIDAssertPasswd' DESC 'Remote Ide
 ntity Assertion administrative identity credentials' OBSOLETE SYNTAX OMsDirec
 toryString SINGLE-VALUE )
olcAttributeTypes: ( OLcfgDbAt:3.7 NAME 'olcDbIDAssertBind' DESC 'Remote Ident
 ity Assertion administrative identity auth bind configuration' SYNTAX OMsDire
 ctoryString SINGLE-VALUE )
olcAttributeTypes: ( OLcfgDbAt:3.8 NAME 'olcDbIDAssertMode' DESC 'Remote Ident
 ity Assertion mode' OBSOLETE SYNTAX OMsDirectoryString SINGLE-VALUE )
olcAttributeTypes: ( OLcfgDbAt:3.9 NAME 'olcDbIDAssertAuthzFrom' DESC 'Remote 
 Identity Assertion authz rules' EQUALITY caseIgnoreMatch SYNTAX OMsDirectoryS
 tring X-ORDERED 'VALUES' )
olcAttributeTypes: ( OLcfgDbAt:3.10 NAME 'olcDbRebindAsUser' DESC 'Rebind as u
 ser' SYNTAX OMsBoolean SINGLE-VALUE )
olcAttributeTypes: ( OLcfgDbAt:3.11 NAME 'olcDbChaseReferrals' DESC 'Chase ref
 errals' SYNTAX OMsBoolean SINGLE-VALUE )
olcAttributeTypes: ( OLcfgDbAt:3.12 NAME 'olcDbTFSupport' DESC 'Absolute filte
 rs support' SYNTAX OMsDirectoryString SINGLE-VALUE )
olcAttributeTypes: ( OLcfgDbAt:3.13 NAME 'olcDbProxyWhoAmI' DESC 'Proxy whoAmI
  exop' SYNTAX OMsBoolean SINGLE-VALUE )
olcAttributeTypes: ( OLcfgDbAt:3.14 NAME 'olcDbTimeout' DESC 'Per-operation ti
 meouts' SYNTAX OMsDirectoryString SINGLE-VALUE )
olcAttributeTypes: ( OLcfgDbAt:3.15 NAME 'olcDbIdleTimeout' DESC 'connection i
 dle timeout' SYNTAX OMsDirectoryString SINGLE-VALUE )
olcAttributeTypes: ( OLcfgDbAt:3.16 NAME 'olcDbConnTtl' DESC 'connection ttl' 
 SYNTAX OMsDirectoryString SINGLE-VALUE )
olcAttributeTypes: ( OLcfgDbAt:3.17 NAME 'olcDbNetworkTimeout' DESC 'connectio
 n network timeout' SYNTAX OMsDirectoryString SINGLE-VALUE )
olcAttributeTypes: ( OLcfgDbAt:3.18 NAME 'olcDbProtocolVersion' DESC 'protocol
  version' SYNTAX OMsInteger SINGLE-VALUE )
olcAttributeTypes: ( OLcfgDbAt:3.19 NAME 'olcDbSingleConn' DESC 'cache a singl
 e connection per identity' SYNTAX OMsBoolean SINGLE-VALUE )
olcAttributeTypes: ( OLcfgDbAt:3.20 NAME 'olcDbCancel' DESC 'abandon/ignore/ex
 op operations when appropriate' SYNTAX OMsDirectoryString SINGLE-VALUE )
olcAttributeTypes: ( OLcfgDbAt:3.21 NAME 'olcDbQuarantine' DESC 'Quarantine da
 tabase if connection fails and retry according to rule' SYNTAX OMsDirectorySt
 ring SINGLE-VALUE )
olcAttributeTypes: ( OLcfgDbAt:3.22 NAME 'olcDbUseTemporaryConn' DESC 'Use tem
 porary connections if the cached one is busy' SYNTAX OMsBoolean SINGLE-VALUE 
 )
olcAttributeTypes: ( OLcfgDbAt:3.23 NAME 'olcDbConnectionPoolMax' DESC 'Max si
 ze of privileged connections pool' SYNTAX OMsInteger SINGLE-VALUE )
olcAttributeTypes: ( OLcfgDbAt:3.25 NAME 'olcDbNoRefs' DESC 'Do not return sea
 rch reference responses' SYNTAX OMsBoolean SINGLE-VALUE )
olcAttributeTypes: ( OLcfgDbAt:3.26 NAME 'olcDbNoUndefFilter' DESC 'Do not pro
 pagate undefined search filters' SYNTAX OMsBoolean SINGLE-VALUE )
olcAttributeTypes: ( OLcfgDbAt:3.27 NAME 'olcDbIDAssertPassThru' DESC 'Remote 
 Identity Assertion passthru rules' EQUALITY caseIgnoreMatch SYNTAX OMsDirecto
 ryString X-ORDERED 'VALUES' )
olcAttributeTypes: ( OLcfgOvAt:3.1 NAME 'olcChainingBehavior' DESC 'Chaining b
 ehavior control parameters (draft-sermersheim-ldap-chaining)' SYNTAX OMsDirec
 toryString SINGLE-VALUE )
olcAttributeTypes: ( OLcfgOvAt:3.2 NAME 'olcChainCacheURI' DESC 'Enables cachi
 ng of URIs not present in configuration' SYNTAX OMsBoolean SINGLE-VALUE )
olcAttributeTypes: ( OLcfgOvAt:3.3 NAME 'olcChainMaxReferralDepth' DESC 'max r
 eferral depth' EQUALITY integerMatch SYNTAX OMsInteger SINGLE-VALUE )
olcAttributeTypes: ( OLcfgOvAt:3.4 NAME 'olcChainReturnError' DESC 'Errors are
  returned instead of the original referral' SYNTAX OMsBoolean SINGLE-VALUE )
olcAttributeTypes: ( OLcfgDbAt:8.1 NAME 'olcDbBindAllowed' DESC 'Allow binds t
 o this database' SYNTAX OMsBoolean SINGLE-VALUE )
olcAttributeTypes: ( OLcfgDbAt:5.1 NAME 'olcRelay' DESC 'Relay DN' SYNTAX OMsD
 N SINGLE-VALUE )
olcAttributeTypes: ( OLcfgDbAt:7.1 NAME 'olcDbSocketPath' DESC 'Pathname for U
 nix domain socket' EQUALITY caseExactMatch SYNTAX OMsDirectoryString SINGLE-V
 ALUE )
olcAttributeTypes: ( OLcfgDbAt:7.2 NAME 'olcDbSocketExtensions' DESC 'binddn, 
 peername, or ssf' EQUALITY caseIgnoreMatch SYNTAX OMsDirectoryString )
olcAttributeTypes: ( olmBDBAttributes:1 NAME 'olmBDBEntryCache' DESC 'Number o
 f items in Entry Cache' SUP monitorCounter NO-USER-MODIFICATION USAGE dSAOper
 ation )
olcAttributeTypes: ( olmBDBAttributes:2 NAME 'olmBDBDNCache' DESC 'Number of i
 tems in DN Cache' SUP monitorCounter NO-USER-MODIFICATION USAGE dSAOperation 
 )
olcAttributeTypes: ( olmBDBAttributes:3 NAME 'olmBDBIDLCache' DESC 'Number of 
 items in IDL Cache' SUP monitorCounter NO-USER-MODIFICATION USAGE dSAOperatio
 n )
olcAttributeTypes: ( olmBDBAttributes:4 NAME 'olmDbDirectory' DESC 'Path name 
 of the directory where the database environment resides' SUP monitoredInfo NO
 -USER-MODIFICATION USAGE dSAOperation )
olcObjectClasses: ( 2.5.6.0 NAME 'top' DESC 'top of the superclass chain' ABST
 RACT MUST objectClass )
olcObjectClasses: ( 1.3.6.1.4.1.1466.101.120.111 NAME 'extensibleObject' DESC 
 'RFC4512: extensible object' SUP top AUXILIARY )
olcObjectClasses: ( 2.5.6.1 NAME 'alias' DESC 'RFC4512: an alias' SUP top STRU
 CTURAL MUST aliasedObjectName )
olcObjectClasses: ( 2.16.840.1.113730.3.2.6 NAME 'referral' DESC 'namedref: na
 med subordinate referral' SUP top STRUCTURAL MUST ref )
olcObjectClasses: ( 1.3.6.1.4.1.4203.1.4.1 NAME ( 'OpenLDAProotDSE' 'LDAProotD
 SE' ) DESC 'OpenLDAP Root DSE object' SUP top STRUCTURAL MAY cn )
olcObjectClasses: ( 2.5.17.0 NAME 'subentry' DESC 'RFC3672: subentry' SUP top 
 STRUCTURAL MUST ( cn \$ subtreeSpecification ) )
olcObjectClasses: ( 2.5.20.1 NAME 'subschema' DESC 'RFC4512: controlling subsc
 hema (sub)entry' AUXILIARY MAY ( dITStructureRules \$ nameForms \$ dITContentRu
 les \$ objectClasses \$ attributeTypes \$ matchingRules \$ matchingRuleUse ) )
olcObjectClasses: ( 1.3.6.1.4.1.1466.101.119.2 NAME 'dynamicObject' DESC 'RFC2
 589: Dynamic Object' SUP top AUXILIARY )
olcObjectClasses: ( 1.3.6.1.4.1.4203.666.3.4 NAME 'glue' DESC 'Glue Entry' SUP
  top STRUCTURAL )
olcObjectClasses: ( 1.3.6.1.4.1.4203.666.3.5 NAME 'syncConsumerSubentry' DESC 
 'Persistent Info for SyncRepl Consumer' AUXILIARY MAY syncreplCookie )
olcObjectClasses: ( 1.3.6.1.4.1.4203.666.3.6 NAME 'syncProviderSubentry' DESC 
 'Persistent Info for SyncRepl Producer' AUXILIARY MAY contextCSN )
olcObjectClasses: ( OLcfgGlOc:0 NAME 'olcConfig' DESC 'OpenLDAP configuration 
 object' SUP top ABSTRACT )
olcObjectClasses: ( OLcfgGlOc:1 NAME 'olcGlobal' DESC 'OpenLDAP Global configu
 ration options' SUP olcConfig STRUCTURAL MAY ( cn \$ olcConfigFile \$ olcConfig
 Dir \$ olcAllows \$ olcArgsFile \$ olcAttributeOptions \$ olcAuthIDRewrite \$ olcA
 uthzPolicy \$ olcAuthzRegexp \$ olcConcurrency \$ olcConnMaxPending \$ olcConnMax
 PendingAuth \$ olcDisallows \$ olcGentleHUP \$ olcIdleTimeout \$ olcIndexSubstrIf
 MaxLen \$ olcIndexSubstrIfMinLen \$ olcIndexSubstrAnyLen \$ olcIndexSubstrAnySte
 p \$ olcIndexIntLen \$ olcLocalSSF \$ olcLogFile \$ olcLogLevel \$ olcPasswordCryp
 tSaltFormat \$ olcPasswordHash \$ olcPidFile \$ olcPluginLogFile \$ olcReadOnly \$
  olcReferral \$ olcReplogFile \$ olcRequires \$ olcRestrict \$ olcReverseLookup \$
  olcRootDSE \$ olcSaslAuxprops \$ olcSaslHost \$ olcSaslRealm \$ olcSaslSecProps 
 \$ olcSecurity \$ olcServerID \$ olcSizeLimit \$ olcSockbufMaxIncoming \$ olcSockb
 ufMaxIncomingAuth \$ olcTCPBuffer \$ olcThreads \$ olcTimeLimit \$ olcTLSCACertif
 icateFile \$ olcTLSCACertificatePath \$ olcTLSCertificateFile \$ olcTLSCertifica
 teKeyFile \$ olcTLSCipherSuite \$ olcTLSCRLCheck \$ olcTLSRandFile \$ olcTLSVerif
 yClient \$ olcTLSDHParamFile \$ olcTLSCRLFile \$ olcToolThreads \$ olcWriteTimeou
 t \$ olcObjectIdentifier \$ olcAttributeTypes \$ olcObjectClasses \$ olcDitConten
 tRules \$ olcLdapSyntaxes ) )
olcObjectClasses: ( OLcfgGlOc:2 NAME 'olcSchemaConfig' DESC 'OpenLDAP schema o
 bject' SUP olcConfig STRUCTURAL MAY ( cn \$ olcObjectIdentifier \$ olcAttribute
 Types \$ olcObjectClasses \$ olcDitContentRules \$ olcLdapSyntaxes ) )
olcObjectClasses: ( OLcfgGlOc:3 NAME 'olcBackendConfig' DESC 'OpenLDAP Backend
 -specific options' SUP olcConfig STRUCTURAL MUST olcBackend )
olcObjectClasses: ( OLcfgGlOc:4 NAME 'olcDatabaseConfig' DESC 'OpenLDAP Databa
 se-specific options' SUP olcConfig STRUCTURAL MUST olcDatabase MAY ( olcHidde
 n \$ olcSuffix \$ olcSubordinate \$ olcAccess \$ olcAddContentAcl \$ olcLastMod \$ 
 olcLimits \$ olcMaxDerefDepth \$ olcPlugin \$ olcReadOnly \$ olcReplica \$ olcRepl
 icaArgsFile \$ olcReplicaPidFile \$ olcReplicationInterval \$ olcReplogFile \$ ol
 cRequires \$ olcRestrict \$ olcRootDN \$ olcRootPW \$ olcSchemaDN \$ olcSecurity \$
  olcSizeLimit \$ olcSyncUseSubentry \$ olcSyncrepl \$ olcTimeLimit \$ olcUpdateDN
  \$ olcUpdateRef \$ olcMirrorMode \$ olcMonitoring \$ olcExtraAttrs ) )
olcObjectClasses: ( OLcfgGlOc:5 NAME 'olcOverlayConfig' DESC 'OpenLDAP Overlay
 -specific options' SUP olcConfig STRUCTURAL MUST olcOverlay )
olcObjectClasses: ( OLcfgGlOc:6 NAME 'olcIncludeFile' DESC 'OpenLDAP configura
 tion include file' SUP olcConfig STRUCTURAL MUST olcInclude MAY ( cn \$ olcRoo
 tDSE ) )
olcObjectClasses: ( OLcfgGlOc:7 NAME 'olcFrontendConfig' DESC 'OpenLDAP fronte
 nd configuration' AUXILIARY MAY ( olcDefaultSearchBase \$ olcPasswordHash \$ ol
 cSortVals ) )
olcObjectClasses: ( OLcfgGlOc:8 NAME 'olcModuleList' DESC 'OpenLDAP dynamic mo
 dule info' SUP olcConfig STRUCTURAL MAY ( cn \$ olcModulePath \$ olcModuleLoad 
 ) )
olcObjectClasses: ( OLcfgDbOc:2.1 NAME 'olcLdifConfig' DESC 'LDIF backend conf
 iguration' SUP olcDatabaseConfig STRUCTURAL MUST olcDbDirectory )
olcObjectClasses: ( 1.3.6.1.4.1.4203.666.3.16.1 NAME 'monitor' DESC 'OpenLDAP 
 system monitoring' SUP top STRUCTURAL MUST cn MAY ( description \$ seeAlso \$ l
 abeledURI \$ monitoredInfo \$ managedInfo \$ monitorOverlay ) )
olcObjectClasses: ( 1.3.6.1.4.1.4203.666.3.16.2 NAME 'monitorServer' DESC 'Ser
 ver monitoring root entry' SUP monitor STRUCTURAL )
olcObjectClasses: ( 1.3.6.1.4.1.4203.666.3.16.3 NAME 'monitorContainer' DESC '
 monitor container class' SUP monitor STRUCTURAL )
olcObjectClasses: ( 1.3.6.1.4.1.4203.666.3.16.4 NAME 'monitorCounterObject' DE
 SC 'monitor counter class' SUP monitor STRUCTURAL )
olcObjectClasses: ( 1.3.6.1.4.1.4203.666.3.16.5 NAME 'monitorOperation' DESC '
 monitor operation class' SUP monitor STRUCTURAL )
olcObjectClasses: ( 1.3.6.1.4.1.4203.666.3.16.6 NAME 'monitorConnection' DESC 
 'monitor connection class' SUP monitor STRUCTURAL )
olcObjectClasses: ( 1.3.6.1.4.1.4203.666.3.16.7 NAME 'managedObject' DESC 'mon
 itor managed entity class' SUP monitor STRUCTURAL )
olcObjectClasses: ( 1.3.6.1.4.1.4203.666.3.16.8 NAME 'monitoredObject' DESC 'm
 onitor monitored entity class' SUP monitor STRUCTURAL )
olcObjectClasses: ( OLcfgDbOc:4.1 NAME 'olcMonitorConfig' DESC 'Monitor backen
 d configuration' SUP olcDatabaseConfig STRUCTURAL )
olcObjectClasses: ( OLcfgDbOc:1.1 NAME 'olcBdbConfig' DESC 'BDB backend config
 uration' SUP olcDatabaseConfig STRUCTURAL MUST olcDbDirectory MAY ( olcDbCach
 eSize \$ olcDbCheckpoint \$ olcDbConfig \$ olcDbCryptFile \$ olcDbCryptKey \$ olcD
 bNoSync \$ olcDbDirtyRead \$ olcDbIDLcacheSize \$ olcDbIndex \$ olcDbLinearIndex 
 \$ olcDbLockDetect \$ olcDbMode \$ olcDbSearchStack \$ olcDbShmKey \$ olcDbCacheFr
 ee \$ olcDbDNcacheSize \$ olcDbPageSize ) )
olcObjectClasses: ( OLcfgDbOc:1.2 NAME 'olcHdbConfig' DESC 'HDB backend config
 uration' SUP olcDatabaseConfig STRUCTURAL MUST olcDbDirectory MAY ( olcDbCach
 eSize \$ olcDbCheckpoint \$ olcDbConfig \$ olcDbCryptFile \$ olcDbCryptKey \$ olcD
 bNoSync \$ olcDbDirtyRead \$ olcDbIDLcacheSize \$ olcDbIndex \$ olcDbLinearIndex 
 \$ olcDbLockDetect \$ olcDbMode \$ olcDbSearchStack \$ olcDbShmKey \$ olcDbCacheFr
 ee \$ olcDbDNcacheSize \$ olcDbPageSize ) )
olcObjectClasses: ( OLcfgDbOc:3.1 NAME 'olcLDAPConfig' DESC 'LDAP backend conf
 iguration' SUP olcDatabaseConfig STRUCTURAL MAY ( olcDbURI \$ olcDbStartTLS \$ 
 olcDbACLAuthcDn \$ olcDbACLPasswd \$ olcDbACLBind \$ olcDbIDAssertAuthcDn \$ olcD
 bIDAssertPasswd \$ olcDbIDAssertBind \$ olcDbIDAssertMode \$ olcDbIDAssertAuthzF
 rom \$ olcDbIDAssertPassThru \$ olcDbRebindAsUser \$ olcDbChaseReferrals \$ olcDb
 TFSupport \$ olcDbProxyWhoAmI \$ olcDbTimeout \$ olcDbIdleTimeout \$ olcDbConnTtl
  \$ olcDbNetworkTimeout \$ olcDbProtocolVersion \$ olcDbSingleConn \$ olcDbCancel
  \$ olcDbQuarantine \$ olcDbUseTemporaryConn \$ olcDbConnectionPoolMax \$ olcDbNo
 Refs \$ olcDbNoUndefFilter ) )
olcObjectClasses: ( OLcfgOvOc:3.1 NAME 'olcChainConfig' DESC 'Chain configurat
 ion' SUP olcOverlayConfig STRUCTURAL MAY ( olcChainingBehavior \$ olcChainCach
 eURI \$ olcChainMaxReferralDepth \$ olcChainReturnError ) )
olcObjectClasses: ( OLcfgOvOc:3.2 NAME 'olcChainDatabase' DESC 'Chain remote s
 erver configuration' AUXILIARY )
olcObjectClasses: ( OLcfgOvOc:3.3 NAME 'olcPBindConfig' DESC 'Proxy Bind confi
 guration' SUP olcOverlayConfig STRUCTURAL MUST olcDbURI MAY ( olcDbStartTLS \$
  olcDbNetworkTimeout \$ olcDbQuarantine ) )
olcObjectClasses: ( OLcfgOvOc:7.1 NAME 'olcDistProcConfig' DESC 'Distributed p
 rocedures <draft-sermersheim-ldap-distproc> configuration' SUP olcOverlayConf
 ig STRUCTURAL MAY ( olcChainingBehavior \$ olcChainCacheURI ) )
olcObjectClasses: ( OLcfgOvOc:7.2 NAME 'olcDistProcDatabase' DESC 'Distributed
  procedure remote server configuration' AUXILIARY )
olcObjectClasses: ( OLcfgDbOc:8.1 NAME 'olcNullConfig' DESC 'Null backend ocnf
 iguration' SUP olcDatabaseConfig STRUCTURAL MAY olcDbBindAllowed )
olcObjectClasses: ( OLcfgDbOc:5.1 NAME 'olcRelayConfig' DESC 'Relay backend co
 nfiguration' SUP olcDatabaseConfig STRUCTURAL MAY olcRelay )
olcObjectClasses: ( OLcfgDbOc:7.1 NAME 'olcDbSocketConfig' DESC 'Socket backen
 d configuration' SUP olcDatabaseConfig STRUCTURAL MUST olcDbSocketPath MAY ol
 cDbSocketExtensions )
olcObjectClasses: ( olmBDBObjectClasses:1 NAME 'olmBDBDatabase' SUP top AUXILI
 ARY MAY ( olmBDBEntryCache \$ olmBDBDNCache \$ olmBDBIDLCache \$ olmDbDirectory 
 ) )
olcLdapSyntaxes: ( 1.3.6.1.4.1.1466.115.121.1.1 DESC 'ACI Item' X-BINARY-TRANS
 FER-REQUIRED 'TRUE' X-NOT-HUMAN-READABLE 'TRUE' )
olcLdapSyntaxes: ( 1.3.6.1.4.1.1466.115.121.1.2 DESC 'Access Point' X-NOT-HUMA
 N-READABLE 'TRUE' )
olcLdapSyntaxes: ( 1.3.6.1.4.1.1466.115.121.1.3 DESC 'Attribute Type Descripti
 on' )
olcLdapSyntaxes: ( 1.3.6.1.4.1.1466.115.121.1.4 DESC 'Audio' X-NOT-HUMAN-READA
 BLE 'TRUE' )
olcLdapSyntaxes: ( 1.3.6.1.4.1.1466.115.121.1.5 DESC 'Binary' X-NOT-HUMAN-READ
 ABLE 'TRUE' )
olcLdapSyntaxes: ( 1.3.6.1.4.1.1466.115.121.1.6 DESC 'Bit String' )
olcLdapSyntaxes: ( 1.3.6.1.4.1.1466.115.121.1.7 DESC 'Boolean' )
olcLdapSyntaxes: ( 1.3.6.1.4.1.1466.115.121.1.8 DESC 'Certificate' X-BINARY-TR
 ANSFER-REQUIRED 'TRUE' X-NOT-HUMAN-READABLE 'TRUE' )
olcLdapSyntaxes: ( 1.3.6.1.4.1.1466.115.121.1.9 DESC 'Certificate List' X-BINA
 RY-TRANSFER-REQUIRED 'TRUE' X-NOT-HUMAN-READABLE 'TRUE' )
olcLdapSyntaxes: ( 1.3.6.1.4.1.1466.115.121.1.10 DESC 'Certificate Pair' X-BIN
 ARY-TRANSFER-REQUIRED 'TRUE' X-NOT-HUMAN-READABLE 'TRUE' )
olcLdapSyntaxes: ( 1.3.6.1.4.1.4203.666.11.10.2.1 DESC 'X.509 AttributeCertifi
 cate' X-BINARY-TRANSFER-REQUIRED 'TRUE' X-NOT-HUMAN-READABLE 'TRUE' )
olcLdapSyntaxes: ( 1.3.6.1.4.1.1466.115.121.1.12 DESC 'Distinguished Name' )
olcLdapSyntaxes: ( 1.2.36.79672281.1.5.0 DESC 'RDN' )
olcLdapSyntaxes: ( 1.3.6.1.4.1.1466.115.121.1.13 DESC 'Data Quality' )
olcLdapSyntaxes: ( 1.3.6.1.4.1.1466.115.121.1.14 DESC 'Delivery Method' )
olcLdapSyntaxes: ( 1.3.6.1.4.1.1466.115.121.1.15 DESC 'Directory String' )
olcLdapSyntaxes: ( 1.3.6.1.4.1.1466.115.121.1.16 DESC 'DIT Content Rule Descri
 ption' )
olcLdapSyntaxes: ( 1.3.6.1.4.1.1466.115.121.1.17 DESC 'DIT Structure Rule Desc
 ription' )
olcLdapSyntaxes: ( 1.3.6.1.4.1.1466.115.121.1.19 DESC 'DSA Quality' )
olcLdapSyntaxes: ( 1.3.6.1.4.1.1466.115.121.1.20 DESC 'DSE Type' )
olcLdapSyntaxes: ( 1.3.6.1.4.1.1466.115.121.1.21 DESC 'Enhanced Guide' )
olcLdapSyntaxes: ( 1.3.6.1.4.1.1466.115.121.1.22 DESC 'Facsimile Telephone Num
 ber' )
olcLdapSyntaxes: ( 1.3.6.1.4.1.1466.115.121.1.23 DESC 'Fax' X-NOT-HUMAN-READAB
 LE 'TRUE' )
olcLdapSyntaxes: ( 1.3.6.1.4.1.1466.115.121.1.24 DESC 'Generalized Time' )
olcLdapSyntaxes: ( 1.3.6.1.4.1.1466.115.121.1.25 DESC 'Guide' )
olcLdapSyntaxes: ( 1.3.6.1.4.1.1466.115.121.1.26 DESC 'IA5 String' )
olcLdapSyntaxes: ( 1.3.6.1.4.1.1466.115.121.1.27 DESC 'Integer' )
olcLdapSyntaxes: ( 1.3.6.1.4.1.1466.115.121.1.28 DESC 'JPEG' X-NOT-HUMAN-READA
 BLE 'TRUE' )
olcLdapSyntaxes: ( 1.3.6.1.4.1.1466.115.121.1.29 DESC 'Master And Shadow Acces
 s Points' )
olcLdapSyntaxes: ( 1.3.6.1.4.1.1466.115.121.1.30 DESC 'Matching Rule Descripti
 on' )
olcLdapSyntaxes: ( 1.3.6.1.4.1.1466.115.121.1.31 DESC 'Matching Rule Use Descr
 iption' )
olcLdapSyntaxes: ( 1.3.6.1.4.1.1466.115.121.1.32 DESC 'Mail Preference' )
olcLdapSyntaxes: ( 1.3.6.1.4.1.1466.115.121.1.33 DESC 'MHS OR Address' )
olcLdapSyntaxes: ( 1.3.6.1.4.1.1466.115.121.1.34 DESC 'Name And Optional UID' 
 )
olcLdapSyntaxes: ( 1.3.6.1.4.1.1466.115.121.1.35 DESC 'Name Form Description' 
 )
olcLdapSyntaxes: ( 1.3.6.1.4.1.1466.115.121.1.36 DESC 'Numeric String' )
olcLdapSyntaxes: ( 1.3.6.1.4.1.1466.115.121.1.37 DESC 'Object Class Descriptio
 n' )
olcLdapSyntaxes: ( 1.3.6.1.4.1.1466.115.121.1.38 DESC 'OID' )
olcLdapSyntaxes: ( 1.3.6.1.4.1.1466.115.121.1.39 DESC 'Other Mailbox' )
olcLdapSyntaxes: ( 1.3.6.1.4.1.1466.115.121.1.40 DESC 'Octet String' )
olcLdapSyntaxes: ( 1.3.6.1.4.1.1466.115.121.1.41 DESC 'Postal Address' )
olcLdapSyntaxes: ( 1.3.6.1.4.1.1466.115.121.1.42 DESC 'Protocol Information' )
olcLdapSyntaxes: ( 1.3.6.1.4.1.1466.115.121.1.43 DESC 'Presentation Address' )
olcLdapSyntaxes: ( 1.3.6.1.4.1.1466.115.121.1.44 DESC 'Printable String' )
olcLdapSyntaxes: ( 1.3.6.1.4.1.1466.115.121.1.11 DESC 'Country String' )
olcLdapSyntaxes: ( 1.3.6.1.4.1.1466.115.121.1.45 DESC 'SubtreeSpecification' )
olcLdapSyntaxes: ( 1.3.6.1.4.1.1466.115.121.1.49 DESC 'Supported Algorithm' X-
 BINARY-TRANSFER-REQUIRED 'TRUE' X-NOT-HUMAN-READABLE 'TRUE' )
olcLdapSyntaxes: ( 1.3.6.1.4.1.1466.115.121.1.50 DESC 'Telephone Number' )
olcLdapSyntaxes: ( 1.3.6.1.4.1.1466.115.121.1.51 DESC 'Teletex Terminal Identi
 fier' )
olcLdapSyntaxes: ( 1.3.6.1.4.1.1466.115.121.1.52 DESC 'Telex Number' )
olcLdapSyntaxes: ( 1.3.6.1.4.1.1466.115.121.1.54 DESC 'LDAP Syntax Description
 ' )
olcLdapSyntaxes: ( 1.3.6.1.4.1.1466.115.121.1.55 DESC 'Modify Rights' )
olcLdapSyntaxes: ( 1.3.6.1.4.1.1466.115.121.1.56 DESC 'LDAP Schema Definition'
  )
olcLdapSyntaxes: ( 1.3.6.1.4.1.1466.115.121.1.57 DESC 'LDAP Schema Description
 ' )
olcLdapSyntaxes: ( 1.3.6.1.4.1.1466.115.121.1.58 DESC 'Substring Assertion' )
olcLdapSyntaxes: ( 1.3.6.1.1.1.0.0 DESC 'RFC2307 NIS Netgroup Triple' )
olcLdapSyntaxes: ( 1.3.6.1.1.1.0.1 DESC 'RFC2307 Boot Parameter' )
olcLdapSyntaxes: ( 1.3.6.1.1.15.1 DESC 'Certificate Exact Assertion' )
olcLdapSyntaxes: ( 1.3.6.1.1.15.2 DESC 'Certificate Assertion' )
olcLdapSyntaxes: ( 1.3.6.1.1.15.3 DESC 'Certificate Pair Exact Assertion' )
olcLdapSyntaxes: ( 1.3.6.1.1.15.4 DESC 'Certificate Pair Assertion' )
olcLdapSyntaxes: ( 1.3.6.1.1.15.5 DESC 'Certificate List Exact Assertion' )
olcLdapSyntaxes: ( 1.3.6.1.1.15.6 DESC 'Certificate List Assertion' )
olcLdapSyntaxes: ( 1.3.6.1.1.15.7 DESC 'Algorithm Identifier' )
olcLdapSyntaxes: ( 1.3.6.1.4.1.4203.666.11.10.2.2 DESC 'AttributeCertificate E
 xact Assertion' )
olcLdapSyntaxes: ( 1.3.6.1.4.1.4203.666.11.10.2.3 DESC 'AttributeCertificate A
 ssertion' )
olcLdapSyntaxes: ( 1.3.6.1.1.16.1 DESC 'UUID' )
olcLdapSyntaxes: ( 1.3.6.1.4.1.4203.666.11.2.1 DESC 'CSN' )
olcLdapSyntaxes: ( 1.3.6.1.4.1.4203.666.11.2.4 DESC 'CSN SID' )
olcLdapSyntaxes: ( 1.3.6.1.4.1.4203.1.1.1 DESC 'OpenLDAP void' )
olcLdapSyntaxes: ( 1.3.6.1.4.1.4203.666.2.7 DESC 'OpenLDAP authz' )
structuralObjectClass: olcSchemaConfig
entryUUID: $uuid
creatorsName: cn=config
createTimestamp: $create_timestamp
entryCSN: $entry_csn
modifiersName: cn=config
modifyTimestamp: $create_timestamp
__SCHEMA_LDIF__
    close $handle
      or
      Carp::croak("Failed to close '$self->{cn_schema_ldif_path}':$OS_ERROR");
    return;
}

sub _create_schema_core_ldif {
    my ($self)      = @_;
    my $write_flags = Fcntl::O_WRONLY() | Fcntl::O_CREAT() | Fcntl::O_EXCL();
    my $uuid        = lc $self->_uuid();
    my $entry_csn   = $self->_entry_csn();
    my $create_timestamp = POSIX::strftime( '%Y%m%d%H%M%SZ', gmtime time );
    my $handle = FileHandle->new( $self->{cn_schema_core_ldif_path},
        $write_flags, oct USER_READ_WRITE_PERMISSIONS() )
      or Carp::croak(
"Failed to open '$self->{cn_schema_core_ldif_path}' for writing:$OS_ERROR"
      );
    $handle->print(
        <<"__SCHEMA_CORE_LDIF__") or Carp::croak("Failed to write to '$self->{cn_schema_core_ldif_path}':$OS_ERROR");
dn: cn={1}core
objectClass: olcSchemaConfig
cn: {1}core
olcAttributeTypes: {0}( 2.5.4.2 NAME 'knowledgeInformation' DESC 'RFC2256: kno
 wledge information' EQUALITY caseIgnoreMatch SYNTAX 1.3.6.1.4.1.1466.115.121.
 1.15{32768} )
olcAttributeTypes: {1}( 2.5.4.4 NAME ( 'sn' 'surname' ) DESC 'RFC2256: last (f
 amily) name(s) for which the entity is known by' SUP name )
olcAttributeTypes: {2}( 2.5.4.5 NAME 'serialNumber' DESC 'RFC2256: serial numb
 er of the entity' EQUALITY caseIgnoreMatch SUBSTR caseIgnoreSubstringsMatch S
 YNTAX 1.3.6.1.4.1.1466.115.121.1.44{64} )
olcAttributeTypes: {3}( 2.5.4.6 NAME ( 'c' 'countryName' ) DESC 'RFC4519: two-
 letter ISO-3166 country code' SUP name SYNTAX 1.3.6.1.4.1.1466.115.121.1.11 S
 INGLE-VALUE )
olcAttributeTypes: {4}( 2.5.4.7 NAME ( 'l' 'localityName' ) DESC 'RFC2256: loc
 ality which this object resides in' SUP name )
olcAttributeTypes: {5}( 2.5.4.8 NAME ( 'st' 'stateOrProvinceName' ) DESC 'RFC2
 256: state or province which this object resides in' SUP name )
olcAttributeTypes: {6}( 2.5.4.9 NAME ( 'street' 'streetAddress' ) DESC 'RFC225
 6: street address of this object' EQUALITY caseIgnoreMatch SUBSTR caseIgnoreS
 ubstringsMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.15{128} )
olcAttributeTypes: {7}( 2.5.4.10 NAME ( 'o' 'organizationName' ) DESC 'RFC2256
 : organization this object belongs to' SUP name )
olcAttributeTypes: {8}( 2.5.4.11 NAME ( 'ou' 'organizationalUnitName' ) DESC '
 RFC2256: organizational unit this object belongs to' SUP name )
olcAttributeTypes: {9}( 2.5.4.12 NAME 'title' DESC 'RFC2256: title associated 
 with the entity' SUP name )
olcAttributeTypes: {10}( 2.5.4.14 NAME 'searchGuide' DESC 'RFC2256: search gui
 de, deprecated by enhancedSearchGuide' SYNTAX 1.3.6.1.4.1.1466.115.121.1.25 )
olcAttributeTypes: {11}( 2.5.4.15 NAME 'businessCategory' DESC 'RFC2256: busin
 ess category' EQUALITY caseIgnoreMatch SUBSTR caseIgnoreSubstringsMatch SYNTA
 X 1.3.6.1.4.1.1466.115.121.1.15{128} )
olcAttributeTypes: {12}( 2.5.4.16 NAME 'postalAddress' DESC 'RFC2256: postal a
 ddress' EQUALITY caseIgnoreListMatch SUBSTR caseIgnoreListSubstringsMatch SYN
 TAX 1.3.6.1.4.1.1466.115.121.1.41 )
olcAttributeTypes: {13}( 2.5.4.17 NAME 'postalCode' DESC 'RFC2256: postal code
 ' EQUALITY caseIgnoreMatch SUBSTR caseIgnoreSubstringsMatch SYNTAX 1.3.6.1.4.
 1.1466.115.121.1.15{40} )
olcAttributeTypes: {14}( 2.5.4.18 NAME 'postOfficeBox' DESC 'RFC2256: Post Off
 ice Box' EQUALITY caseIgnoreMatch SUBSTR caseIgnoreSubstringsMatch SYNTAX 1.3
 .6.1.4.1.1466.115.121.1.15{40} )
olcAttributeTypes: {15}( 2.5.4.19 NAME 'physicalDeliveryOfficeName' DESC 'RFC2
 256: Physical Delivery Office Name' EQUALITY caseIgnoreMatch SUBSTR caseIgnor
 eSubstringsMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.15{128} )
olcAttributeTypes: {16}( 2.5.4.20 NAME 'telephoneNumber' DESC 'RFC2256: Teleph
 one Number' EQUALITY telephoneNumberMatch SUBSTR telephoneNumberSubstringsMat
 ch SYNTAX 1.3.6.1.4.1.1466.115.121.1.50{32} )
olcAttributeTypes: {17}( 2.5.4.21 NAME 'telexNumber' DESC 'RFC2256: Telex Numb
 er' SYNTAX 1.3.6.1.4.1.1466.115.121.1.52 )
olcAttributeTypes: {18}( 2.5.4.22 NAME 'teletexTerminalIdentifier' DESC 'RFC22
 56: Teletex Terminal Identifier' SYNTAX 1.3.6.1.4.1.1466.115.121.1.51 )
olcAttributeTypes: {19}( 2.5.4.23 NAME ( 'facsimileTelephoneNumber' 'fax' ) DE
 SC 'RFC2256: Facsimile (Fax) Telephone Number' SYNTAX 1.3.6.1.4.1.1466.115.12
 1.1.22 )
olcAttributeTypes: {20}( 2.5.4.24 NAME 'x121Address' DESC 'RFC2256: X.121 Addr
 ess' EQUALITY numericStringMatch SUBSTR numericStringSubstringsMatch SYNTAX 1
 .3.6.1.4.1.1466.115.121.1.36{15} )
olcAttributeTypes: {21}( 2.5.4.25 NAME 'internationaliSDNNumber' DESC 'RFC2256
 : international ISDN number' EQUALITY numericStringMatch SUBSTR numericString
 SubstringsMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.36{16} )
olcAttributeTypes: {22}( 2.5.4.26 NAME 'registeredAddress' DESC 'RFC2256: regi
 stered postal address' SUP postalAddress SYNTAX 1.3.6.1.4.1.1466.115.121.1.41
  )
olcAttributeTypes: {23}( 2.5.4.27 NAME 'destinationIndicator' DESC 'RFC2256: d
 estination indicator' EQUALITY caseIgnoreMatch SUBSTR caseIgnoreSubstringsMat
 ch SYNTAX 1.3.6.1.4.1.1466.115.121.1.44{128} )
olcAttributeTypes: {24}( 2.5.4.28 NAME 'preferredDeliveryMethod' DESC 'RFC2256
 : preferred delivery method' SYNTAX 1.3.6.1.4.1.1466.115.121.1.14 SINGLE-VALU
 E )
olcAttributeTypes: {25}( 2.5.4.29 NAME 'presentationAddress' DESC 'RFC2256: pr
 esentation address' EQUALITY presentationAddressMatch SYNTAX 1.3.6.1.4.1.1466
 .115.121.1.43 SINGLE-VALUE )
olcAttributeTypes: {26}( 2.5.4.30 NAME 'supportedApplicationContext' DESC 'RFC
 2256: supported application context' EQUALITY objectIdentifierMatch SYNTAX 1.
 3.6.1.4.1.1466.115.121.1.38 )
olcAttributeTypes: {27}( 2.5.4.31 NAME 'member' DESC 'RFC2256: member of a gro
 up' SUP distinguishedName )
olcAttributeTypes: {28}( 2.5.4.32 NAME 'owner' DESC 'RFC2256: owner (of the ob
 ject)' SUP distinguishedName )
olcAttributeTypes: {29}( 2.5.4.33 NAME 'roleOccupant' DESC 'RFC2256: occupant 
 of role' SUP distinguishedName )
olcAttributeTypes: {30}( 2.5.4.36 NAME 'userCertificate' DESC 'RFC2256: X.509 
 user certificate, use ;binary' EQUALITY certificateExactMatch SYNTAX 1.3.6.1.
 4.1.1466.115.121.1.8 )
olcAttributeTypes: {31}( 2.5.4.37 NAME 'cACertificate' DESC 'RFC2256: X.509 CA
  certificate, use ;binary' EQUALITY certificateExactMatch SYNTAX 1.3.6.1.4.1.
 1466.115.121.1.8 )
olcAttributeTypes: {32}( 2.5.4.38 NAME 'authorityRevocationList' DESC 'RFC2256
 : X.509 authority revocation list, use ;binary' SYNTAX 1.3.6.1.4.1.1466.115.1
 21.1.9 )
olcAttributeTypes: {33}( 2.5.4.39 NAME 'certificateRevocationList' DESC 'RFC22
 56: X.509 certificate revocation list, use ;binary' SYNTAX 1.3.6.1.4.1.1466.1
 15.121.1.9 )
olcAttributeTypes: {34}( 2.5.4.40 NAME 'crossCertificatePair' DESC 'RFC2256: X
 .509 cross certificate pair, use ;binary' SYNTAX 1.3.6.1.4.1.1466.115.121.1.1
 0 )
olcAttributeTypes: {35}( 2.5.4.42 NAME ( 'givenName' 'gn' ) DESC 'RFC2256: fir
 st name(s) for which the entity is known by' SUP name )
olcAttributeTypes: {36}( 2.5.4.43 NAME 'initials' DESC 'RFC2256: initials of s
 ome or all of names, but not the surname(s).' SUP name )
olcAttributeTypes: {37}( 2.5.4.44 NAME 'generationQualifier' DESC 'RFC2256: na
 me qualifier indicating a generation' SUP name )
olcAttributeTypes: {38}( 2.5.4.45 NAME 'x500UniqueIdentifier' DESC 'RFC2256: X
 .500 unique identifier' EQUALITY bitStringMatch SYNTAX 1.3.6.1.4.1.1466.115.1
 21.1.6 )
olcAttributeTypes: {39}( 2.5.4.46 NAME 'dnQualifier' DESC 'RFC2256: DN qualifi
 er' EQUALITY caseIgnoreMatch ORDERING caseIgnoreOrderingMatch SUBSTR caseIgno
 reSubstringsMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.44 )
olcAttributeTypes: {40}( 2.5.4.47 NAME 'enhancedSearchGuide' DESC 'RFC2256: en
 hanced search guide' SYNTAX 1.3.6.1.4.1.1466.115.121.1.21 )
olcAttributeTypes: {41}( 2.5.4.48 NAME 'protocolInformation' DESC 'RFC2256: pr
 otocol information' EQUALITY protocolInformationMatch SYNTAX 1.3.6.1.4.1.1466
 .115.121.1.42 )
olcAttributeTypes: {42}( 2.5.4.50 NAME 'uniqueMember' DESC 'RFC2256: unique me
 mber of a group' EQUALITY uniqueMemberMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1
 .34 )
olcAttributeTypes: {43}( 2.5.4.51 NAME 'houseIdentifier' DESC 'RFC2256: house 
 identifier' EQUALITY caseIgnoreMatch SUBSTR caseIgnoreSubstringsMatch SYNTAX 
 1.3.6.1.4.1.1466.115.121.1.15{32768} )
olcAttributeTypes: {44}( 2.5.4.52 NAME 'supportedAlgorithms' DESC 'RFC2256: su
 pported algorithms' SYNTAX 1.3.6.1.4.1.1466.115.121.1.49 )
olcAttributeTypes: {45}( 2.5.4.53 NAME 'deltaRevocationList' DESC 'RFC2256: de
 lta revocation list; use ;binary' SYNTAX 1.3.6.1.4.1.1466.115.121.1.9 )
olcAttributeTypes: {46}( 2.5.4.54 NAME 'dmdName' DESC 'RFC2256: name of DMD' S
 UP name )
olcAttributeTypes: {47}( 2.5.4.65 NAME 'pseudonym' DESC 'X.520(4th): pseudonym
  for the object' SUP name )
olcAttributeTypes: {48}( 0.9.2342.19200300.100.1.3 NAME ( 'mail' 'rfc822Mailbo
 x' ) DESC 'RFC1274: RFC822 Mailbox' EQUALITY caseIgnoreIA5Match SUBSTR caseIg
 noreIA5SubstringsMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.26{256} )
olcAttributeTypes: {49}( 0.9.2342.19200300.100.1.25 NAME ( 'dc' 'domainCompone
 nt' ) DESC 'RFC1274/2247: domain component' EQUALITY caseIgnoreIA5Match SUBST
 R caseIgnoreIA5SubstringsMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.26 SINGLE-VA
 LUE )
olcAttributeTypes: {50}( 0.9.2342.19200300.100.1.37 NAME 'associatedDomain' DE
 SC 'RFC1274: domain associated with object' EQUALITY caseIgnoreIA5Match SUBST
 R caseIgnoreIA5SubstringsMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.26 )
olcAttributeTypes: {51}( 1.2.840.113549.1.9.1 NAME ( 'email' 'emailAddress' 'p
 kcs9email' ) DESC 'RFC3280: legacy attribute for email addresses in DNs' EQUA
 LITY caseIgnoreIA5Match SUBSTR caseIgnoreIA5SubstringsMatch SYNTAX 1.3.6.1.4.
 1.1466.115.121.1.26{128} )
olcObjectClasses: {0}( 2.5.6.2 NAME 'country' DESC 'RFC2256: a country' SUP to
 p STRUCTURAL MUST c MAY ( searchGuide \$ description ) )
olcObjectClasses: {1}( 2.5.6.3 NAME 'locality' DESC 'RFC2256: a locality' SUP 
 top STRUCTURAL MAY ( street \$ seeAlso \$ searchGuide \$ st \$ l \$ description ) 
 )
olcObjectClasses: {2}( 2.5.6.4 NAME 'organization' DESC 'RFC2256: an organizat
 ion' SUP top STRUCTURAL MUST o MAY ( userPassword \$ searchGuide \$ seeAlso \$ b
 usinessCategory \$ x121Address \$ registeredAddress \$ destinationIndicator \$ pr
 eferredDeliveryMethod \$ telexNumber \$ teletexTerminalIdentifier \$ telephoneNu
 mber \$ internationaliSDNNumber \$ facsimileTelephoneNumber \$ street \$ postOffi
 ceBox \$ postalCode \$ postalAddress \$ physicalDeliveryOfficeName \$ st \$ l \$ de
 scription ) )
olcObjectClasses: {3}( 2.5.6.5 NAME 'organizationalUnit' DESC 'RFC2256: an org
 anizational unit' SUP top STRUCTURAL MUST ou MAY ( userPassword \$ searchGuide
  \$ seeAlso \$ businessCategory \$ x121Address \$ registeredAddress \$ destination
 Indicator \$ preferredDeliveryMethod \$ telexNumber \$ teletexTerminalIdentifier
  \$ telephoneNumber \$ internationaliSDNNumber \$ facsimileTelephoneNumber \$ str
 eet \$ postOfficeBox \$ postalCode \$ postalAddress \$ physicalDeliveryOfficeName
  \$ st \$ l \$ description ) )
olcObjectClasses: {4}( 2.5.6.6 NAME 'person' DESC 'RFC2256: a person' SUP top 
 STRUCTURAL MUST ( sn \$ cn ) MAY ( userPassword \$ telephoneNumber \$ seeAlso \$ 
 description ) )
olcObjectClasses: {5}( 2.5.6.7 NAME 'organizationalPerson' DESC 'RFC2256: an o
 rganizational person' SUP person STRUCTURAL MAY ( title \$ x121Address \$ regis
 teredAddress \$ destinationIndicator \$ preferredDeliveryMethod \$ telexNumber \$
  teletexTerminalIdentifier \$ telephoneNumber \$ internationaliSDNNumber \$ facs
 imileTelephoneNumber \$ street \$ postOfficeBox \$ postalCode \$ postalAddress \$ 
 physicalDeliveryOfficeName \$ ou \$ st \$ l ) )
olcObjectClasses: {6}( 2.5.6.8 NAME 'organizationalRole' DESC 'RFC2256: an org
 anizational role' SUP top STRUCTURAL MUST cn MAY ( x121Address \$ registeredAd
 dress \$ destinationIndicator \$ preferredDeliveryMethod \$ telexNumber \$ telete
 xTerminalIdentifier \$ telephoneNumber \$ internationaliSDNNumber \$ facsimileTe
 lephoneNumber \$ seeAlso \$ roleOccupant \$ preferredDeliveryMethod \$ street \$ p
 ostOfficeBox \$ postalCode \$ postalAddress \$ physicalDeliveryOfficeName \$ ou \$
  st \$ l \$ description ) )
olcObjectClasses: {7}( 2.5.6.9 NAME 'groupOfNames' DESC 'RFC2256: a group of n
 ames (DNs)' SUP top STRUCTURAL MUST ( member \$ cn ) MAY ( businessCategory \$ 
 seeAlso \$ owner \$ ou \$ o \$ description ) )
olcObjectClasses: {8}( 2.5.6.10 NAME 'residentialPerson' DESC 'RFC2256: an res
 idential person' SUP person STRUCTURAL MUST l MAY ( businessCategory \$ x121Ad
 dress \$ registeredAddress \$ destinationIndicator \$ preferredDeliveryMethod \$ 
 telexNumber \$ teletexTerminalIdentifier \$ telephoneNumber \$ internationaliSDN
 Number \$ facsimileTelephoneNumber \$ preferredDeliveryMethod \$ street \$ postOf
 ficeBox \$ postalCode \$ postalAddress \$ physicalDeliveryOfficeName \$ st \$ l ) 
 )
olcObjectClasses: {9}( 2.5.6.11 NAME 'applicationProcess' DESC 'RFC2256: an ap
 plication process' SUP top STRUCTURAL MUST cn MAY ( seeAlso \$ ou \$ l \$ descri
 ption ) )
olcObjectClasses: {10}( 2.5.6.12 NAME 'applicationEntity' DESC 'RFC2256: an ap
 plication entity' SUP top STRUCTURAL MUST ( presentationAddress \$ cn ) MAY ( 
 supportedApplicationContext \$ seeAlso \$ ou \$ o \$ l \$ description ) )
olcObjectClasses: {11}( 2.5.6.13 NAME 'dSA' DESC 'RFC2256: a directory system 
 agent (a server)' SUP applicationEntity STRUCTURAL MAY knowledgeInformation )
olcObjectClasses: {12}( 2.5.6.14 NAME 'device' DESC 'RFC2256: a device' SUP to
 p STRUCTURAL MUST cn MAY ( serialNumber \$ seeAlso \$ owner \$ ou \$ o \$ l \$ desc
 ription ) )
olcObjectClasses: {13}( 2.5.6.15 NAME 'strongAuthenticationUser' DESC 'RFC2256
 : a strong authentication user' SUP top AUXILIARY MUST userCertificate )
olcObjectClasses: {14}( 2.5.6.16 NAME 'certificationAuthority' DESC 'RFC2256: 
 a certificate authority' SUP top AUXILIARY MUST ( authorityRevocationList \$ c
 ertificateRevocationList \$ cACertificate ) MAY crossCertificatePair )
olcObjectClasses: {15}( 2.5.6.17 NAME 'groupOfUniqueNames' DESC 'RFC2256: a gr
 oup of unique names (DN and Unique Identifier)' SUP top STRUCTURAL MUST ( uni
 queMember \$ cn ) MAY ( businessCategory \$ seeAlso \$ owner \$ ou \$ o \$ descript
 ion ) )
olcObjectClasses: {16}( 2.5.6.18 NAME 'userSecurityInformation' DESC 'RFC2256:
  a user security information' SUP top AUXILIARY MAY supportedAlgorithms )
olcObjectClasses: {17}( 2.5.6.16.2 NAME 'certificationAuthority-V2' SUP certif
 icationAuthority AUXILIARY MAY deltaRevocationList )
olcObjectClasses: {18}( 2.5.6.19 NAME 'cRLDistributionPoint' SUP top STRUCTURA
 L MUST cn MAY ( certificateRevocationList \$ authorityRevocationList \$ deltaRe
 vocationList ) )
olcObjectClasses: {19}( 2.5.6.20 NAME 'dmd' SUP top STRUCTURAL MUST dmdName MA
 Y ( userPassword \$ searchGuide \$ seeAlso \$ businessCategory \$ x121Address \$ r
 egisteredAddress \$ destinationIndicator \$ preferredDeliveryMethod \$ telexNumb
 er \$ teletexTerminalIdentifier \$ telephoneNumber \$ internationaliSDNNumber \$ 
 facsimileTelephoneNumber \$ street \$ postOfficeBox \$ postalCode \$ postalAddres
 s \$ physicalDeliveryOfficeName \$ st \$ l \$ description ) )
olcObjectClasses: {20}( 2.5.6.21 NAME 'pkiUser' DESC 'RFC2587: a PKI user' SUP
  top AUXILIARY MAY userCertificate )
olcObjectClasses: {21}( 2.5.6.22 NAME 'pkiCA' DESC 'RFC2587: PKI certificate a
 uthority' SUP top AUXILIARY MAY ( authorityRevocationList \$ certificateRevoca
 tionList \$ cACertificate \$ crossCertificatePair ) )
olcObjectClasses: {22}( 2.5.6.23 NAME 'deltaCRL' DESC 'RFC2587: PKI user' SUP 
 top AUXILIARY MAY deltaRevocationList )
olcObjectClasses: {23}( 1.3.6.1.4.1.250.3.15 NAME 'labeledURIObject' DESC 'RFC
 2079: object that contains the URI attribute type' SUP top AUXILIARY MAY labe
 ledURI )
olcObjectClasses: {24}( 0.9.2342.19200300.100.4.19 NAME 'simpleSecurityObject'
  DESC 'RFC1274: simple security object' SUP top AUXILIARY MUST userPassword )
olcObjectClasses: {25}( 1.3.6.1.4.1.1466.344 NAME 'dcObject' DESC 'RFC2247: do
 main component object' SUP top AUXILIARY MUST dc )
olcObjectClasses: {26}( 1.3.6.1.1.3.1 NAME 'uidObject' DESC 'RFC2377: uid obje
 ct' SUP top AUXILIARY MUST uid )
structuralObjectClass: olcSchemaConfig
entryUUID: $uuid
creatorsName: cn=config
createTimestamp: $create_timestamp
entryCSN: $entry_csn
modifiersName: cn=config
modifyTimestamp: $create_timestamp
__SCHEMA_CORE_LDIF__
    close $handle
      or Carp::croak(
        "Failed to close '$self->{cn_schema_core_ldif_path}':$OS_ERROR");
    return;
}

sub _create_olc_database_config {
    my ($self)      = @_;
    my $write_flags = Fcntl::O_WRONLY() | Fcntl::O_CREAT() | Fcntl::O_EXCL();
    my $uuid        = lc $self->_uuid();
    my $entry_csn   = $self->_entry_csn();
    my ( $uid, $gid ) =
      ( getpwuid $EFFECTIVE_USER_ID )[ UID_INDEX(), GID_INDEX() ];
    my $create_timestamp = POSIX::strftime( '%Y%m%d%H%M%SZ', gmtime time );
    my $handle = FileHandle->new( $self->{olc_database_config_path},
        $write_flags, oct USER_READ_WRITE_PERMISSIONS() )
      or Carp::croak(
"Failed to open '$self-{olc_database_config_path}' for writing:$OS_ERROR"
      );
    my $user = $self->admin_user();
    $handle->print(
        <<"__DB_CONFIG_LDIF__") or Carp::croak("Failed to write to '$self->{olc_database_config_path}':$OS_ERROR");
dn: $self->{config_database_rdn}
objectClass: olcDatabaseConfig
olcDatabase: $self->{olc_database_for_config}
olcAddContentAcl: TRUE
olcLastMod: TRUE
olcMaxDerefDepth: 15
olcReadOnly: FALSE
olcRootDN: $user
olcAccess: to * by * read
olcSyncUseSubentry: FALSE
olcMonitoring: FALSE
structuralObjectClass: olcDatabaseConfig
entryUUID: $uuid
creatorsName: cn=config
createTimestamp: $create_timestamp
entryCSN: $entry_csn
modifiersName: cn=config
modifyTimestamp: $create_timestamp
__DB_CONFIG_LDIF__
    close $handle
      or Carp::croak(
        "Failed to close '$self->{olc_database_config_path}':$OS_ERROR");
    return;
}

sub _create_olc_database_hdb {
    my ($self)      = @_;
    my $write_flags = Fcntl::O_WRONLY() | Fcntl::O_CREAT() | Fcntl::O_EXCL();
    my $uuid        = lc $self->_uuid();
    my $entry_csn   = $self->_entry_csn();
    my $create_timestamp = POSIX::strftime( '%Y%m%d%H%M%SZ', gmtime time );
    my ( $uid, $gid ) =
      ( getpwuid $EFFECTIVE_USER_ID )[ UID_INDEX(), GID_INDEX() ];
    my $handle = FileHandle->new( $self->{olc_database_hdb_path},
        $write_flags, oct USER_READ_WRITE_PERMISSIONS() )
      or Carp::croak(
        "Failed to open '$self->{olc_database_hdb_path}' for writing:$OS_ERROR"
      );
    my $user     = $self->admin_user();
    my $suffix   = $self->suffix();
    my $password = $self->admin_password();
    $handle->print(
        <<"__DB_LDIF__") or Carp::croak("Failed to write to '$self->{olc_database_hdb_path}':$OS_ERROR");
dn: $self->{database_hdb_rdn}
objectClass: olcDatabaseConfig
objectClass: olcHdbConfig
olcDatabase: $self->{olc_database_for_hdb}
olcAddContentAcl: FALSE
olcLastMod: TRUE
olcMaxDerefDepth: 15
olcReadOnly: FALSE
olcSyncUseSubentry: FALSE
olcMonitoring: TRUE
olcDbDirectory: $self->{db_directory}
olcDbCacheSize: 1000
olcDbCheckpoint: 1024 15
olcDbNoSync: FALSE
olcDbDirtyRead: FALSE
olcDbIDLcacheSize: 0
olcDbLinearIndex: FALSE
olcDbMode: 0600
olcDbSearchStack: 16
olcDbShmKey: 0
olcDbCacheFree: 1
olcDbDNcacheSize: 0
structuralObjectClass: olcHdbConfig
entryUUID: $uuid
creatorsName: cn=config
createTimestamp: $create_timestamp
olcSuffix: $suffix
olcRootDN: $user
olcRootPW: ${password}
olcAccess: to * by * read
entryCSN: $entry_csn
modifiersName: cn=config
modifyTimestamp: $create_timestamp
__DB_LDIF__
    close $handle
      or
      Carp::croak("Failed to close '$self->{olc_database_hdb_path}':$OS_ERROR");
    return;
}

sub _remove_db_directory {
    my ($self) = @_;
    unlink $self->{olc_database_hdb_path}
      or ( $OS_ERROR == POSIX::ENOENT() )
      or Carp::croak(
        "Failed to unlink '$self->{olc_database_hdb_path}':$OS_ERROR");
    my $db_handle = DirHandle->new( $self->{db_directory} );
    if ($db_handle) {
        while ( my $entry = $db_handle->read() ) {
            next if ( $entry eq File::Spec->curdir() );
            next if ( $entry eq File::Spec->updir() );
            if ( $entry =~ /^(\w+[.]\w+|\w+)$/smx ) {
                my $path = "$self->{db_directory}/$1";
                unlink $path
                  or Carp::croak("Failed to unlink '$path':$OS_ERROR");
            }
        }
        $db_handle->close()
          or Carp::croak(
            "Failed to close directory '$self->{db_directory}':$OS_ERROR");
    }
    elsif ( $OS_ERROR != POSIX::ENOENT() ) {
        Carp::croak(
            "Failed to open directory '$self->{db_directory}':$OS_ERROR");
    }
    rmdir $self->{db_directory}
      or ( $OS_ERROR == POSIX::ENOENT() )
      or Carp::croak("Failed to rmdir '$self->{db_directory}':$OS_ERROR");
    return;
}

sub _remove_cn_schema_directory {
    my ($self) = @_;
    unlink $self->{cn_schema_core_ldif_path}
      or ( $OS_ERROR == POSIX::ENOENT() )
      or Carp::croak(
        "Failed to unlink '$self->{cn_schema_core_ldif_path}:$OS_ERROR");
    unlink $self->{cn_schema_ldif_path}
      or ( $OS_ERROR == POSIX::ENOENT() )
      or
      Carp::croak("Failed to unlink '$self->{cn_schema_ldif_path}':$OS_ERROR");
    my $cn_schema_handle = DirHandle->new( $self->{cn_schema_directory} );
    if ($cn_schema_handle) {
        while ( my $entry = $cn_schema_handle->read() ) {
            next if ( $entry eq File::Spec->curdir() );
            next if ( $entry eq File::Spec->updir() );
            if ( $entry =~ /^(cn=[{]\d+[}]x[-]com[-]synchroad[.]ldif)$/smx ) {
                my $path = "$self->{cn_schema_directory}/$1";
                unlink $path
                  or Carp::croak("Failed to unlink '$path':$OS_ERROR");
            }
        }
        $cn_schema_handle->close()
          or Carp::croak(
            "Failed to close directory '$self->{cn_schema_directory}':$OS_ERROR"
          );
    }
    elsif ( $OS_ERROR != POSIX::ENOENT() ) {
        Carp::croak(
            "Failed to open directory '$self->{cn_schema_directory}':$OS_ERROR"
        );
    }
    rmdir $self->{cn_schema_directory}
      or ( $OS_ERROR == POSIX::ENOENT() )
      or
      Carp::croak("Failed to rmdir '$self->{cn_schema_directory}':$OS_ERROR");
    return;
}

sub DESTROY {
    my ($self) = @_;
    $self->stop();
    unlink $self->{slapd_pid_path}
      or ( $OS_ERROR == POSIX::ENOENT() )
      or Carp::croak("Failed to unlink '$self->{slapd_pid_path}':$OS_ERROR");
    unlink $self->{olc_database_frontend_path}
      or ( $OS_ERROR == POSIX::ENOENT() )
      or Carp::croak(
        "Failed to unlink '$self->{olc_database_frontend_path}':$OS_ERROR");
    $self->_remove_db_directory();
    unlink $self->{olc_database_config_path}
      or ( $OS_ERROR == POSIX::ENOENT() )
      or Carp::croak(
        "Failed to unlink '$self->{olc_database_config_path}':$OS_ERROR");
    $self->_remove_cn_schema_directory();
    rmdir $self->{cn_config_directory}
      or ( $OS_ERROR == POSIX::ENOENT() )
      or
      Carp::croak("Failed to rmdir '$self->{cn_config_directory}':$OS_ERROR");
    unlink $self->{config_ldif_path}
      or ( $OS_ERROR == POSIX::ENOENT() )
      or Carp::croak("Failed to unlink '$self->{config_ldif_path}':$OS_ERROR");
    rmdir $self->{slapd_d_directory}
      or ( $OS_ERROR == POSIX::ENOENT() )
      or Carp::croak("Failed to rmdir '$self->{slapd_d_directory}':$OS_ERROR");
    unlink $self->{slapd_socket_path}
      or ( $OS_ERROR == POSIX::ENOENT() )
      or Carp::croak("Failed to unlink '$self->{slapd_socket_path}':$OS_ERROR");
    rmdir $self->{root_directory}
      or ( $OS_ERROR == POSIX::ENOENT() )
      or Carp::croak("Failed to rmdir '$self->{root_directory}':$OS_ERROR");
    return;
}

=head1 AUTHOR

David Dick, C<< <ddick at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-openldap at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-OpenLDAP>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::OpenLDAP


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-OpenLDAP>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-OpenLDAP>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-OpenLDAP>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-OpenLDAP/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 David Dick.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;
