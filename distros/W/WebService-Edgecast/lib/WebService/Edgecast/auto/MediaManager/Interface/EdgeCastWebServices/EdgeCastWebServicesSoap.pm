package WebService::Edgecast::auto::MediaManager::Interface::EdgeCastWebServices::EdgeCastWebServicesSoap;
BEGIN {
  $WebService::Edgecast::auto::MediaManager::Interface::EdgeCastWebServices::EdgeCastWebServicesSoap::VERSION = '0.01.00';
}
use strict;
use warnings;
use Class::Std::Fast::Storable;
use Scalar::Util qw(blessed);
use base qw(SOAP::WSDL::Client::Base);

# only load if it hasn't been loaded before
require WebService::Edgecast::auto::MediaManager::Typemap::EdgeCastWebServices
    if not WebService::Edgecast::auto::MediaManager::Typemap::EdgeCastWebServices->can('get_class');

sub START {
    $_[0]->set_proxy('https://api.edgecast.com/v1/MediaManager.asmx') if not $_[2]->{proxy};
    $_[0]->set_class_resolver('WebService::Edgecast::auto::MediaManager::Typemap::EdgeCastWebServices')
        if not $_[2]->{class_resolver};

    $_[0]->set_prefix($_[2]->{use_prefix}) if exists $_[2]->{use_prefix};
}

sub PurgeFileFromEdge {
    my ($self, $body, $header) = @_;
    die "PurgeFileFromEdge must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'PurgeFileFromEdge',
        soap_action => 'EC:WebServices/PurgeFileFromEdge',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::MediaManager::Element::PurgeFileFromEdge )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub PurgeFileFromEdgeMemory {
    my ($self, $body, $header) = @_;
    die "PurgeFileFromEdgeMemory must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'PurgeFileFromEdgeMemory',
        soap_action => 'EC:WebServices/PurgeFileFromEdgeMemory',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::MediaManager::Element::PurgeFileFromEdgeMemory )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub LoadFileToEdge {
    my ($self, $body, $header) = @_;
    die "LoadFileToEdge must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'LoadFileToEdge',
        soap_action => 'EC:WebServices/LoadFileToEdge',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::MediaManager::Element::LoadFileToEdge )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub TokenKeyUpdate {
    my ($self, $body, $header) = @_;
    die "TokenKeyUpdate must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'TokenKeyUpdate',
        soap_action => 'EC:WebServices/TokenKeyUpdate',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::MediaManager::Element::TokenKeyUpdate )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub TokenDirAdd {
    my ($self, $body, $header) = @_;
    die "TokenDirAdd must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'TokenDirAdd',
        soap_action => 'EC:WebServices/TokenDirAdd',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::MediaManager::Element::TokenDirAdd )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub TokenEncrypt {
    my ($self, $body, $header) = @_;
    die "TokenEncrypt must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'TokenEncrypt',
        soap_action => 'EC:WebServices/TokenEncrypt',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::MediaManager::Element::TokenEncrypt )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub FmsLiveAuthGlobalKeyGet {
    my ($self, $body, $header) = @_;
    die "FmsLiveAuthGlobalKeyGet must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'FmsLiveAuthGlobalKeyGet',
        soap_action => 'EC:WebServices/FmsLiveAuthGlobalKeyGet',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::MediaManager::Element::FmsLiveAuthGlobalKeyGet )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub FmsLiveAuthGlobalKeyUpdate {
    my ($self, $body, $header) = @_;
    die "FmsLiveAuthGlobalKeyUpdate must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'FmsLiveAuthGlobalKeyUpdate',
        soap_action => 'EC:WebServices/FmsLiveAuthGlobalKeyUpdate',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::MediaManager::Element::FmsLiveAuthGlobalKeyUpdate )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub FmsLiveAuthStreamKeysGet {
    my ($self, $body, $header) = @_;
    die "FmsLiveAuthStreamKeysGet must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'FmsLiveAuthStreamKeysGet',
        soap_action => 'EC:WebServices/FmsLiveAuthStreamKeysGet',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::MediaManager::Element::FmsLiveAuthStreamKeysGet )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub FmsLiveAuthStreamKeyGet {
    my ($self, $body, $header) = @_;
    die "FmsLiveAuthStreamKeyGet must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'FmsLiveAuthStreamKeyGet',
        soap_action => 'EC:WebServices/FmsLiveAuthStreamKeyGet',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::MediaManager::Element::FmsLiveAuthStreamKeyGet )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub FmsLiveAuthStreamKeyAdd {
    my ($self, $body, $header) = @_;
    die "FmsLiveAuthStreamKeyAdd must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'FmsLiveAuthStreamKeyAdd',
        soap_action => 'EC:WebServices/FmsLiveAuthStreamKeyAdd',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::MediaManager::Element::FmsLiveAuthStreamKeyAdd )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub FmsLiveAuthStreamKeyDelete {
    my ($self, $body, $header) = @_;
    die "FmsLiveAuthStreamKeyDelete must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'FmsLiveAuthStreamKeyDelete',
        soap_action => 'EC:WebServices/FmsLiveAuthStreamKeyDelete',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::MediaManager::Element::FmsLiveAuthStreamKeyDelete )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub FmsLiveAuthStreamKeyUpdate {
    my ($self, $body, $header) = @_;
    die "FmsLiveAuthStreamKeyUpdate must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'FmsLiveAuthStreamKeyUpdate',
        soap_action => 'EC:WebServices/FmsLiveAuthStreamKeyUpdate',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::MediaManager::Element::FmsLiveAuthStreamKeyUpdate )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub WmsPubPointMethodsGet {
    my ($self, $body, $header) = @_;
    die "WmsPubPointMethodsGet must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'WmsPubPointMethodsGet',
        soap_action => 'EC:WebServices/WmsPubPointMethodsGet',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::MediaManager::Element::WmsPubPointMethodsGet )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub WmsPubPointGet {
    my ($self, $body, $header) = @_;
    die "WmsPubPointGet must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'WmsPubPointGet',
        soap_action => 'EC:WebServices/WmsPubPointGet',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::MediaManager::Element::WmsPubPointGet )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub WmsPubPointsGet {
    my ($self, $body, $header) = @_;
    die "WmsPubPointsGet must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'WmsPubPointsGet',
        soap_action => 'EC:WebServices/WmsPubPointsGet',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::MediaManager::Element::WmsPubPointsGet )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub WmsPubPointAdd {
    my ($self, $body, $header) = @_;
    die "WmsPubPointAdd must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'WmsPubPointAdd',
        soap_action => 'EC:WebServices/WmsPubPointAdd',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::MediaManager::Element::WmsPubPointAdd )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub WmsPubPointDelete {
    my ($self, $body, $header) = @_;
    die "WmsPubPointDelete must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'WmsPubPointDelete',
        soap_action => 'EC:WebServices/WmsPubPointDelete',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::MediaManager::Element::WmsPubPointDelete )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub WmsPubPointUpdate {
    my ($self, $body, $header) = @_;
    die "WmsPubPointUpdate must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'WmsPubPointUpdate',
        soap_action => 'EC:WebServices/WmsPubPointUpdate',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::MediaManager::Element::WmsPubPointUpdate )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}




