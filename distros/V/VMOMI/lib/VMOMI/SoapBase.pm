package VMOMI::SoapBase;

use strict;
use warnings;

use URI;
use XML::LibXML;
use XML::LibXML::Reader;
use HTTP::Cookies;
use HTTP::Request;
use LWP::ConnCache;
use LWP::UserAgent;
use IO::Socket::SSL;

use constant P5NS => 'VMOMI';

sub AUTOLOAD {
    my $self = shift;
    my $name = our $AUTOLOAD;
        
    return if $name =~ /::DESTROY$/;
    $name =~ s/.*:://;
    
    if (not exists $self->{$name}) {
        Exception::Autoload->throw(message => "unknown accessor '$name' in " . ref $self);
    }
    
    $self->{$name} = shift if @_;
    return $self->{$name};
}

sub new {
    my ($class, %args) = @_;
    my ($self, $scheme, $host, $port, $path, $sslKey, $sslCrt, $service_uri, $user_agent,
        $cookie_jar, $conn_cache, $ssl_opts, $version, $namespace);
    
    $scheme     = delete($args{'scheme'})           || 'https';
    $host       = delete($args{'host'})             || 'localhost';
    $port       = delete($args{'port'})             || '443';
    $path       = delete($args{'path'})             || '/sdk';
    $sslKey     = delete($args{'sslKey'})           || 'ssl/client.key';
    $sslCrt     = delete($args{'sslCrt'})           || 'ssl/client.crt';
    #$tunnelPort = delete($args{'sdkTunnelPort'})   || '8089';
    #$tunnelHost = delete($args{'sdkTunnelHost'})   || 'sdkTunnel';
    
    $service_uri = new URI();
    $service_uri->scheme($scheme);
    $service_uri->host($host);
    $service_uri->port($port);
    $service_uri->path($path);
    
    #$tunnel_uri = new URI();
    #$tunnel_uri->scheme($scheme);
    #$tunnel_uri->host($tunnelHost);
    #$tunnel_uri->port($tunnelPort);
    #$tunnel_uri->path($path);
    
    $self = bless {
        'user_agent'    => undef,
        'soap_action'   => '""',
        'service_uri'   => $service_uri,
    }, $class;
    
    $ssl_opts = {
        verify_hostname => 0,
        SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_NONE,
        #SSL_key_file    => $sslKey,
        #SSL_cert_file   => $sslCrt, 
    };
    
    $user_agent = new LWP::UserAgent(
        agent    => $self->agent_string,
        ssl_opts => $ssl_opts,
    );
    
    $conn_cache = new LWP::ConnCache();
    $cookie_jar = new HTTP::Cookies(ignore_discard => 1);
    
    $user_agent->cookie_jar($cookie_jar);
    $user_agent->protocols_allowed(['http', 'https']);
    $user_agent->conn_cache($conn_cache);
    
    $self->user_agent($user_agent);
    
    # Query service namespace and version; generate soap_action
    $version    = $self->service_version;
    $namespace  = $self->service_namespace;
    
    if (defined $namespace and defined $version) {
        $self->soap_action($namespace . "/" . $version);
    } else {
        return undef;
    }
    
    return $self;
}

sub agent_string {
    return "Perl/VMOMI";
}

sub service_version {
    my $self = shift;
    
    return $self->{'service_version'} if defined $self->{'service_version'};
    
    my ($req, $res, $uri, $xml, $doc, $namespaces, $version);
    
    $uri = $self->service_uri->clone;
    $uri->path($uri->path . "/vimServiceVersions.xml");
    
    $req = new HTTP::Request();
    $req->uri($uri);
    $req->method('GET');
    $req->content_type('text/xml');
    
    $res = $self->user_agent->request($req);
    $xml = new XML::LibXML();
    
    # TODO: verify is_error will not have false positives for non 200 codes from the API
    if ($res->is_error) {
        Exception::Protocol->throw(
            message => "Failed to retrieve server version at '" . $uri->as_string . "' (" .
                $res->status_line . ")\n"
        );
    }
            
    eval { 
        $doc = $xml->parse_string($res->content) 
    };
    
    # If parse_string() does not parse clean, there must be a connection or protocol error.
    # Set error to the response status line as the XML error will be non-descriptive.
    if ($@) {
        Exception::Protocol->throw(
            message => $res->status_line,
        );
    }
    
    $namespaces = $doc->documentElement->getChildrenByTagName('namespace');
    foreach my $ns (@{ $namespaces || [ ] }) {
        my ($name);
        $name = $ns->getChildrenByTagName('name')->shift;
        if ($name->textContent eq 'urn:vim25') {
            $version = $ns->getChildrenByTagName('version')->shift->textContent;
        }
    }
    return $self->{'service_version'} = $version;
}

