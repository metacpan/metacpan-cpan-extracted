package VMware::API::vCloud;

# ABSTRACT: VMware vCloud Director

use Data::Dumper;
use LWP;
use XML::Simple;

use warnings;
use strict;

our $VERSION = '2.404'; # VERSION
our $AUTHORITY = 'cpan:NIGELM'; # AUTHORITY

# ADMIN OPTS - http://www.vmware.com/support/vcd/doc/rest-api-doc-1.5-html/landing-admin_operations.html
# USER OPTS - http://www.vmware.com/support/vcd/doc/rest-api-doc-1.5-html/landing-user_operations.html


sub new {
    my $class = shift @_;
    my $self  = {};

    $self->{hostname} = shift @_;
    $self->{username} = shift @_;
    $self->{password} = shift @_;
    $self->{orgname}  = shift @_;

    $self->{debug}        = 0;       # Defaults to no debug info
    $self->{die_on_fault} = 1;       # Defaults to dieing on an error
    $self->{ssl_timeout}  = 3600;    # Defaults to 1h

    $self->{orgname} = 'System' unless $self->{orgname};

    $self->{conf} = shift @_ if defined $_[0] and ref $_[0];
    $self->{debug} = $self->{conf}->{debug} if defined $self->{conf}->{debug};

    bless( $self, $class );

    $self->_regenerate();

    $self->_debug( "Loaded VMware::vCloud v" . our $VERSION . "\n" ) if $self->{debug};
    return $self;
}


sub config {
    my $self = shift @_;

    my %input       = @_;
    my @config_vals = qw/debug die_on_fault hostname orgname password ssl_timeout username/;
    my %config_vals = map { $_, 1; } @config_vals;

    for my $key ( keys %input ) {
        if ( $config_vals{$key} ) {
            $self->{$key} = $input{$key};
        }
        else {
            warn
                'Config key "$key" is being ignored. Only the following options may be configured: '
                . join( ", ", @config_vals ) . "\n";
        }
    }

    $self->_regenerate();

    my %out;
    map { $out{$_} = $self->{$_} } @config_vals;

    return wantarray ? %out : \%out;
}

### Internal methods

# $self->{raw}->{version} - Full data on the API version from login (populated on api_version() call)
# $self->{raw}->{login}
# $self->{learned}->{version} - API version number (populated on api_version() call)
# $self->{learned}->{url}->{login} - Authentication URL (populated on api_version() call)
# $self->{learned}->{url}->{orglist}

sub DESTROY {
    my $self = shift @_;
    my @dump = split "\n", Dumper( $self->{learned} );
    pop @dump;
    shift @dump;
    $self->_debug_with_level( 2, "Learned variables: \n" . join( "\n", @dump ) );
}

sub _debug {
    my $self = shift @_;
    return unless $self->{debug};
    while ( my $debug = shift @_ ) {
        chomp $debug;
        print STDERR "DEBUG: $debug\n";
    }
}

sub _debug_with_level {
    my $self  = shift @_;
    my $value = shift @_;
    return if $self->{debug} < $value;
    $self->_debug(@_);
}

sub _fault {
    my $self  = shift @_;
    my @error = @_;

    my $message = "\nERROR: ";

    if ( scalar @error and ref $error[0] eq 'HTTP::Response' ) {
        if ( $error[0]->content ) {
            $self->_debug( Dumper( \@error ) );
            $self->_debug( 'ERROR Status Line: ' . $error[0]->status_line );
            $self->_debug( 'ERROR Content: ' . $error[0]->content );

            my $ret;    # Try parsing as XML, or fallback to content as message
            eval { $ret = $self->_parse_xml( $error[0]->content ); };
            $message
                .= ( $@ ? $error[0]->content : $error[0]->status_line . ' : ' . $ret->{message} );
        }
        die $message;
    }

    while ( my $error = shift @error ) {
        if ( ref $error eq 'SCALAR' ) {
            chomp $error;
            $message .= $error;
        }
        else {
            $message .= Dumper($error);
        }
    }
}

sub _regenerate {
    my $self = shift @_;
    $self->{ua} = LWP::UserAgent->new;
    $self->_debug_with_level( 2, "VMware::API::vCLoud::_regenerate()" );

    $self->{api_version} = $self->api_version();
    $self->_debug("API Version: $self->{api_version}");

    $self->{url_base} =
        URI->new( 'https://' . $self->{hostname} . '/api/v' . $self->{api_version} . '/' );
    $self->_debug("API URL: $self->{url_base}");
}

sub _xml_response {
    my $self     = shift @_;
    my $response = shift @_;
    $self->_debug_with_level( 3, "Received XML Content: \n\n" . $response->content . "\n\n" );
    if ( $response->is_success ) {
        return unless $response->content;
        return $self->_parse_xml( $response->content );
    }
    else {
        $self->_fault($response);
    }
}

sub _parse_xml {
    my $self = shift @_;
    my $xml  = shift @_;
    my $data = XMLin( $xml, ForceArray => 1 );
    return $data;
}


sub delete {
    my $self = shift @_;
    my $url  = shift @_;
    $self->_debug("API: delete($url)\n") if $self->{debug};
    my $req = HTTP::Request->new( DELETE => $url );
    $req->header( Accept => $self->{learned}->{accept_header} );
    my $response = $self->{ua}->request($req);
    return $self->_xml_response($response);
}


sub get {
    my $self = shift @_;
    my $url = shift @_ || '';
    $self->_debug("API: get($url)\n") if $self->{debug};
    my $req = HTTP::Request->new( GET => $url );
    $req->header( Accept => $self->{learned}->{accept_header} );

    #$self->_debug_with_level(3,"Sending GET: \n\n" . $req->as_string . "\n");
    my $response = $self->{ua}->request($req);
    my $check    = $response->request;
    $self->_debug_with_level( 3, "Sent GET:\n\n" . $check->as_string . "\n" );
    $self->_debug_with_level( 3, "GET returned:\n\n" . $response->as_string . "\n" );
    return $self->_xml_response($response);
}


sub get_raw {
    my $self = shift @_;
    my $url  = shift @_;
    $self->_debug("API: get($url)\n") if $self->{debug};
    my $req = HTTP::Request->new( GET => $url );
    $req->header( Accept => $self->{learned}->{accept_header} );

    #$self->_debug_with_level(3,"Sending GET: \n\n" . $req->as_string . "\n");
    my $response = $self->{ua}->request($req);
    my $check    = $response->request;
    $self->_debug_with_level( 3, "Sent GET:\n\n" . $check->as_string . "\n" );
    $self->_debug_with_level( 3, "GET returned:\n\n" . $response->as_string . "\n" );
    return $response->content;
}