1;



__END__

=pod

=head1 NAME

WebService::Edgecast::auto::MediaManager::Interface::EdgeCastWebServices::EdgeCastWebServicesSoap - SOAP Interface for the EdgeCastWebServices Web Service

=head1 VERSION

version 0.01.00

=head1 SYNOPSIS

 use WebService::Edgecast::auto::MediaManager::Interface::EdgeCastWebServices::EdgeCastWebServicesSoap;
 my $interface = WebService::Edgecast::auto::MediaManager::Interface::EdgeCastWebServices::EdgeCastWebServicesSoap->new();

 my $response;
 $response = $interface->PurgeFileFromEdge();
 $response = $interface->PurgeFileFromEdgeMemory();
 $response = $interface->LoadFileToEdge();
 $response = $interface->TokenKeyUpdate();
 $response = $interface->TokenDirAdd();
 $response = $interface->TokenEncrypt();
 $response = $interface->FmsLiveAuthGlobalKeyGet();
 $response = $interface->FmsLiveAuthGlobalKeyUpdate();
 $response = $interface->FmsLiveAuthStreamKeysGet();
 $response = $interface->FmsLiveAuthStreamKeyGet();
 $response = $interface->FmsLiveAuthStreamKeyAdd();
 $response = $interface->FmsLiveAuthStreamKeyDelete();
 $response = $interface->FmsLiveAuthStreamKeyUpdate();
 $response = $interface->WmsPubPointMethodsGet();
 $response = $interface->WmsPubPointGet();
 $response = $interface->WmsPubPointsGet();
 $response = $interface->WmsPubPointAdd();
 $response = $interface->WmsPubPointDelete();
 $response = $interface->WmsPubPointUpdate();