sub service_namespace {
    my $self = shift;
    
    return $self->{'service_namespace'} if defined $self->{'service_namespace'};
    
    my ($req, $res, $uri, $xml, $doc, $target, $namespace);
    
    $uri = $self->service_uri->clone;
    $uri->path($uri->path . "/vimService.wsdl");
    
    $req = new HTTP::Request();
    $req->uri($uri);
    $req->method('GET');
    $req->content_type('text/xml');
    
    $res = $self->user_agent->request($req);
    $xml = new XML::LibXML();

    # Verify is_error will not have false positives for non 200 codes from the vSphere API 
    if ($res->is_error) {
        Exception::Protocol->throw(
            message => "Failed to retrieve server namespace at '" . $uri->as_string . 
                "' (" . $res->status_line . ")\n"
        );
    }
    
    
    
    # If parse_string() does not parse clean, there must have been a connection or other
    # protocol error.  Set error to the response status line as the XML error should be 
    # non-descriptive.
    eval { $doc = $xml->parse_string($res->content) };
    if ($@) {
        Exception::Protocol->throw(message => $res->status_line);
    }
    
    $target = $doc->documentElement->getAttribute('targetNamespace');
    if (defined $target) {
        ($namespace) = $target =~ /^(urn:vim[0-9a-zA-Z]+)(?:Service)/;
    } else {
        Exception::Protocol->throw(
            message => "Service target namespace (" . $uri->path . ") unavailable: $@",
        );
    }
    return $self->{'service_namespace'} = $namespace;
}

sub soap_call {
    my ($self, $operation, $ret_type, $is_array, $x_args, $v_args) = @_;
    my ($xmldoc, $envelope, $body, $namespace, $soap_action, $uri, $request, $response, 
        $reader, @returnval, $result, $fault );
         
    # SOAP Envelope
    $xmldoc = new XML::LibXML::Document("1.0", "UTF-8");
    $envelope = $xmldoc->createElement("soapenv:Envelope");
    $envelope->setAttributeNS(
        "http://www.w3.org/2000/xmlns/", 
        "xmlns:soapenv", 
        "http://schemas.xmlsoap.org/soap/envelope/" );
    $envelope->setAttributeNS(
        "http://www.w3.org/2000/xmlns/", 
        "xmlns:xsd", 
        "http://www.w3.org/2001/XMLSchema" );
    $envelope->setAttributeNS(
        "http://www.w3.org/2000/xmlns/", 
        "xmlns:xsi", 
        "http://www.w3.org/2001/XMLSchema-instance" );
    $body = new XML::LibXML::Element("soapenv:Body");
    $envelope->addChild($body);
    
    $operation = new XML::LibXML::Element($operation);
    $namespace = $self->service_namespace;
    $operation->setAttribute("xmlns", $namespace);
    
    # Enumerate expected arguments
    foreach (@$x_args) {
        my ($x_name, $x_type, $v_value, $v_type, $node);
        
        ($x_name, $x_type) = @$_;
        if (exists $v_args->{$x_name}) {
            my $v_value = delete($v_args->{$x_name});
            my $v_type  = ref $v_value;
            
            if ($v_type eq 'ARRAY') {
                foreach (@$v_value) {
                    my $c_type = ref $_;
                    $c_type =~ s/.*:://;
                    $node = $self->soap_node($_, $c_type, $x_name, $x_type);
                    $operation->addChild($node);
                }
            } elsif (defined $v_value) {
                $v_type =~ s/.*:://;
                $node = $self->soap_node($v_value, $v_type, $x_name, $x_type);
                $operation->addChild($node);
            } else {
                $node = new XML::LibXML::Element($x_name);
                $operation->addChild($node);
            }
        }
    }
    $body->addChild($operation);
    $xmldoc->addChild($envelope);
    
    # SOAP Action
    $soap_action = $self->service_namespace . "/" . $self->service_version;
    
    # SOAP Request  
    $uri = $self->service_uri;
    $request = new HTTP::Request();
    $request->method('POST');
    $request->uri($uri);
    $request->content_type('text/xml');
    $request->content($xmldoc->toString);
    $request->header(SOAPAction => $soap_action);

    # SOAP Response
    $response = $self->user_agent->request($request);
    
    # Review error handling for the reader interface; return to status code evaluation?
    $reader = new XML::LibXML::Reader(string => $response->content);
    
    # Parse for soapenv:Fault and soapenv:Body
    while ($reader->read) {
        my ($name, $type, $depth, $class, $content, $value);
        
        $name  = $reader->name;
        $type  = $reader->nodeType;
        $depth = $reader->depth;
        
        if ($name =~ m/returnval/ and $type == 1 and $depth == 3) {
            # Would there be a need to check type attribute and call an emit_type?
            # TODO: Create a base boolean type to simplify deserialization!
            if (defined $ret_type) {
                if ($ret_type eq 'boolean') {
                    $content = $reader->readInnerXml;
                    if ($content =~ m/(true|1)/i) {
                        $value = 1;
                    } elsif ($content =~ m/(false|0)/i) {
                        $value = 0;
                    } else {
                        Exception::Deserialize(
                            message => "deserialization error: server returned '$value' as a boolean"
                        );
                    }
                    push @returnval, $value;
                } else {
                    $class = P5NS . "::$ret_type";
                    $value = $class->deserialize($reader, $self);
                    push @returnval, $value;
                }
            } else {
                $value = $reader->readInnerXml;
                push @returnval, $value;    
            }
        }
        if ($name =~ m/soapenv:Fault/ and $type == 1 and $depth == 2) {
            $fault = $self->soap_fault($reader);
        }
    }
    
    if ($is_array) {
        $result = \@returnval;
    } else {
        $result = pop @returnval;
    }
    
    Exception::SoapFault->throw(
        message     => $fault->{'faultstring'},
        detail      => $fault->{'detail'},
        faultcode   => $fault->{'faultcode'}
    ) if $fault;

    return $result;
}