sub post {
    my $self = shift @_;
    my $href = shift @_;

    my $type    = shift @_;
    my $content = shift @_;

    $self->_debug("API: post($href)\n") if $self->{debug};
    my $req = HTTP::Request->new( POST => $href );

    $req->content($content)   if $content;
    $req->content_type($type) if $type;
    $req->header( Accept => $self->{learned}->{accept_header} );

    $self->_debug_with_level(
        3,
        "Posting with XML Content-Type: $type",
        "Posting XML content:\n\n$content\n\n"
    );

    my $response = $self->{ua}->request($req);
    my $data     = $self->_xml_response($response);

    my @ret = ( $response->message, $response->code, $data );

    return wantarray ? @ret : \@ret;
}


sub put {
    my $self = shift @_;
    my $href = shift @_;

    my $type    = shift @_;
    my $content = shift @_;

    $self->_debug("API: post($href)\n") if $self->{debug};
    my $req = HTTP::Request->new( PUT => $href );

    $req->content($content)   if $content;
    $req->content_type($type) if $type;
    $req->header( Accept => $self->{learned}->{accept_header} );

    $self->_debug_with_level(
        3,
        "Posting with XML Content-Type: $type",
        "Posting XML content:\n\n$content\n\n"
    );

    my $response = $self->{ua}->request($req);
    my $data     = $self->_xml_response($response);

    my @ret = ( $response->message, $response->code, $data );

    return wantarray ? @ret : \@ret;
}


sub api_version {
    my $self = shift @_;
    my $url =
        URI->new( 'https://' . $self->{hostname} . '/api/versions' );    # Check API version first!

    $self->_debug("Checking $url for supported API versions");

    my $req = HTTP::Request->new( GET => $url );
    my $response = $self->{ua}->request($req);
    if ( $response->status_line eq '200 OK' ) {
        my $info = XMLin( $response->content );

        #die Dumper($info);

        $self->{learned}->{version} = 0;
        for my $verblock ( @{ $info->{VersionInfo} } ) {
            if ( $verblock->{Version} > $self->{learned}->{version} ) {
                $self->{raw}->{version}          = $verblock;
                $self->{learned}->{version}      = $verblock->{Version};
                $self->{learned}->{url}->{login} = $verblock->{LoginUrl};
            }
        }

        return $self->{learned}->{version};
    }
    else {
        $self->_fault($response);
    }
}


sub login {
    my $self = shift @_;

    $self->_debug( 'Login URL: ' . $self->{learned}->{url}->{login} );
    my $req = HTTP::Request->new( POST => $self->{learned}->{url}->{login} );

    $req->authorization_basic( $self->{username} . '@' . $self->{orgname}, $self->{password} );
    $self->_debug( "Attempting to login: "
            . $self->{username} . '@'
            . $self->{orgname} . ' '
            . $self->{password} );

    $self->{learned}->{accept_header} = 'application/*+xml;version=' . $self->{learned}->{version};
    $self->_debug( 'Accept header: ' . $self->{learned}->{accept_header} );
    $req->header( Accept => $self->{learned}->{accept_header} );

    my $response = $self->{ua}->request($req);

    my $token = $response->header('x-vcloud-authorization');
    $self->{ua}->default_header( 'x-vcloud-authorization', $token );

    $self->_debug( "Authentication status: " . $response->status_line );
    if ( $response->status_line =~ /^4\d\d/ ) {
        die "ERROR: Login Error: " . $response->status_line;
    }

    $self->_debug( "Authentication token: " . $token );

    $self->{raw}->{login} = $self->_xml_response($response);

    for my $link ( @{ $self->{raw}->{login}->{Link} } ) {
        next if not defined $link->{type};
        $self->{learned}->{url}->{admin} = $link->{href}
            if $link->{type} eq 'application/vnd.vmware.admin.vcloud+xml';
        $self->{learned}->{url}->{entity} = $link->{href}
            if $link->{type} eq 'application/vnd.vmware.vcloud.entity+xml';
        $self->{learned}->{url}->{extensibility} = $link->{href}
            if $link->{type} eq 'application/vnd.vmware.vcloud.apiextensibility+xml';
        $self->{learned}->{url}->{extension} = $link->{href}
            if $link->{type} eq 'application/vnd.vmware.admin.vmwExtension+xml';
        $self->{learned}->{url}->{orglist} = $link->{href}
            if $link->{type} eq 'application/vnd.vmware.vcloud.orgList+xml';
        $self->{learned}->{url}->{query} = $link->{href}
            if $link->{type} eq 'application/vnd.vmware.vcloud.query.queryList+xml';

        #die Dumper($self->{raw}->{login}->{Link});
    }

    $self->{have_session} = 1;
    return $self->{raw}->{login};
}


# http://pubs.vmware.com/vcd-51/topic/com.vmware.vcloud.api.doc_51/GUID-FBAA5B7D-8599-40C2-8081-E6D77DF18D5F.html

sub logout {
    my $self = shift @_;
    $self->_debug("API: logout()\n") if $self->{debug};
    $self->{have_session} = 0;

    my $url = $self->{learned}->{url}->{login};
    $url =~ s/sessions/session/;
    my $req = HTTP::Request->new( DELETE => $self->{learned}->{url}->{login} );
    $req->header( Accept => $self->{learned}->{accept_header} );

    my $response = $self->{ua}->request($req);
    return 1 if $response->code() == 401;    # No content is a successful logout
    return $self->_xml_response($response);
}

### API methods


sub admin {
    my $self = shift @_;
    $self->_debug("API: admin()\n")  if $self->{debug};
    return $self->{learned}->{admin} if defined $self->{learned}->{admin};

    my $parsed = $self->get( $self->{learned}->{url}->{admin} );

    $self->{learned}->{admin}->{networks} = $parsed->{Networks}->[0]->{Network};
    $self->{learned}->{admin}->{rights}   = $parsed->{RightReferences}->[0]->{RightReference};
    $self->{learned}->{admin}->{roles}    = $parsed->{RoleReferences}->[0]->{RoleReference};
    $self->{learned}->{admin}->{orgs} =
        $parsed->{OrganizationReferences}->[0]->{OrganizationReference};
    $self->{learned}->{admin}->{pvdcs} =
        $parsed->{ProviderVdcReferences}->[0]->{ProviderVdcReference};

    return $self->{learned}->{admin};
}