=head1 DESCRIPTION

SOAP Interface for the EdgeCastWebServices web service
located at https://api.edgecast.com/v1/MediaManager.asmx.

=head1 SERVICE EdgeCastWebServices

API for integrating with the EdgeCast CDN Media Manager

=head2 Port EdgeCastWebServicesSoap



=head1 METHODS

=head2 General methods

=head3 new

Constructor.

All arguments are forwarded to L<SOAP::WSDL::Client|SOAP::WSDL::Client>.

=head2 SOAP Service methods

Method synopsis is displayed with hash refs as parameters.

The commented class names in the method's parameters denote that objects
of the corresponding class can be passed instead of the marked hash ref.

You may pass any combination of objects, hash and list refs to these
methods, as long as you meet the structure.

List items (i.e. multiple occurences) are not displayed in the synopsis.
You may generally pass a list ref of hash refs (or objects) instead of a hash
ref - this may result in invalid XML if used improperly, though. Note that
SOAP::WSDL always expects list references at maximum depth position.

XML attributes are not displayed in this synopsis and cannot be set using
hash refs. See the respective class' documentation for additional information.



=head3 PurgeFileFromEdge

This function will purge a file from the edge servers. <br>Media Type: 3=HTTP Large Object, 8=HTTP Small Object, 2=Flash, 1=Windows, 14=ADN<br>Path: May be to a folder or file. To specify a folder, please put a trailing slash at the end of the URL. Include a wildcard (*) after the slash to purge recursively, or leave it out to purge non-recursively. Both cnames and AN paths are allowed.

Returns a L<WebService::Edgecast::auto::MediaManager::Element::PurgeFileFromEdgeResponse|WebService::Edgecast::auto::MediaManager::Element::PurgeFileFromEdgeResponse> object.

 $response = $interface->PurgeFileFromEdge( {
    strCredential =>  $some_value, # string
    strCustomerId =>  $some_value, # string
    strPath =>  $some_value, # string
    intMediaType =>  $some_value, # int
  },,
 );

=head3 PurgeFileFromEdgeMemory

Deprecated. Use PurgeFileFromEdge. 

Returns a L<WebService::Edgecast::auto::MediaManager::Element::PurgeFileFromEdgeMemoryResponse|WebService::Edgecast::auto::MediaManager::Element::PurgeFileFromEdgeMemoryResponse> object.

 $response = $interface->PurgeFileFromEdgeMemory( {
    strCredential =>  $some_value, # string
    strCustomerId =>  $some_value, # string
    strPath =>  $some_value, # string
    intMediaType =>  $some_value, # int
  },,
 );

=head3 LoadFileToEdge

Load file from origin to edge servers.<br>Media Type: 3=HTTP Large Object, 8=HTTP Small Object, 2=Flash, 14=ADN. Windows is not available at this time.<br>Path: Should be to a file. Folders may not be loaded and will be ignored. Both cnames and AN paths are allowed.

Returns a L<WebService::Edgecast::auto::MediaManager::Element::LoadFileToEdgeResponse|WebService::Edgecast::auto::MediaManager::Element::LoadFileToEdgeResponse> object.

 $response = $interface->LoadFileToEdge( {
    strCredential =>  $some_value, # string
    strCustomerId =>  $some_value, # string
    strPath =>  $some_value, # string
    intMediaType =>  $some_value, # int
  },,
 );

=head3 TokenKeyUpdate

Update Token Authentication Key. This key is used to create the encrypted token.<br>Required fields: strCredential, strCustomerId, strKey, intMediaType <br>Media Type: 3=HTTP Large Object, 8=HTTP Small Object, 2=Flash, 1=Windows<br>

Returns a L<WebService::Edgecast::auto::MediaManager::Element::TokenKeyUpdateResponse|WebService::Edgecast::auto::MediaManager::Element::TokenKeyUpdateResponse> object.

 $response = $interface->TokenKeyUpdate( {
    strCredential =>  $some_value, # string
    strCustomerId =>  $some_value, # string
    strKey =>  $some_value, # string
    intMediaType =>  $some_value, # int
  },,
 );

=head3 TokenDirAdd

Add Token Authentication Directory. <br>All additions and changes should be processed every 30 minutes. <br>Directory Path should be starting from the root. Example: /directory1/directory2 <br>Required fields: strCredential, strCustomerId, strDir, intMediaType <br>Media Type: 3=HTTP Large Object, 8=HTTP Small Object, 2=Flash, 1=Windows<br>