sub soap_node {
    my ($self, $value, $type, $x_name, $x_type) = @_;
    my ($node);
    
    
    if (defined $x_type) {        
        if (defined $value) {
            # boolean
            if ($x_type eq 'boolean') {
                if ($value =~ m/(true|1)/i) {
                    $value = 'true';
                } elsif ($value =~ m/(false|0)/i) {
                    $value = 'false';
                } else {
                    Exception::Serialize->throw(
                        message => "serialization error: cannot convert '$value' to" .
                            " boolean for member '$x_name'"
                    );
                }
                $node = new XML::LibXML::Element($x_name);
                $node->appendText($value);
                return $node
            }
        
            # ManagedObjectReference
            if ($x_type eq 'ManagedObjectReference') {
                if ($value->isa(P5NS . "::ManagedObject")) {
                    if (exists $value->{'_moref'}) {
                        $value = $value->{'_moref'};
                    }
                } elsif (not $type eq 'ManagedObjectReference') {
                    Exception::Serialize->throw(
                        message => "serialization error: expected $x_type, not $type for" .
                            " member '$x_name'"
                    );
                }
            }
            
            if ($type ne $x_type) {
                $node = $value->serialize($x_name, $type);
            } else {
                $node = $value->serialize($x_name);
            }
        }   
    } else {
        # xsi type (string, int, double, etc)
        if (defined $value) {
            $node = new XML::LibXML::Element($x_name);
            $node->appendText($value);
        }
    }
    return $node;
}

sub soap_fault {
    my ($self, $reader) = @_;
    my ($node_name, $node_depth, $node_type, $name, $depth, $type, $fault);
    
    $fault = { };
    
    $node_name  = $reader->name;
    $node_depth = $reader->depth;
    $node_type  = $reader->nodeType;
    
    do {
        $reader->read;
        
        my ($class, $xsi_type);
        
        $name  = $reader->name; 
        $depth = $reader->depth;
        $type  = $reader->nodeType;
                
        if ($name =~ m/faultcode/   and $type == 1  and $depth == 3) {
            $fault->{faultcode} = $reader->readInnerXml;
        }
        if ($name =~ m/faultstring/ and $type == 1  and $depth == 3) {
            $fault->{faultstring} = $reader->readInnerXml;
        }
        if ($name =~ m/detail/      and $type == 1  and $depth == 3) {
            $reader->read;
            
            $name = $reader->name;
            $name =~ m/(.*)Fault/;
            $class = P5NS . "::$1";
            $fault->{detail} = $class->deserialize($reader);
        }
    } until ($name eq $node_name and $type != $node_type and $depth == $node_depth);
    
    return $fault;
}

1;