sub admin_extension_get {
    my $self = shift @_;
    $self->_debug("API: admin_extension_get()\n") if $self->{debug};
    return $self->get( $self->{learned}->{url}->{admin} . 'extension' );
}


sub admin_extension_vimServer_get {
    my $self = shift @_;
    my $url  = shift @_;
    $self->_debug("API: admin_extension_vimServer_get($url)\n") if $self->{debug};
    return $self->get($url);
}


sub admin_extension_vimServerReferences_get {
    my $self = shift @_;
    $self->_debug("API: admin_extension_vimServerReferences_get()\n") if $self->{debug};
    return $self->get( $self->{learned}->{url}->{admin} . 'extension/vimServerReferences' );
}


# http://pubs.vmware.com/vcd-51/index.jsp?topic=%2Fcom.vmware.vcloud.api.reference.doc_51%2Fdoc%2Foperations%2FPOST-CreateCatalog.html

# Add catalog item http://pubs.vmware.com/vcd-51/index.jsp?topic=%2Fcom.vmware.vcloud.api.reference.doc_51%2Fdoc%2Foperations%2FPOST-CreateCatalogItem.html

sub catalog_create {
    my $self = shift @_;
    my $url  = shift @_;
    my $conf = shift @_;

    $conf->{is_published} = 0 unless defined $conf->{is_published};

    $url .= '/catalogs' unless $url =~ /\/catalogs$/;
    $self->_debug("API: catalog_create($url)\n") if $self->{debug};

    my $xml = '<AdminCatalog xmlns="http://www.vmware.com/vcloud/v1.5" name="' . $conf->{name} . '">
   <Description>' . $conf->{description} . '</Description>
   <IsPublished>' . $conf->{is_published} . '</IsPublished>
</AdminCatalog>';

    my $ret = $self->post( $url, 'application/vnd.vmware.admin.catalog+xml', $xml );

    return $ret->[2]->{href} if $ret->[1] == 201;
    return $ret;
}


sub catalog_get {
    my $self = shift @_;
    my $cat  = shift @_;
    $self->_debug("API: catalog_get($cat)\n") if $self->{debug};
    return $self->get( $cat =~ /^[^\/]+$/ ? $self->{url_base} . 'catalog/' . $cat : $cat );
}


# http://pubs.vmware.com/vcd-51/index.jsp?topic=%2Fcom.vmware.vcloud.api.reference.doc_51%2Fdoc%2Ftypes%2FControlAccessParamsType.html

sub catalog_get_access {
    my $self     = shift @_;
    my $cat_href = shift @_;
    my $org_href = shift @_;

    die 'Bad Catalog HREF' unless $cat_href =~ /(\/catalog\/[^\/]+)$/;
    my $href = $org_href . $1 . '/controlAccess';
    $href =~ s/admin\///;

    $self->_debug("API: catalog_get_access($href)\n") if $self->{debug};
    return $self->get($href);
}


# http://pubs.vmware.com/vcd-51/index.jsp?topic=%2Fcom.vmware.vcloud.api.reference.doc_51%2Fdoc%2Ftypes%2FControlAccessParamsType.html

sub catalog_set_access {
    my $self      = shift @_;
    my $cat_href  = shift @_;
    my $org_href  = shift @_;
    my $is_shared = shift @_;
    my $level     = shift @_;

    die 'Bad Catalog HREF' unless $cat_href =~ /(\/catalog\/[^\/]+)$/;
    my $href = $org_href . $1 . '/action/controlAccess';
    $href =~ s/admin\///;

    $self->_debug("API: catalog_set_access($href)\n") if $self->{debug};

    my $xml = '<ControlAccessParams xmlns="http://www.vmware.com/vcloud/v1.5">
    <IsSharedToEveryone>' . $is_shared . '</IsSharedToEveryone>
    <EveryoneAccessLevel>' . $level . '</EveryoneAccessLevel>
</ControlAccessParams>';

    my $ret = $self->post( $href, 'application/vnd.vmware.vcloud.controlAccess+xml', $xml );

    return $ret->[2]->{href} if $ret->[1] == 201;
    return $ret;
}


sub datastore_list {
    my $self      = shift @_;
    my $query_url = $self->{learned}->{url}->{query} . '?type=datastore&format=idrecords';
    return $self->get($query_url);
}


# http://pubs.vmware.com/vcd-51/topic/com.vmware.vcloud.api.doc_51/GUID-439C57EA-859C-423C-B21B-22B230395600.html
# http://www.vmware.com/support/vcd/doc/rest-api-doc-1.5-html/operations/PUT-Organization.html

sub org_create {
    my $self = shift @_;
    my $conf = shift @_;

    $self->_debug("API: org_create()\n") if $self->{debug};
    my $url = $self->{learned}->{url}->{admin} . 'orgs';

    $conf->{ldap_mode} = 'NONE' unless defined $conf->{ldap_mode};

    my $vapp_lease = '<VAppLeaseSettings>
            <DeleteOnStorageLeaseExpiration>0</DeleteOnStorageLeaseExpiration>
            <DeploymentLeaseSeconds>0</DeploymentLeaseSeconds>
            <StorageLeaseSeconds>0</StorageLeaseSeconds>
        </VAppLeaseSettings>';

    my $tmpl_lease = '<VAppTemplateLeaseSettings>
            <DeleteOnStorageLeaseExpiration>0</DeleteOnStorageLeaseExpiration>
            <StorageLeaseSeconds>0</StorageLeaseSeconds>
        </VAppTemplateLeaseSettings>';

    my $vdcs;
    if ( defined $conf->{vdc} and ref $conf->{vdc} ) {
        for my $vdc ( @{ $conf->{vdc} } ) {
            $vdcs .= '<Vdc href="' . $vdc . '"/> ';
        }
    }
    elsif ( defined $conf->{vdc} ) {
        $vdcs = '<Vdc href="' . $conf->{vdc} . '"/> ';
    }
    $vdcs .= "\n";

    my $xml = '
<AdminOrg xmlns="http://www.vmware.com/vcloud/v1.5" name="' . $conf->{name} . '">
  <Description>' . $conf->{desc} . '</Description>
  <FullName>' . $conf->{fullname} . '</FullName>
  <IsEnabled>' . $conf->{is_enabled} . '</IsEnabled>
    <Settings>
        <OrgGeneralSettings>
            <CanPublishCatalogs>' . $conf->{can_publish} . '</CanPublishCatalogs>
            <DeployedVMQuota>' . $conf->{deployed} . '</DeployedVMQuota>
            <StoredVmQuota>' . $conf->{stored} . '</StoredVmQuota>
            <UseServerBootSequence>false</UseServerBootSequence>
            <DelayAfterPowerOnSeconds>1</DelayAfterPowerOnSeconds>
        </OrgGeneralSettings>
        ' . $vapp_lease . '
        ' . $tmpl_lease . '
        <OrgLdapSettings>
          <OrgLdapMode>' . $conf->{ldap_mode} . '</OrgLdapMode>
        </OrgLdapSettings>
    </Settings>
    <Vdcs>
      ' . $vdcs . '
    </Vdcs>
</AdminOrg>
';

    my $ret = $self->post( $url, 'application/vnd.vmware.admin.organization+xml', $xml );

    return $ret->[2]->{href} if $ret->[1] == 201;
    return $ret;
}