Returns a L<WebService::Edgecast::auto::MediaManager::Element::TokenDirAddResponse|WebService::Edgecast::auto::MediaManager::Element::TokenDirAddResponse> object.

 $response = $interface->TokenDirAdd( {
    strCredential =>  $some_value, # string
    strCustomerId =>  $some_value, # string
    strDir =>  $some_value, # string
    intMediaType =>  $some_value, # int
  },,
 );

=head3 TokenEncrypt

Create an encrypted token. <br>Required fields: strCredential, strKey, strArgs<br>Key: A unique key of your choice, used to create the encrypted token. This key must also be set using TokenKeyUpdate or set in the Media Control Center.<br>Args: Arguments. Example: ec_expire=1185943200&ec_country_deny=US

Returns a L<WebService::Edgecast::auto::MediaManager::Element::TokenEncryptResponse|WebService::Edgecast::auto::MediaManager::Element::TokenEncryptResponse> object.

 $response = $interface->TokenEncrypt( {
    strCredential =>  $some_value, # string
    strKey =>  $some_value, # string
    strArgs =>  $some_value, # string
  },,
 );

=head3 FmsLiveAuthGlobalKeyGet

This method call will get the customer's FMS Live Auth Global Key. <br>

Returns a L<WebService::Edgecast::auto::MediaManager::Element::FmsLiveAuthGlobalKeyGetResponse|WebService::Edgecast::auto::MediaManager::Element::FmsLiveAuthGlobalKeyGetResponse> object.

 $response = $interface->FmsLiveAuthGlobalKeyGet( {
    strCredential =>  $some_value, # string
    strCustomerId =>  $some_value, # string
  },,
 );

=head3 FmsLiveAuthGlobalKeyUpdate

This method call will update the customer's FMS Live Auth Global Key. <br>

Returns a L<WebService::Edgecast::auto::MediaManager::Element::FmsLiveAuthGlobalKeyUpdateResponse|WebService::Edgecast::auto::MediaManager::Element::FmsLiveAuthGlobalKeyUpdateResponse> object.

 $response = $interface->FmsLiveAuthGlobalKeyUpdate( {
    strCredential =>  $some_value, # string
    strCustomerId =>  $some_value, # string
    strGlobalKey =>  $some_value, # string
  },,
 );

=head3 FmsLiveAuthStreamKeysGet

This method call will get all FMS Live Auth Stream Keys. <br>

Returns a L<WebService::Edgecast::auto::MediaManager::Element::FmsLiveAuthStreamKeysGetResponse|WebService::Edgecast::auto::MediaManager::Element::FmsLiveAuthStreamKeysGetResponse> object.

 $response = $interface->FmsLiveAuthStreamKeysGet( {
    strCredential =>  $some_value, # string
    strCustomerId =>  $some_value, # string
  },,
 );

=head3 FmsLiveAuthStreamKeyGet

This method call will get a FMS Live Auth Stream Key, given its unique ID. <br>

Returns a L<WebService::Edgecast::auto::MediaManager::Element::FmsLiveAuthStreamKeyGetResponse|WebService::Edgecast::auto::MediaManager::Element::FmsLiveAuthStreamKeyGetResponse> object.

 $response = $interface->FmsLiveAuthStreamKeyGet( {
    strCredential =>  $some_value, # string
    strCustomerId =>  $some_value, # string
    intId =>  $some_value, # int
  },,
 );

=head3 FmsLiveAuthStreamKeyAdd

This method call will add a FMS Live Auth Stream Key. <br>Note that the stream path starts after the AN portion of your URL.

Returns a L<WebService::Edgecast::auto::MediaManager::Element::FmsLiveAuthStreamKeyAddResponse|WebService::Edgecast::auto::MediaManager::Element::FmsLiveAuthStreamKeyAddResponse> object.

 $response = $interface->FmsLiveAuthStreamKeyAdd( {
    strCredential =>  $some_value, # string
    strCustomerId =>  $some_value, # string
    strStreamKey =>  $some_value, # string
    strStreamPath =>  $some_value, # string
  },,
 );

=head3 FmsLiveAuthStreamKeyDelete

This method call will delete a FMS Live Auth Stream Key, given its unique ID. <br>