sub org_get {
    my $self = shift @_;
    my $org  = shift @_;
    my $req;

    $self->_debug("API: org_get($org)\n") if $self->{debug};
    return $self->get( $org =~ /^[^\/]+$/ ? $self->{url_base} . 'org/' . $org : $org );
}


sub org_list {
    my $self = shift @_;
    $self->_debug("API: org_list()\n") if $self->{debug};
    return $self->get( $self->{learned}->{url}->{orglist} );
}


sub org_network_create {
    my $self = shift @_;
    my $url  = shift @_;
    my $conf = shift @_;

    $conf->{is_shared} = 0 unless defined $conf->{is_shared};

    $self->_debug("API: org_network_create()\n") if $self->{debug};

    #  my $xml = '
    #<OrgNetwork xmlns="http://www.vmware.com/vcloud/v1.5" name="'.$name.'">
    #  <Description>'.$desc.'</Description>
    #   <Configuration>
    #      <IpScopes>
    #         <IpScope>
    #            <IsInherited>false</IsInherited>
    #            <Gateway>'.$gateway .'</Gateway>
    #            <Netmask>'.$netmask.'</Netmask>
    #            <Dns1>'.$dns1.'</Dns1>
    #            <Dns2>'.$dns2.'</Dns2>
    #            <DnsSuffix>'.$dnssuffix.'</DnsSuffix>
    #            <IpRanges>
    #               <IpRange>
    #                  <StartAddress>'.$start_ip.'</StartAddress>
    #                  <EndAddress>'.$end_ip.'</EndAddress>
    #               </IpRange>
    #            </IpRanges>
    #         </IpScope>
    #      </IpScopes>
    #      <FenceMode>natRouted</FenceMode>
    #   </Configuration>
    #   <EdgeGateway
    #      href="https://vcloud.example.com/api/admin/gateway/2000" />
    #   <IsShared>true</IsShared>
    #</OrgVdcNetwork>
    #  ';

    my $xml = '<OrgVdcNetwork
   name="' . $conf->{name} . '"
   xmlns="http://www.vmware.com/vcloud/v1.5">
   <Description>' . $conf->{desc} . '</Description>
   <Configuration>
      <ParentNetwork
         href="' . $conf->{parent_net_href} . '" />
      <FenceMode>bridged</FenceMode>
   </Configuration>
  <IsShared>' . $conf->{is_shared} . '</IsShared>
</OrgVdcNetwork>';

    $url .= '/networks';

    my $ret = $self->post( $url, 'application/vnd.vmware.vcloud.orgVdcNetwork+xml', $xml );

    return $ret->[2]->{href} if $ret->[1] == 201;
    return $ret;
}


# http://pubs.vmware.com/vcd-51/index.jsp?topic=%2Fcom.vmware.vcloud.api.reference.doc_51%2Fdoc%2Ftypes%2FCreateVdcParamsType.html

sub org_vdc_create {
    my $self = shift @_;
    my $url  = shift @_;
    my $conf = shift @_;

    $self->_debug("API: org_vdc_create()\n") if $self->{debug};

    my $networkpool =
        $conf->{np_href} ? '<NetworkPoolReference href="' . $conf->{np_href} . '"/>' : '';

    my $sp;
    if ( defined $conf->{sp} and ref $conf->{sp} ) {
        for my $ref ( @{ $conf->{sp} } ) {
            $sp .= '<VdcStorageProfile>
      <Enabled>' . $ref->{sp_enabled} . '</Enabled>
      <Units>' . $ref->{sp_units} . '</Units>
      <Limit>' . $ref->{sp_limit} . '</Limit>
      <Default>' . $ref->{sp_default} . '</Default>
      <ProviderVdcStorageProfile href="' . $ref->{sp_href} . '" />
   </VdcStorageProfile>';
        }
    }
    elsif ( defined $conf->{sp_enabled} ) {
        $sp = '<VdcStorageProfile>
      <Enabled>' . $conf->{sp_enabled} . '</Enabled>
      <Units>' . $conf->{sp_units} . '</Units>
      <Limit>' . $conf->{sp_limit} . '</Limit>
      <Default>' . $conf->{sp_default} . '</Default>
      <ProviderVdcStorageProfile href="' . $conf->{sp_href} . '" />
   </VdcStorageProfile>';
    }

    my $xml = '
<CreateVdcParams xmlns="http://www.vmware.com/vcloud/v1.5" name="' . $conf->{name} . '">
  <Description>' . $conf->{desc} . '</Description>
  <AllocationModel>' . $conf->{allocation_model} . '</AllocationModel>
   <ComputeCapacity>
      <Cpu>
         <Units>' . $conf->{cpu_unit} . '</Units>
         <Allocated>' . $conf->{cpu_alloc} . '</Allocated>
         <Limit>' . $conf->{cpu_limit} . '</Limit>
      </Cpu>
      <Memory>
         <Units>' . $conf->{mem_unit} . '</Units>
         <Allocated>' . $conf->{mem_alloc} . '</Allocated>
         <Limit>' . $conf->{mem_limit} . '</Limit>
      </Memory>
   </ComputeCapacity>
   <NicQuota>' . $conf->{nic_quota} . '</NicQuota>
   <NetworkQuota>' . $conf->{net_quota} . '</NetworkQuota>
   ' . $sp . '
   <ResourceGuaranteedMemory>' . $conf->{ResourceGuaranteedMemory} . '</ResourceGuaranteedMemory>
   <ResourceGuaranteedCpu>' . $conf->{ResourceGuaranteedCpu} . '</ResourceGuaranteedCpu>
   <VCpuInMhz>' . $conf->{VCpuInMhz} . '</VCpuInMhz>
   <IsThinProvision>' . $conf->{is_thin_provision} . '</IsThinProvision>
   ' . $networkpool . '
   <ProviderVdcReference
      name="' . $conf->{pvdc_name} . '"
      href="' . $conf->{pvdc_href} . '" />
   <UsesFastProvisioning>' . $conf->{use_fast_provisioning} . '</UsesFastProvisioning>
</CreateVdcParams>
  ';

    $url .= '/vdcsparams';

    my $ret = $self->post( $url, 'application/vnd.vmware.admin.createVdcParams+xml', $xml );

    return $ret->[2]->{href} if $ret->[1] == 201;
    return $ret;
}


# http://pubs.vmware.com/vcd-51/index.jsp?topic=%2Fcom.vmware.vcloud.api.reference.doc_51%2Fdoc%2Ftypes%2FAdminVdcType.html

sub org_vdc_update {
    my $self = shift @_;
    my $url  = shift @_;
    my $conf = shift @_;
    $self->_debug("API: org_vdc_update()\n") if $self->{debug};

    my $desc = '<Description>' . $conf->{desc} . "</Description>\n";
    my $alloc =
        $conf->{allocation_model}
        ? '<AllocationModel>' . $conf->{allocation_model} . "</AllocationModel>\n"
        : '';
    my $compute;
    my $nicquota =
        defined $conf->{nic_quota} ? '<NicQuota>' . $conf->{nic_quota} . "</NicQuota>\n" : '';
    my $netquota =
        defined $conf->{net_quota}
        ? '<NetworkQuota>' . $conf->{net_quota} . "</NetworkQuota>\n"
        : '';
    my $sp;
    my $networkpool =
        $conf->{np_href} ? '<NetworkPoolReference href="' . $conf->{np_href} . '"/>' : '';
    my $res_mem =
        defined $conf->{ResourceGuaranteedMemory}
        ? '<ResourceGuaranteedMemory>'
        . $conf->{ResourceGuaranteedMemory}
        . "</ResourceGuaranteedMemory>\n"
        : '';
    my $res_cpu =
        defined $conf->{ResourceGuaranteedCpu}
        ? '<ResourceGuaranteedCpu>' . $conf->{ResourceGuaranteedCpu} . "</ResourceGuaranteedCpu>\n"
        : '';
    my $vcpu =
        defined $conf->{VCpuInMhz} ? '<VCpuInMhz>' . $conf->{VCpuInMhz} . "</VCpuInMhz>\n" : '';
    my $thin =
        defined $conf->{is_thin_provision}
        ? '<IsThinProvision>' . $conf->{is_thin_provision} . "</IsThinProvision>\n"
        : '';
    my $pvdc =
        $conf->{pvdc_href}
        ? '<ProviderVdcReference name="'
        . $conf->{pvdc_name}
        . '" href="'
        . $conf->{pvdc_href}
        . "\" />\n"
        : '';
    my $fast =
        defined $conf->{use_fast_provisioning}
        ? '<UsesFastProvisioning>' . $conf->{use_fast_provisioning} . "</UsesFastProvisioning>\n"
        : '';

    if ( defined $conf->{sp} and ref $conf->{sp} ) {
        for my $ref ( @{ $conf->{sp} } ) {
            $sp .= '<VdcStorageProfile>
      <Enabled>' . $ref->{sp_enabled} . '</Enabled>
      <Units>' . $ref->{sp_units} . '</Units>
      <Limit>' . $ref->{sp_limit} . '</Limit>
      <Default>' . $ref->{sp_default} . '</Default>
      <ProviderVdcStorageProfile href="' . $ref->{sp_href} . '" />
   </VdcStorageProfile>';
        }
    }
    elsif ( defined $conf->{sp_enabled} ) {
        $sp = '<VdcStorageProfile>
      <Enabled>' . $conf->{sp_enabled} . '</Enabled>
      <Units>' . $conf->{sp_units} . '</Units>
      <Limit>' . $conf->{sp_limit} . '</Limit>
      <Default>' . $conf->{sp_default} . '</Default>
      <ProviderVdcStorageProfile href="' . $conf->{sp_href} . '" />
   </VdcStorageProfile>';
    }

    if ( defined $conf->{cpu_unit} or defined $conf->{mem_unit} ) {
        $compute = '  <ComputeCapacity>
      <Cpu>
         <Units>' . $conf->{cpu_unit} . '</Units>
         <Allocated>' . $conf->{cpu_alloc} . '</Allocated>
         <Limit>' . $conf->{cpu_limit} . '</Limit>
      </Cpu>
      <Memory>
         <Units>' . $conf->{mem_unit} . '</Units>
         <Allocated>' . $conf->{mem_alloc} . '</Allocated>
         <Limit>' . $conf->{mem_limit} . "</Limit>
      </Memory>
   </ComputeCapacity>\n";
    }

    my $href = $conf->{href} ? 'href="' . $conf->{href} . '"' : '';

    my $xml =
          '<AdminVdc xmlns="http://www.vmware.com/vcloud/v1.5" '
        . $href
        . ' name="'
        . $conf->{name} . "\">\n"
        . $desc
        . $alloc
        . $compute
        . $nicquota
        . $netquota
        . $sp
        . $res_mem
        . $res_cpu
        . $vcpu
        . $thin
        . $networkpool
        . $pvdc
        . $fast
        . "</AdminVdc>\n";

    my $ret = $self->put( $url, 'application/vnd.vmware.admin.vdc+xml', $xml );

    return $ret->[2]->{href} if $ret->[1] == 201;
    return $ret;
}


sub pvdc_get {
    my $self = shift @_;
    my $tmpl = shift @_;
    $self->_debug("API: pvdc_get($tmpl)\n") if $self->{debug};
    return $self->get( $tmpl =~ /^[^\/]+$/ ? $self->{url_base} . 'tmpl/' . $tmpl : $tmpl );
}


# http://pubs.vmware.com/vcd-51/topic/com.vmware.vcloud.api.reference.doc_51/doc/operations/GET-Task.html

sub task_get {
    my $self = shift @_;
    my $href = shift @_;
    $self->_debug("API: task_get($href)\n") if $self->{debug};
    return $self->get($href);
}


# http://pubs.vmware.com/vcd-51/index.jsp?topic=%2Fcom.vmware.vcloud.api.reference.doc_51%2Fdoc%2Foperations%2FGET-VAppTemplate.html