Returns a L<WebService::Edgecast::auto::MediaManager::Element::FmsLiveAuthStreamKeyDeleteResponse|WebService::Edgecast::auto::MediaManager::Element::FmsLiveAuthStreamKeyDeleteResponse> object.

 $response = $interface->FmsLiveAuthStreamKeyDelete( {
    strCredential =>  $some_value, # string
    strCustomerId =>  $some_value, # string
    intId =>  $some_value, # int
  },,
 );

=head3 FmsLiveAuthStreamKeyUpdate

This method call will update a FMS Live Auth Stream Key, given its unique ID. <br>Note that the stream path starts after the AN portion of your URL.

Returns a L<WebService::Edgecast::auto::MediaManager::Element::FmsLiveAuthStreamKeyUpdateResponse|WebService::Edgecast::auto::MediaManager::Element::FmsLiveAuthStreamKeyUpdateResponse> object.

 $response = $interface->FmsLiveAuthStreamKeyUpdate( {
    strCredential =>  $some_value, # string
    strCustomerId =>  $some_value, # string
    intId =>  $some_value, # int
    strStreamKey =>  $some_value, # string
    strStreamPath =>  $some_value, # string
  },,
 );

=head3 WmsPubPointMethodsGet

This method call will get all WMS Publishing Point Encoding Methods. <br>

Returns a L<WebService::Edgecast::auto::MediaManager::Element::WmsPubPointMethodsGetResponse|WebService::Edgecast::auto::MediaManager::Element::WmsPubPointMethodsGetResponse> object.

 $response = $interface->WmsPubPointMethodsGet( {
    strCredential =>  $some_value, # string
    strCustomerId =>  $some_value, # string
  },,
 );

=head3 WmsPubPointGet

This method call will get a WMS Publishing Point, given its unique ID. <br>

Returns a L<WebService::Edgecast::auto::MediaManager::Element::WmsPubPointGetResponse|WebService::Edgecast::auto::MediaManager::Element::WmsPubPointGetResponse> object.

 $response = $interface->WmsPubPointGet( {
    strCredential =>  $some_value, # string
    strCustomerId =>  $some_value, # string
    intId =>  $some_value, # int
  },,
 );

=head3 WmsPubPointsGet

This method call will get all WMS Publishing Points. <br>

Returns a L<WebService::Edgecast::auto::MediaManager::Element::WmsPubPointsGetResponse|WebService::Edgecast::auto::MediaManager::Element::WmsPubPointsGetResponse> object.

 $response = $interface->WmsPubPointsGet( {
    strCredential =>  $some_value, # string
    strCustomerId =>  $some_value, # string
  },,
 );

=head3 WmsPubPointAdd

This method call will add a WMS Publishing Point. <br>

Returns a L<WebService::Edgecast::auto::MediaManager::Element::WmsPubPointAddResponse|WebService::Edgecast::auto::MediaManager::Element::WmsPubPointAddResponse> object.

 $response = $interface->WmsPubPointAdd( {
    strCredential =>  $some_value, # string
    strCustomerId =>  $some_value, # string
    strName =>  $some_value, # string
    intMethodId =>  $some_value, # int
    strPullSourceUrl =>  $some_value, # string
    blnEnableBuffering =>  $some_value, # boolean
  },,
 );

=head3 WmsPubPointDelete

This method call will delete a WMS Publishing Point, given its unique ID. <br>

Returns a L<WebService::Edgecast::auto::MediaManager::Element::WmsPubPointDeleteResponse|WebService::Edgecast::auto::MediaManager::Element::WmsPubPointDeleteResponse> object.

 $response = $interface->WmsPubPointDelete( {
    strCredential =>  $some_value, # string
    strCustomerId =>  $some_value, # string
    intId =>  $some_value, # int
  },,
 );

=head3 WmsPubPointUpdate

This method call will update a WMS Publishing Point, given its unique ID. <br>

Returns a L<WebService::Edgecast::auto::MediaManager::Element::WmsPubPointUpdateResponse|WebService::Edgecast::auto::MediaManager::Element::WmsPubPointUpdateResponse> object.

 $response = $interface->WmsPubPointUpdate( {
    strCredential =>  $some_value, # string
    strCustomerId =>  $some_value, # string
    intId =>  $some_value, # int
    strName =>  $some_value, # string
    intMethodId =>  $some_value, # int
    strPullSourceUrl =>  $some_value, # string
    blnEnableBuffering =>  $some_value, # boolean
  },,
 );



=head1 AUTHOR

Generated by SOAP::WSDL on Wed Dec 22 13:08:32 2010

=cut