sub template_get {
    my $self = shift @_;
    my $tmpl = shift @_;
    $self->_debug("API: template_get($tmpl)\n") if $self->{debug};
    return $self->get( $tmpl =~ /^[^\/]+$/ ? $self->{url_base} . 'tmpl/' . $tmpl : $tmpl );
}


# http://www.vmware.com/support/vcd/doc/rest-api-doc-1.5-html/operations/GET-VAppTemplateMetadata.html

sub template_get_metadata {
    my $self = shift @_;
    my $href = shift @_;
    $self->_debug("API: template_get_metadata($href)\n") if $self->{debug};
    return $self->get( $href . '/metadata' );
}


sub vdc_get {
    my $self = shift @_;
    my $vdc  = shift @_;
    $self->_debug("API: vdc_get($vdc)\n") if $self->{debug};
    return $self->get( $vdc =~ /^[^\/]+$/ ? $self->{url_base} . 'vdc/' . $vdc : $vdc );
}


sub vdc_list {
    my $self = shift @_;
    $self->_debug("API: vdc_list()\n") if $self->{debug};
    return $self->get( $self->{learned}->{url}->{admin} . 'vdcs/query' );
}


# http://pubs.vmware.com/vcd-51/index.jsp?topic=%2Fcom.vmware.vcloud.api.reference.doc_51%2Fdoc%2Ftypes%2FInstantiateVAppTemplateParamsType.html

sub vapp_create_from_template {
    my $self = shift @_;
    my $url  = shift @_;

    my $name                    = shift @_;
    my $netid                   = shift @_;
    my $fencemode               = shift @_;
    my $template_href           = shift @_;
    my $IpAddressAllocationMode = shift @_;

    my $vdcid  = shift @_;
    my $tmplid = shift @_;

    $self->_debug("API: vapp_create($url)\n") if $self->{debug};

    # XML to build

    my $xml =
          '<InstantiateVAppTemplateParams name="'
        . $name
        . '" xmlns="http://www.vmware.com/vcloud/v1.5" xmlns:ovf="http://schemas.dmtf.org/ovf/envelope/1" >
	<Description>Example FTP Server vApp</Description>
	<InstantiationParams>
		<NetworkConfigSection>
			<ovf:Info>Configuration parameters for vAppNetwork</ovf:Info>
			<NetworkConfig networkName="vAppNetwork">
				<Configuration>
					<ParentNetwork href="' . $netid . '"/>
					<FenceMode>' . $fencemode . '</FenceMode>
				</Configuration>
			</NetworkConfig>
		</NetworkConfigSection>
	</InstantiationParams>
	<Source href="' . $template_href . '"/>
  </InstantiateVAppTemplateParams>';

    my $ret =
        $self->post( $url, 'application/vnd.vmware.vcloud.instantiateVAppTemplateParams+xml',
        $xml );
    my $task_href = $ret->[2]->{Tasks}->[0]->{Task}->{task}->{href};
    return wantarray ? ( $task_href, $ret ) : \( $task_href, $ret );
}


# http://pubs.vmware.com/vcd-51/topic/com.vmware.vcloud.api.doc_51/GUID-9E04772F-2BA9-42A9-947D-4EE7A05A6EE0.html

sub vapp_create_from_sources {
    my $self = shift @_;
    my $url  = shift @_;

    my $name                    = shift @_;
    my $netid                   = shift @_;
    my $fencemode               = shift @_;
    my $template_href           = shift @_;
    my $IpAddressAllocationMode = shift @_;

    my $vdcid  = shift @_;
    my $tmplid = shift @_;

    $self->_debug("API: vapp_create($url)\n") if $self->{debug};

    # XML to build
    my $xml = '
<InstantiateVAppTemplateParams name="' . $name
        . '" xmlns="http://www.vmware.com/vcloud/v1.5" xmlns:ovf="http://schemas.dmtf.org/ovf/envelope/1" >
	<Description>Example FTP Server vApp</Description>
	<InstantiationParams>
		<NetworkConfigSection>
			<ovf:Info>Configuration parameters for vAppNetwork</ovf:Info>
			<NetworkConfig networkName="vAppNetwork">
				<Configuration>
					<ParentNetwork href="' . $netid . '"/>
					<FenceMode>' . $fencemode . '</FenceMode>
				</Configuration>
			</NetworkConfig>
		</NetworkConfigSection>
	</InstantiationParams>
	<Source href="' . $template_href . '"/>
</InstantiateVAppTemplateParams>
';

    return $self->post( $url, 'application/vnd.vmware.vcloud.instantiateVAppTemplateParams+xml',
        $xml );
}


sub vapp_get {
    my $self = shift @_;
    my $vapp = shift @_;
    my $req;

    $self->_debug("API: vapp_get($vapp)\n") if $self->{debug};
    return $self->get( $vapp =~ /^[^\/]+$/ ? $self->{url_base} . 'vApp/vapp-' . $vapp : $vapp );
}


# http://pubs.vmware.com/vcd-51/index.jsp?topic=%2Fcom.vmware.vcloud.api.reference.doc_51%2Fdoc%2Foperations%2FGET-VAppMetadata.html

sub vapp_get_metadata {
    my $self = shift @_;
    my $href = shift @_;
    $self->_debug("API: vapp_get_metadata($href)\n") if $self->{debug};
    return $self->get( $href . '/metadata' );
}


# POST /vApp/{id}/action/recomposeVApp
# http://www.vmware.com/support/vcd/doc/rest-api-doc-1.5-html/types/RecomposeVAppParamsType.html

sub vapp_recompose_add_vm {
    my $self      = shift @_;
    my $vapp_name = shift @_;
    my $vapp_href = shift @_;
    my $vm_name   = shift @_;
    my $vm_href   = shift @_;

    my $network        = shift @_;
    my $storageProfile = shift @_;

    my $desc = '';

    my $xml =
        '<RecomposeVAppParams xmlns="http://www.vmware.com/vcloud/v1.5" xmlns:ovf="http://schemas.dmtf.org/ovf/envelope/1" >
    <Description>' . $desc . '</Description>
    <SourcedItem sourceDelete="0">
        <Source href="' . $vm_href . '" name="' . $vm_name . '" />
    </SourcedItem>
    <AllEULAsAccepted> 1 </AllEULAsAccepted>
    <CreateItem href="' . $vapp_href . '" name="' . $vapp_name . '">
        <Description>".$desc."</Description>
        <StorageProfile href="' . $storageProfile . '"/>
    </CreateItem>
</RecomposeVAppParams>';

    return $self->post( $vapp_href . '/action/recomposeVApp',
        'application/vnd.vmware.vcloud.recomposeVAppParams+xml', $xml );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

VMware::API::vCloud - VMware vCloud Director

=head1 VERSION

version 2.404

=head1 SYNOPSIS

  my $api = new VMware::API::vCloud (
    $hostname, $username, $password, $orgname
  );

  my $raw_login_data = $vcd->login;

=head1 DESCRIPTION

This module provides a bare interface to VMware's vCloud REST API.

VMware::vCloud is designed for high level usage with vCloud Director. This
module, however, provides a more low-level access to the REST interface.

Responses received from vCloud are in XML. They are translated via XML::Simple
with ForceArray set for consistency in nesting. This is the object returned.

Aside from the translation of XML into a perl data structure, no further
alteration is performed on the data.

HTTP errors are automatically parsed and die() is called. If you need to
perform a dangerous action, do so in an eval block and evaluate $@.

=head1 NAME

VMware::API::vCloud - The VMware vCloud API

=head1 OBJECT METHODS

These methods are not API calls. They represent the methods that create this
module as a "wrapper" for the vCloud API.

=head2 new()

This method creates the vCloud object.

Arguments

=over 4

=item * hostname

=item * username

=item * password

=item * organization

=back

=head2 config()

  $vcd->config( debug => 1 );

=over 4

=item debug

  0 for no debugging.
  1 to turn on basic debug messages.
  2 to display learned variables on exit.
  3 to show all XML transactions.

=item die_on_fault - 1 to cause the program to die verbosely on a soap fault. 0 for the fault object to be returned on the call and for die() to not be called. Defaults to 1. If you choose not to die_on_fault (for example, if you are writing a CGI) you will want to check all return objects to see if they are fault objects or not.

=item ssl_timeout - seconds to wait for timeout. Defaults to 3600. (1hr) This is how long a transaction response will be waited for once submitted. For slow storage systems and full clones, you may want to up this higher. If you find yourself setting this to more than 6 hours, your vCloud setup is probably not in the best shape.

=item hostname, orgname, username and password - All of these values can be changed from the original settings on new(). This is handing for performing multiple transactions across organizations.

=back

=head1 REST METHODS

These are direct access to the REST web methods.

=head2 delete($url)

Performs a DELETE action on the given URL, and returns the parsed XML response.

=head2 get($url)

Performs a GET action on the given URL, and returns the parsed XML response.

=head2 get_raw($url)

Performs a GET action on the given URL, and returns the unparsed HTTP::Request
object.

=head2 post($url,$type,$content)

Performs a POST action on the given URL, and returns the parsed XML response.

The optional value for $type is set as the Content Type for the transaction.

The optional value for $content is used as the content of the post.

=head2 put($url,$type,$content)

Performs a PUT action on the given URL, and returns the parsed XML response.

The optional value for $type is set as the Content Type for the transaction.

The optional value for $content is used as the content of the post.

=head1 API SHORTHAND METHODS

=head2 api_version

* Relative URL: /api/versions

This call queries the server for the current version of the API supported. It
is implicitly called when library is instanced.

=head2 login

* Relative URL: dynamic, but usually: /login/

This call takes the username and password provided in the config() and creates
an authentication  token from the server. If successful, it returns the login
data returned by the server.

In the 5.1 version of the API, this is a list of several access URLs.

=head2 logout()

Removes the current login session on the server.

=head2 admin()

* Relative URL: dynamic admin URL, usually /api/admin/

Parses the admin API URL to build and return a hash reference of key URLs for
the API.

=head2 admin_extension_get()

* Relative URL: dynamic admin URL followed by "/extension"

=head2 admin_extension_vimServer_get()

=head2 admin_extension_vimServerReferences_get()

=head2 catalog_create($org_href,$conf)

$conf is a hashref that can contain:

=over 4

=item * name

=item * description

=item * is_published

=back

Org HREF example: http://example.vcd.server/api/admin/org/{id}

=head2 catalog_get($catid or $caturl)

As a parameter, this method thakes the raw numeric id of the catalog or the
full URL detailed for the catalog from the login catalog.

It returns the requested catalog.

=head2 catalog_get_access($cat_href,$org_href)

HREF example:
http://example.vcd.server/api/org/{id}/catalog/{catalogId}/action/controlAccess

=head2 catalog_set_access($cat_href,$org_href,$is_shared,$level)

The sets the "organizational" sharing for a catalog.

=over 4

=item * is_shared - 1 or 0

=item * level - one of: FullControl, Change, ReadOnly

=back

HREF example:
http://example.vcd.server/api/org/{id}/catalog/{catalogId}/action/controlAccess

=head2 datastore_list()

Connect to the System group for this query to work.

Returns a hash(ref) or datastore information.

=head2 org_create($name,$desc,$fullname,$is_enabled)

Create an organization.

=over 4

=item * name

=item * desc

=item * fullname

=item * is_enabled

=item * can_publish

=item * deployed

=item * stored

=item * ldap_mode: NONE, SYSTEM or CUSTOM - Custom requires further parameters not implemented yet. Default is NONE

=back

=head2 org_get($orgid or $orgurl)

As a parameter, this method takes the raw numeric id of the organization or the
full URL detailed for the organization from the login catalog.

It returns the requested organization.

=head2 org_list()

Returns the full list of available organizations.

=head2 org_network_create($url,$conf)

Create an org network

The conf hash reference can contain:

=over 4

=item * name

=item * desc

=item * gateway

=item * netmask

=item * dns1

=item * dns2

=item * dnssuffix

=item * is_enabled

=item * is_shared

=item * start_ip

=item * end_ip

=back

=head2 org_vdc_create($url,$conf)

Create an org VDC

The conf hash reference can contain:

=over 4

=item * name

=item * desc

=item * np_href

=item * sp_enabled

=item * sp_units

=item * sp_limit

=item * sp_default

=item * sp_href

=item * allocation_model

=item * cpu_unit

=item * cpu_alloc

=item * cpu_limit

=item * mem_unit

=item * mem_alloc

=item * mem_limit

=item * nic_quota

=item * net_quota

=item * ResourceGuaranteedMemory

=item * ResourceGuaranteedCpu

=item * VCpuInMhz

=item * is_thin_provision

=item * pvdc_name

=item * pvdc_href

=item * use_fast_provisioning

=back

=head2 org_vdc_update($url,$conf)

Create an org VDC

The conf hash reference can contain:

=over 4

=item * name (required)

=item * desc

=item * np_href

=item * sp_enabled

=item * sp_units

=item * sp_limit

=item * sp_default

=item * sp_href

=item * allocation_model

=item * cpu_unit

=item * cpu_alloc

=item * cpu_limit

=item * mem_unit

=item * mem_alloc

=item * mem_limit

=item * nic_quota

=item * net_quota

=item * ResourceGuaranteedMemory

=item * ResourceGuaranteedCpu

=item * VCpuInMhz

=item * is_thin_provision

=item * pvdc_name

=item * pvdc_href

=item * use_fast_provisioning

=back

=head2 pvdc_get($href)

Returns information on the pvdc.

=head2 task_get($href)

Returns information on the task.

=head2 template_get($templateid or $templateurl)

As a parameter, this method thakes the raw numeric id of the template or the
full URL.

It returns the requested template.

=head2 template_get_metadata($tmpl_href)

Returns the response for metadata for the given template href.

HREF example: http://example.vcd.server/api/vAppTemplate/{uuid}

=head2 vdc_get($vdcid or $vdcurl)

As a parameter, this method thakes the raw numeric id of the virtual data
center or the full URL detailed a catalog.

It returns the requested VDC.

=head2 vdc_list()

Returns the full list of available VDCs.

=head2 vapp_create_from_template($url,$name,$netid,$fencemode,$template_href,$IpAddressAllocationMode,$vcdid,$tmplid)

Create a vapp from a vapp template.

Given a name, VDC, template and network, instantiate the vapp template with the
given settings and other defaults.

=over 4

=item * Fencemode can be: bridged, isolated, or natRouted

=item * IP Allocation mode can be: NONE, MANUAL, POOL, DHCP

=back

An array(ref) is returned. The first element is the task href, if one was
created. The second element is the HTTP reqest object returned by the server.

=head2 vapp_create_from_sources($url,$name,$netid,$fencemode,$template_href,$IpAddressAllocationMode,$vcdid,$sourcesref)

Given one or more source HREFs, such as VMs withing in an existing template or
a VM catalog item, create a vApp.

Details of the create task will be returned.

=over 4

=item * Fencemode can be: bridged, isolated, or natRouted

=item * IP Allocation mode can be: NONE, MANUAL, POOL, DHCP

=back

=head2 vapp_get($vappid or $vapp_href)

As a parameter, this method thakes the raw numeric id of the vApp or the full
URL.

It returns the requested vApp.

=head2 vapp_get_metadata($vapp_href)

Returns the response for metadata for the given vApp href.

HREF example: http://example.vcd.server/api/vApp/{uuid}

=head2 vapp_recompose_add_vm($href,$vapp_name,$vapp_href,$vm_name_to_be,$vm_current_href)

Returns a task.

VM should be powered off to work.

=head1 BUGS and LIMITATIONS

=head3 Which "name" is which when recomposing a vApp

The docs on recomosing a vApp (URL below) refer to a name as an attribute of
RecomposeVAppParams, a name as an arrtributed of the SourcedItem, and a name as
an attribute of CreateItem or DeleteItem.

I believe the official description of all three is "A name as parameter."

Here's what they do when inserting a VM into an existing vApp:

RecomposeVAppParams name attribute - names the task. (I think)

SourcedItem name attribute - The name the new VM will be when put into the
vApp. (Note that the "href" attribute right next to it will reference the
CURRENT location the VM is being copied from. Got that? One attribute is for
the "from" side of the action, and the other is for the "to" side. Clear as
mud?)

CreateItem attribute - The name of the container vApp that is being edited. If
you change the name, but retain the href for the vApp, it will rename the vApp
to the new name.

=head3 LoginUrl error.

In both version 1.5 and 5.1 of the API, the "LoginUrl" returned upon log has
the value of 'https://HOSTNAME/api/sessions'

To actually succeed with an API log out, however, the URL has to be "session" -
singular - 'https://HOSTNAME/api/session'

This module works around this issue.

=head3 Template name validation.

Most names in the GUI (for vApps, VMs, Templates, and Catalogs) are limited to
128 characters, and are restricted to being composed of alpha numerics and
standard keyboard punctuations. Notably, spaces and tabs are NOT allowed to be
entered in the GUI. However, you can upload a template in the API with a space
in the name. It will only be visable or usable some of the time in the GUI.
Apparently there is a bug in name validation via the API.

=head1 WISH LIST

If someone from VMware is reading this, and has control of the API, I would
dearly love a few changes, that might help things:

=over 4

=item Statistics & Dogfooding - There is an implied contract in the API. That is, anything I can see and do in the GUI I should also be able to do via the API. There are no per-VM statistics available in the API. But the statistics are shown in the GUI. Please offer per-VM statistics in the API. Crosswalking the VM name and trying to find the data in the vSphere API to do this is a pain.

=item System - It would really help if in the API guide it mentions early on that the organization to connect as an administrator account, IE: the macro organization to which all other orgs descend from is called "System." That helps a lot.

=item External vs External - When you have the concept of a "fenced" network for a vApp, one of the most confusing points is the local network that is natted to the outside is referred to as "External" as is the outside IPs that the network is routed to. Walk a new user through some of the Org creation wizards and watch the confusion. Bad choice of names.

=back

=head1 DEPENDENCIES

  LWP
  XML::Simple

=head1 SEE ALSO

 VMware vCloud Director Publications
  http://www.vmware.com/support/pubs/vcd_pubs.html
  http://pubs.vmware.com/vcd-51/index.jsp

 VMware vCloud API Programming Guide v5.1
  http://pubs.vmware.com/vcd-51/topic/com.vmware.vcloud.api.doc_51/GUID-86CA32C2-3753-49B2-A471-1CE460109ADB.html

 vCloud API and Admin API v5.1 schema definition files
  http://pubs.vmware.com/vcd-51/topic/com.vmware.vcloud.api.reference.doc_51/about.html

 VMware vCloud API Communities
  http://communities.vmware.com/community/vmtn/developer/forums/vcloudapi

 VMware vCloud API Specification v1.5
  http://www.vmware.com/support/vcd/doc/rest-api-doc-1.5-html/

=head1 AUTHORS

=over 4

=item *

Phillip Pollard <bennie@cpan.org>

=item *

Nigel Metheringham <nigelm@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Phillip Pollard <bennie@cpan.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
