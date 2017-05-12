package WebService::Edgecast::auto::Administration::Interface::EdgeCastWebServices::EdgeCastWebServicesSoap;
BEGIN {
  $WebService::Edgecast::auto::Administration::Interface::EdgeCastWebServices::EdgeCastWebServicesSoap::VERSION = '0.01.00';
}
use strict;
use warnings;
use Class::Std::Fast::Storable;
use Scalar::Util qw(blessed);
use base qw(SOAP::WSDL::Client::Base);

# only load if it hasn't been loaded before
require WebService::Edgecast::auto::Administration::Typemap::EdgeCastWebServices
    if not WebService::Edgecast::auto::Administration::Typemap::EdgeCastWebServices->can('get_class');

sub START {
    $_[0]->set_proxy('https://api.edgecast.com/v1/Administration.asmx') if not $_[2]->{proxy};
    $_[0]->set_class_resolver('WebService::Edgecast::auto::Administration::Typemap::EdgeCastWebServices')
        if not $_[2]->{class_resolver};

    $_[0]->set_prefix($_[2]->{use_prefix}) if exists $_[2]->{use_prefix};
}

sub CustomersGet {
    my ($self, $body, $header) = @_;
    die "CustomersGet must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'CustomersGet',
        soap_action => 'EC:WebServices/CustomersGet',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::Administration::Element::CustomersGet )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub CustomerGet {
    my ($self, $body, $header) = @_;
    die "CustomerGet must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'CustomerGet',
        soap_action => 'EC:WebServices/CustomerGet',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::Administration::Element::CustomerGet )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub CustomerAdd {
    my ($self, $body, $header) = @_;
    die "CustomerAdd must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'CustomerAdd',
        soap_action => 'EC:WebServices/CustomerAdd',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::Administration::Element::CustomerAdd )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub CustomerUpdate {
    my ($self, $body, $header) = @_;
    die "CustomerUpdate must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'CustomerUpdate',
        soap_action => 'EC:WebServices/CustomerUpdate',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::Administration::Element::CustomerUpdate )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub CustomerDelete {
    my ($self, $body, $header) = @_;
    die "CustomerDelete must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'CustomerDelete',
        soap_action => 'EC:WebServices/CustomerDelete',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::Administration::Element::CustomerDelete )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub CustomerUserAdd {
    my ($self, $body, $header) = @_;
    die "CustomerUserAdd must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'CustomerUserAdd',
        soap_action => 'EC:WebServices/CustomerUserAdd',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::Administration::Element::CustomerUserAdd )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub CustomerUserDelete {
    my ($self, $body, $header) = @_;
    die "CustomerUserDelete must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'CustomerUserDelete',
        soap_action => 'EC:WebServices/CustomerUserDelete',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::Administration::Element::CustomerUserDelete )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub CustomerUserUpdate {
    my ($self, $body, $header) = @_;
    die "CustomerUserUpdate must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'CustomerUserUpdate',
        soap_action => 'EC:WebServices/CustomerUserUpdate',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::Administration::Element::CustomerUserUpdate )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub CustomerUsersGet {
    my ($self, $body, $header) = @_;
    die "CustomerUsersGet must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'CustomerUsersGet',
        soap_action => 'EC:WebServices/CustomerUsersGet',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::Administration::Element::CustomerUsersGet )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub CustomerUserGet {
    my ($self, $body, $header) = @_;
    die "CustomerUserGet must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'CustomerUserGet',
        soap_action => 'EC:WebServices/CustomerUserGet',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::Administration::Element::CustomerUserGet )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub CustomerCustomIdUpdate {
    my ($self, $body, $header) = @_;
    die "CustomerCustomIdUpdate must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'CustomerCustomIdUpdate',
        soap_action => 'EC:WebServices/CustomerCustomIdUpdate',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::Administration::Element::CustomerCustomIdUpdate )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub CustomerAccountMeasuredByUpdate {
    my ($self, $body, $header) = @_;
    die "CustomerAccountMeasuredByUpdate must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'CustomerAccountMeasuredByUpdate',
        soap_action => 'EC:WebServices/CustomerAccountMeasuredByUpdate',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::Administration::Element::CustomerAccountMeasuredByUpdate )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub CustomerAccountMeasuredByGet {
    my ($self, $body, $header) = @_;
    die "CustomerAccountMeasuredByGet must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'CustomerAccountMeasuredByGet',
        soap_action => 'EC:WebServices/CustomerAccountMeasuredByGet',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::Administration::Element::CustomerAccountMeasuredByGet )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub CustomerStatusUpdate {
    my ($self, $body, $header) = @_;
    die "CustomerStatusUpdate must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'CustomerStatusUpdate',
        soap_action => 'EC:WebServices/CustomerStatusUpdate',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::Administration::Element::CustomerStatusUpdate )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub CustomerStatusGet {
    my ($self, $body, $header) = @_;
    die "CustomerStatusGet must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'CustomerStatusGet',
        soap_action => 'EC:WebServices/CustomerStatusGet',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::Administration::Element::CustomerStatusGet )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub CustomerHttpUpdate {
    my ($self, $body, $header) = @_;
    die "CustomerHttpUpdate must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'CustomerHttpUpdate',
        soap_action => 'EC:WebServices/CustomerHttpUpdate',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::Administration::Element::CustomerHttpUpdate )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub CustomerHttpGet {
    my ($self, $body, $header) = @_;
    die "CustomerHttpGet must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'CustomerHttpGet',
        soap_action => 'EC:WebServices/CustomerHttpGet',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::Administration::Element::CustomerHttpGet )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub CustomerHttpLargeGet {
    my ($self, $body, $header) = @_;
    die "CustomerHttpLargeGet must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'CustomerHttpLargeGet',
        soap_action => 'EC:WebServices/CustomerHttpLargeGet',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::Administration::Element::CustomerHttpLargeGet )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub CustomerHttpLargeUpdate {
    my ($self, $body, $header) = @_;
    die "CustomerHttpLargeUpdate must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'CustomerHttpLargeUpdate',
        soap_action => 'EC:WebServices/CustomerHttpLargeUpdate',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::Administration::Element::CustomerHttpLargeUpdate )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub CustomerHttpSmallUpdate {
    my ($self, $body, $header) = @_;
    die "CustomerHttpSmallUpdate must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'CustomerHttpSmallUpdate',
        soap_action => 'EC:WebServices/CustomerHttpSmallUpdate',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::Administration::Element::CustomerHttpSmallUpdate )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub CustomerHttpSmallGet {
    my ($self, $body, $header) = @_;
    die "CustomerHttpSmallGet must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'CustomerHttpSmallGet',
        soap_action => 'EC:WebServices/CustomerHttpSmallGet',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::Administration::Element::CustomerHttpSmallGet )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub CustomerFmsUpdate {
    my ($self, $body, $header) = @_;
    die "CustomerFmsUpdate must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'CustomerFmsUpdate',
        soap_action => 'EC:WebServices/CustomerFmsUpdate',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::Administration::Element::CustomerFmsUpdate )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub CustomerFmsGet {
    my ($self, $body, $header) = @_;
    die "CustomerFmsGet must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'CustomerFmsGet',
        soap_action => 'EC:WebServices/CustomerFmsGet',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::Administration::Element::CustomerFmsGet )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub CustomerWmsUpdate {
    my ($self, $body, $header) = @_;
    die "CustomerWmsUpdate must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'CustomerWmsUpdate',
        soap_action => 'EC:WebServices/CustomerWmsUpdate',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::Administration::Element::CustomerWmsUpdate )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub CustomerWmsGet {
    my ($self, $body, $header) = @_;
    die "CustomerWmsGet must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'CustomerWmsGet',
        soap_action => 'EC:WebServices/CustomerWmsGet',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::Administration::Element::CustomerWmsGet )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub CustomerAccessModuleUpdate {
    my ($self, $body, $header) = @_;
    die "CustomerAccessModuleUpdate must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'CustomerAccessModuleUpdate',
        soap_action => 'EC:WebServices/CustomerAccessModuleUpdate',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::Administration::Element::CustomerAccessModuleUpdate )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub CustomerAccessModuleGet {
    my ($self, $body, $header) = @_;
    die "CustomerAccessModuleGet must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'CustomerAccessModuleGet',
        soap_action => 'EC:WebServices/CustomerAccessModuleGet',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::Administration::Element::CustomerAccessModuleGet )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub CustomerUserAccessModuleUpdate {
    my ($self, $body, $header) = @_;
    die "CustomerUserAccessModuleUpdate must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'CustomerUserAccessModuleUpdate',
        soap_action => 'EC:WebServices/CustomerUserAccessModuleUpdate',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::Administration::Element::CustomerUserAccessModuleUpdate )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub CustomerUserAccessModuleGet {
    my ($self, $body, $header) = @_;
    die "CustomerUserAccessModuleGet must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'CustomerUserAccessModuleGet',
        soap_action => 'EC:WebServices/CustomerUserAccessModuleGet',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::Administration::Element::CustomerUserAccessModuleGet )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub CustomerOriginAdvancedUpdate {
    my ($self, $body, $header) = @_;
    die "CustomerOriginAdvancedUpdate must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'CustomerOriginAdvancedUpdate',
        soap_action => 'EC:WebServices/CustomerOriginAdvancedUpdate',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::Administration::Element::CustomerOriginAdvancedUpdate )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub CustomerOriginUpdate {
    my ($self, $body, $header) = @_;
    die "CustomerOriginUpdate must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'CustomerOriginUpdate',
        soap_action => 'EC:WebServices/CustomerOriginUpdate',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::Administration::Element::CustomerOriginUpdate )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub DeliveryRegionsGet {
    my ($self, $body, $header) = @_;
    die "DeliveryRegionsGet must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'DeliveryRegionsGet',
        soap_action => 'EC:WebServices/DeliveryRegionsGet',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::Administration::Element::DeliveryRegionsGet )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub CustomerDeliveryRegionUpdate {
    my ($self, $body, $header) = @_;
    die "CustomerDeliveryRegionUpdate must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'CustomerDeliveryRegionUpdate',
        soap_action => 'EC:WebServices/CustomerDeliveryRegionUpdate',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::Administration::Element::CustomerDeliveryRegionUpdate )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub CustomerOriginAdvancedAdd {
    my ($self, $body, $header) = @_;
    die "CustomerOriginAdvancedAdd must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'CustomerOriginAdvancedAdd',
        soap_action => 'EC:WebServices/CustomerOriginAdvancedAdd',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::Administration::Element::CustomerOriginAdvancedAdd )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub CustomerOriginAdd {
    my ($self, $body, $header) = @_;
    die "CustomerOriginAdd must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'CustomerOriginAdd',
        soap_action => 'EC:WebServices/CustomerOriginAdd',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::Administration::Element::CustomerOriginAdd )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub CustomerOriginDelete {
    my ($self, $body, $header) = @_;
    die "CustomerOriginDelete must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'CustomerOriginDelete',
        soap_action => 'EC:WebServices/CustomerOriginDelete',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::Administration::Element::CustomerOriginDelete )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub OriginShieldPOPsGet {
    my ($self, $body, $header) = @_;
    die "OriginShieldPOPsGet must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'OriginShieldPOPsGet',
        soap_action => 'EC:WebServices/OriginShieldPOPsGet',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::Administration::Element::OriginShieldPOPsGet )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub CustomerOriginAdvancedGet {
    my ($self, $body, $header) = @_;
    die "CustomerOriginAdvancedGet must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'CustomerOriginAdvancedGet',
        soap_action => 'EC:WebServices/CustomerOriginAdvancedGet',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::Administration::Element::CustomerOriginAdvancedGet )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub CustomerOriginGet {
    my ($self, $body, $header) = @_;
    die "CustomerOriginGet must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'CustomerOriginGet',
        soap_action => 'EC:WebServices/CustomerOriginGet',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::Administration::Element::CustomerOriginGet )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub CustomerOriginsAdvancedGet {
    my ($self, $body, $header) = @_;
    die "CustomerOriginsAdvancedGet must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'CustomerOriginsAdvancedGet',
        soap_action => 'EC:WebServices/CustomerOriginsAdvancedGet',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::Administration::Element::CustomerOriginsAdvancedGet )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub CustomerOriginsGet {
    my ($self, $body, $header) = @_;
    die "CustomerOriginsGet must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'CustomerOriginsGet',
        soap_action => 'EC:WebServices/CustomerOriginsGet',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::Administration::Element::CustomerOriginsGet )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub CustomerCnameAdd {
    my ($self, $body, $header) = @_;
    die "CustomerCnameAdd must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'CustomerCnameAdd',
        soap_action => 'EC:WebServices/CustomerCnameAdd',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::Administration::Element::CustomerCnameAdd )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub CustomerCnameDelete {
    my ($self, $body, $header) = @_;
    die "CustomerCnameDelete must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'CustomerCnameDelete',
        soap_action => 'EC:WebServices/CustomerCnameDelete',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::Administration::Element::CustomerCnameDelete )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub CustomerCnameGet {
    my ($self, $body, $header) = @_;
    die "CustomerCnameGet must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'CustomerCnameGet',
        soap_action => 'EC:WebServices/CustomerCnameGet',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::Administration::Element::CustomerCnameGet )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub CustomerCnamesGet {
    my ($self, $body, $header) = @_;
    die "CustomerCnamesGet must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'CustomerCnamesGet',
        soap_action => 'EC:WebServices/CustomerCnamesGet',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::Administration::Element::CustomerCnamesGet )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub CustomerUrlUpdate {
    my ($self, $body, $header) = @_;
    die "CustomerUrlUpdate must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'CustomerUrlUpdate',
        soap_action => 'EC:WebServices/CustomerUrlUpdate',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::Administration::Element::CustomerUrlUpdate )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub CustomerServiceUpdate {
    my ($self, $body, $header) = @_;
    die "CustomerServiceUpdate must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'CustomerServiceUpdate',
        soap_action => 'EC:WebServices/CustomerServiceUpdate',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( WebService::Edgecast::auto::Administration::Element::CustomerServiceUpdate )],
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

WebService::Edgecast::auto::Administration::Interface::EdgeCastWebServices::EdgeCastWebServicesSoap - SOAP Interface for the EdgeCastWebServices Web Service

=head1 VERSION

version 0.01.00

=head1 SYNOPSIS

 use WebService::Edgecast::auto::Administration::Interface::EdgeCastWebServices::EdgeCastWebServicesSoap;
 my $interface = WebService::Edgecast::auto::Administration::Interface::EdgeCastWebServices::EdgeCastWebServicesSoap->new();

 my $response;
 $response = $interface->CustomersGet();
 $response = $interface->CustomerGet();
 $response = $interface->CustomerAdd();
 $response = $interface->CustomerUpdate();
 $response = $interface->CustomerDelete();
 $response = $interface->CustomerUserAdd();
 $response = $interface->CustomerUserDelete();
 $response = $interface->CustomerUserUpdate();
 $response = $interface->CustomerUsersGet();
 $response = $interface->CustomerUserGet();
 $response = $interface->CustomerCustomIdUpdate();
 $response = $interface->CustomerAccountMeasuredByUpdate();
 $response = $interface->CustomerAccountMeasuredByGet();
 $response = $interface->CustomerStatusUpdate();
 $response = $interface->CustomerStatusGet();
 $response = $interface->CustomerHttpUpdate();
 $response = $interface->CustomerHttpGet();
 $response = $interface->CustomerHttpLargeGet();
 $response = $interface->CustomerHttpLargeUpdate();
 $response = $interface->CustomerHttpSmallUpdate();
 $response = $interface->CustomerHttpSmallGet();
 $response = $interface->CustomerFmsUpdate();
 $response = $interface->CustomerFmsGet();
 $response = $interface->CustomerWmsUpdate();
 $response = $interface->CustomerWmsGet();
 $response = $interface->CustomerAccessModuleUpdate();
 $response = $interface->CustomerAccessModuleGet();
 $response = $interface->CustomerUserAccessModuleUpdate();
 $response = $interface->CustomerUserAccessModuleGet();
 $response = $interface->CustomerOriginAdvancedUpdate();
 $response = $interface->CustomerOriginUpdate();
 $response = $interface->DeliveryRegionsGet();
 $response = $interface->CustomerDeliveryRegionUpdate();
 $response = $interface->CustomerOriginAdvancedAdd();
 $response = $interface->CustomerOriginAdd();
 $response = $interface->CustomerOriginDelete();
 $response = $interface->OriginShieldPOPsGet();
 $response = $interface->CustomerOriginAdvancedGet();
 $response = $interface->CustomerOriginGet();
 $response = $interface->CustomerOriginsAdvancedGet();
 $response = $interface->CustomerOriginsGet();
 $response = $interface->CustomerCnameAdd();
 $response = $interface->CustomerCnameDelete();
 $response = $interface->CustomerCnameGet();
 $response = $interface->CustomerCnamesGet();
 $response = $interface->CustomerUrlUpdate();
 $response = $interface->CustomerServiceUpdate();



=head1 DESCRIPTION

SOAP Interface for the EdgeCastWebServices web service
located at https://api.edgecast.com/v1/Administration.asmx.

=head1 SERVICE EdgeCastWebServices

Administration API

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



=head3 CustomersGet

Gets list of customers for partners.<br>Required fields: strCredential

Returns a L<WebService::Edgecast::auto::Administration::Element::CustomersGetResponse|WebService::Edgecast::auto::Administration::Element::CustomersGetResponse> object.

 $response = $interface->CustomersGet( {
    strCredential =>  $some_value, # string
  },,
 );

=head3 CustomerGet

Gets customer information.<br>Required fields: strCredential, strCustomerId OR strCustomId

Returns a L<WebService::Edgecast::auto::Administration::Element::CustomerGetResponse|WebService::Edgecast::auto::Administration::Element::CustomerGetResponse> object.

 $response = $interface->CustomerGet( {
    strCredential =>  $some_value, # string
    strCustomerId =>  $some_value, # string
    strCustomId =>  $some_value, # string
  },,
 );

=head3 CustomerAdd

Add customer. <br>**Use methods CustomerHttpUpdate, CustomerFmsUpdate, and/or CustomerWmsUpdate to enable customer media types. Media types are disabled until you call these methods.<br>**Use method CustomerUserAdd to create a user for the Media Control Center. No logins exist for the Media Control Center until this method is called.<br>Required fields: strCredential, strCompanyName, intStatus <br>Status: 1=Active, 3=Trial (deleted after 14 days)

Returns a L<WebService::Edgecast::auto::Administration::Element::CustomerAddResponse|WebService::Edgecast::auto::Administration::Element::CustomerAddResponse> object.

 $response = $interface->CustomerAdd( {
    strCredential =>  $some_value, # string
    strCompanyName =>  $some_value, # string
    intStatus =>  $some_value, # unsignedInt
    strWebsite =>  $some_value, # string
    strAddress1 =>  $some_value, # string
    strAddress2 =>  $some_value, # string
    strCity =>  $some_value, # string
    strState =>  $some_value, # string
    strZip =>  $some_value, # string
    strCountry =>  $some_value, # string
    strBillingAddress1 =>  $some_value, # string
    strBillingAddress2 =>  $some_value, # string
    strBillingCity =>  $some_value, # string
    strBillingState =>  $some_value, # string
    strBillingZip =>  $some_value, # string
    strBillingCountry =>  $some_value, # string
    strNotes =>  $some_value, # string
    strContactFirstName =>  $some_value, # string
    strContactLastName =>  $some_value, # string
    strContactTitle =>  $some_value, # string
    strContactEmail =>  $some_value, # string
    strContactPhone =>  $some_value, # string
    strContactFax =>  $some_value, # string
    strContactMobile =>  $some_value, # string
    strBillingContactFirstName =>  $some_value, # string
    strBillingContactLastName =>  $some_value, # string
    strBillingContactTitle =>  $some_value, # string
    strBillingContactEmail =>  $some_value, # string
    strBillingContactPhone =>  $some_value, # string
    strBillingContactFax =>  $some_value, # string
    strBillingContactMobile =>  $some_value, # string
  },,
 );

=head3 CustomerUpdate

Update a customer's basic information. <br>Required fields: strCredential, strCustomerId OR strCustomId <br>

Returns a L<WebService::Edgecast::auto::Administration::Element::CustomerUpdateResponse|WebService::Edgecast::auto::Administration::Element::CustomerUpdateResponse> object.

 $response = $interface->CustomerUpdate( {
    strCredential =>  $some_value, # string
    strCustomerId =>  $some_value, # string
    strCustomId =>  $some_value, # string
    strCompanyName =>  $some_value, # string
    strWebsite =>  $some_value, # string
    strAddress1 =>  $some_value, # string
    strAddress2 =>  $some_value, # string
    strCity =>  $some_value, # string
    strState =>  $some_value, # string
    strZip =>  $some_value, # string
    strCountry =>  $some_value, # string
    strBillingAddress1 =>  $some_value, # string
    strBillingAddress2 =>  $some_value, # string
    strBillingCity =>  $some_value, # string
    strBillingState =>  $some_value, # string
    strBillingZip =>  $some_value, # string
    strBillingCountry =>  $some_value, # string
    strNotes =>  $some_value, # string
    strContactFirstName =>  $some_value, # string
    strContactLastName =>  $some_value, # string
    strContactTitle =>  $some_value, # string
    strContactEmail =>  $some_value, # string
    strContactPhone =>  $some_value, # string
    strContactFax =>  $some_value, # string
    strContactMobile =>  $some_value, # string
    strBillingContactFirstName =>  $some_value, # string
    strBillingContactLastName =>  $some_value, # string
    strBillingContactTitle =>  $some_value, # string
    strBillingContactEmail =>  $some_value, # string
    strBillingContactPhone =>  $some_value, # string
    strBillingContactFax =>  $some_value, # string
    strBillingContactMobile =>  $some_value, # string
  },,
 );

=head3 CustomerDelete

Delete a customer. Once a customer is deleted, it cannot be reactivated. To suspend service, use CustomerStatusUpdate instead.<br>Required fields: strCredential, strCustomerId OR strCustomId <br>

Returns a L<WebService::Edgecast::auto::Administration::Element::CustomerDeleteResponse|WebService::Edgecast::auto::Administration::Element::CustomerDeleteResponse> object.

 $response = $interface->CustomerDelete( {
    strCredential =>  $some_value, # string
    strCustomerId =>  $some_value, # string
    strCustomId =>  $some_value, # string
  },,
 );

=head3 CustomerUserAdd

Create a user for the Media Control Center. User access will default to the customer's access modules. Use method CustomerAccessModuleUpdate to modify access at the customer level.<br>Use method CustomerUserAccessModuleUpdate to modify access at the user level.<br>Required fields: strCredential, strCustomerId OR strCustomId, strEmail, strPassword <br>IsAdmin: For no, enter "0" or "false". For yes, enter "1" or "true". Admin users have all access rights to the MCC, and they can not be deleted. There can only be one admin user per customer. <br>Please consult the API documentation for the time zone ID mapping. <br>

Returns a L<WebService::Edgecast::auto::Administration::Element::CustomerUserAddResponse|WebService::Edgecast::auto::Administration::Element::CustomerUserAddResponse> object.

 $response = $interface->CustomerUserAdd( {
    strCredential =>  $some_value, # string
    strCustomerId =>  $some_value, # string
    strCustomId =>  $some_value, # string
    strFirstName =>  $some_value, # string
    strLastName =>  $some_value, # string
    strEmail =>  $some_value, # string
    strPassword =>  $some_value, # string
    strIsAdmin =>  $some_value, # string
    strTitle =>  $some_value, # string
    strAddress1 =>  $some_value, # string
    strAddress2 =>  $some_value, # string
    strCity =>  $some_value, # string
    strState =>  $some_value, # string
    strZip =>  $some_value, # string
    strCountry =>  $some_value, # string
    strPhone =>  $some_value, # string
    strFax =>  $some_value, # string
    strMobile =>  $some_value, # string
    strTimeZoneId =>  $some_value, # string
  },,
 );

=head3 CustomerUserDelete

Delete a customer user. <br>Required fields: strCredential, strCustomerId OR strCustomId, intCustomerUserId <br>

Returns a L<WebService::Edgecast::auto::Administration::Element::CustomerUserDeleteResponse|WebService::Edgecast::auto::Administration::Element::CustomerUserDeleteResponse> object.

 $response = $interface->CustomerUserDelete( {
    strCredential =>  $some_value, # string
    strCustomerId =>  $some_value, # string
    strCustomId =>  $some_value, # string
    intCustomerUserId =>  $some_value, # unsignedInt
  },,
 );

=head3 CustomerUserUpdate

Update a customer user's basic information. If Email, Password, or TimeZoneId is empty, it will not be updated. All other values will be updated if empty.<br>Required fields: strCredential, intCustomerUserId <br>Status: 0 for disable, 1 for enable

Returns a L<WebService::Edgecast::auto::Administration::Element::CustomerUserUpdateResponse|WebService::Edgecast::auto::Administration::Element::CustomerUserUpdateResponse> object.

 $response = $interface->CustomerUserUpdate( {
    strCredential =>  $some_value, # string
    strCustomerId =>  $some_value, # string
    strCustomId =>  $some_value, # string
    intCustomerUserId =>  $some_value, # unsignedInt
    strFirstName =>  $some_value, # string
    strLastName =>  $some_value, # string
    strEmail =>  $some_value, # string
    strPassword =>  $some_value, # string
    strTitle =>  $some_value, # string
    strAddress1 =>  $some_value, # string
    strAddress2 =>  $some_value, # string
    strCity =>  $some_value, # string
    strState =>  $some_value, # string
    strZip =>  $some_value, # string
    strCountry =>  $some_value, # string
    strPhone =>  $some_value, # string
    strFax =>  $some_value, # string
    strMobile =>  $some_value, # string
    strTimeZoneId =>  $some_value, # string
  },,
 );

=head3 CustomerUsersGet

Gets list of customer users for a customer.<br>Required fields: strCredential, strCustomerId OR strCustomId

Returns a L<WebService::Edgecast::auto::Administration::Element::CustomerUsersGetResponse|WebService::Edgecast::auto::Administration::Element::CustomerUsersGetResponse> object.

 $response = $interface->CustomerUsersGet( {
    strCredential =>  $some_value, # string
    strCustomerId =>  $some_value, # string
    strCustomId =>  $some_value, # string
  },,
 );

=head3 CustomerUserGet

Get a customer user's basic information<br>Required fields: strCredential, strCustomerId OR strCustomId, intCustomerUserId <br>Status: 0 for disable, 1 for enable

Returns a L<WebService::Edgecast::auto::Administration::Element::CustomerUserGetResponse|WebService::Edgecast::auto::Administration::Element::CustomerUserGetResponse> object.

 $response = $interface->CustomerUserGet( {
    strCredential =>  $some_value, # string
    strCustomerId =>  $some_value, # string
    strCustomId =>  $some_value, # string
    intCustomerUserId =>  $some_value, # unsignedInt
  },,
 );

=head3 CustomerCustomIdUpdate

Update Custom Id. The Custom Id field may be used if partners have their own Ids associated with customers.<br>This value must be unique across all of the partner's customers.<br>Required fields: strCredential, strCustomerId, strCustomId <br>

Returns a L<WebService::Edgecast::auto::Administration::Element::CustomerCustomIdUpdateResponse|WebService::Edgecast::auto::Administration::Element::CustomerCustomIdUpdateResponse> object.

 $response = $interface->CustomerCustomIdUpdate( {
    strCredential =>  $some_value, # string
    strCustomerId =>  $some_value, # string
    strCustomId =>  $some_value, # string
  },,
 );

=head3 CustomerAccountMeasuredByUpdate

Update Account Measured By. This describes how a customer account is measured by, and usually reflects customer's payment method.<br>The default is bandwidth, set upon CustomerAdd.<br>Required fields: strCredential, strCustomerId OR strCustomId, intAccountMeasuredBy <br>Account Measured By: 0=Bandwidth (Mbps) (default), 1=Data Transferred (GB)

Returns a L<WebService::Edgecast::auto::Administration::Element::CustomerAccountMeasuredByUpdateResponse|WebService::Edgecast::auto::Administration::Element::CustomerAccountMeasuredByUpdateResponse> object.

 $response = $interface->CustomerAccountMeasuredByUpdate( {
    strCredential =>  $some_value, # string
    strCustomerId =>  $some_value, # string
    strCustomId =>  $some_value, # string
    intAccountMeasuredBy =>  $some_value, # short
  },,
 );

=head3 CustomerAccountMeasuredByGet

Gets whether a customer account is measured by bandwidth or data transferred. This usually reflects customer's payment method.<br>The default is bandwidth, set upon CustomerAdd.<br> Required fields: strCredential, strCustomerId OR strCustomId <br>Returns Account Measured By: 0=Bandwidth (Mbps) (default), 1=Data Transferred (GB)

Returns a L<WebService::Edgecast::auto::Administration::Element::CustomerAccountMeasuredByGetResponse|WebService::Edgecast::auto::Administration::Element::CustomerAccountMeasuredByGetResponse> object.

 $response = $interface->CustomerAccountMeasuredByGet( {
    strCredential =>  $some_value, # string
    strCustomerId =>  $some_value, # string
    strCustomId =>  $some_value, # string
  },,
 );

=head3 CustomerStatusUpdate

Update Customer Status. Only valid paths are Active -> Suspended, Suspended -> Active, and Trial -> Active.<br>Required fields: strCredential, strCustomerId OR strCustomId, intStatus <br>Status: 1=Active, 2=Suspended, 3=Trial <br>

Returns a L<WebService::Edgecast::auto::Administration::Element::CustomerStatusUpdateResponse|WebService::Edgecast::auto::Administration::Element::CustomerStatusUpdateResponse> object.

 $response = $interface->CustomerStatusUpdate( {
    strCredential =>  $some_value, # string
    strCustomerId =>  $some_value, # string
    strCustomId =>  $some_value, # string
    intStatus =>  $some_value, # short
  },,
 );

=head3 CustomerStatusGet

Get Customer Status. <br>Required fields: strCredential, strCustomerId OR strCustomId <br>Status: 0=Inactive, 1=Active, 2=Suspended, 3=Trial <br>

Returns a L<WebService::Edgecast::auto::Administration::Element::CustomerStatusGetResponse|WebService::Edgecast::auto::Administration::Element::CustomerStatusGetResponse> object.

 $response = $interface->CustomerStatusGet( {
    strCredential =>  $some_value, # string
    strCustomerId =>  $some_value, # string
    strCustomId =>  $some_value, # string
  },,
 );

=head3 CustomerHttpUpdate

Deprecated. Use CustomerHttpLargeUpdate.

Returns a L<WebService::Edgecast::auto::Administration::Element::CustomerHttpUpdateResponse|WebService::Edgecast::auto::Administration::Element::CustomerHttpUpdateResponse> object.

 $response = $interface->CustomerHttpUpdate( {
    strCredential =>  $some_value, # string
    strCustomerId =>  $some_value, # string
    strCustomId =>  $some_value, # string
    strStatus =>  $some_value, # string
    strContentURL =>  $some_value, # string
  },,
 );

=head3 CustomerHttpGet

Deprecated. Use CustomerHttpLargeGet.

Returns a L<WebService::Edgecast::auto::Administration::Element::CustomerHttpGetResponse|WebService::Edgecast::auto::Administration::Element::CustomerHttpGetResponse> object.

 $response = $interface->CustomerHttpGet( {
    strCredential =>  $some_value, # string
    strCustomerId =>  $some_value, # string
    strCustomId =>  $some_value, # string
  },,
 );

=head3 CustomerHttpLargeGet

Get customer information for HTTP Large Object.<br>Required fields: strCredential, strCustomerId OR strCustomId <br>Returns Status: 0 for disable, 1 for enable <br>Returns Content URL

Returns a L<WebService::Edgecast::auto::Administration::Element::CustomerHttpLargeGetResponse|WebService::Edgecast::auto::Administration::Element::CustomerHttpLargeGetResponse> object.

 $response = $interface->CustomerHttpLargeGet( {
    strCredential =>  $some_value, # string
    strCustomerId =>  $some_value, # string
    strCustomId =>  $some_value, # string
  },,
 );

=head3 CustomerHttpLargeUpdate

Update HTTP Large Object. Enable or disable a customer for HTTP Large Object, and set content URL string. Only non-empty values will be updated.<br>Default value for Content URL is http://ne.edgecastcdn.net .<br>Required fields: strCredential, strCustomerId OR strCustomId, <br>Status: 0 for disable, 1 for enable

Returns a L<WebService::Edgecast::auto::Administration::Element::CustomerHttpLargeUpdateResponse|WebService::Edgecast::auto::Administration::Element::CustomerHttpLargeUpdateResponse> object.

 $response = $interface->CustomerHttpLargeUpdate( {
    strCredential =>  $some_value, # string
    strCustomerId =>  $some_value, # string
    strCustomId =>  $some_value, # string
    strStatus =>  $some_value, # string
    strContentURL =>  $some_value, # string
  },,
 );

=head3 CustomerHttpSmallUpdate

Update HTTP Small Object. Enable or disable a customer for HTTP Small Object, and set content URL string. Only non-empty values will be updated.<br>Default value for Content URL is http://wac.xxxx.edgecastcdn.net, where 'xxxx' is the customer id.<br>Required fields: strCredential, strCustomerId OR strCustomId, <br>Status: 0 for disable, 1 for enable

Returns a L<WebService::Edgecast::auto::Administration::Element::CustomerHttpSmallUpdateResponse|WebService::Edgecast::auto::Administration::Element::CustomerHttpSmallUpdateResponse> object.

 $response = $interface->CustomerHttpSmallUpdate( {
    strCredential =>  $some_value, # string
    strCustomerId =>  $some_value, # string
    strCustomId =>  $some_value, # string
    strStatus =>  $some_value, # string
    strContentURL =>  $some_value, # string
  },,
 );

=head3 CustomerHttpSmallGet

Get customer information for HTTP Small Object.<br>Required fields: strCredential, strCustomerId OR strCustomId <br>Returns Status: 0 for disable, 1 for enable <br>Returns Content URL

Returns a L<WebService::Edgecast::auto::Administration::Element::CustomerHttpSmallGetResponse|WebService::Edgecast::auto::Administration::Element::CustomerHttpSmallGetResponse> object.

 $response = $interface->CustomerHttpSmallGet( {
    strCredential =>  $some_value, # string
    strCustomerId =>  $some_value, # string
    strCustomId =>  $some_value, # string
  },,
 );

=head3 CustomerFmsUpdate

Update FMS. Enable or disable a customer for FMS, and set content URL string. Only non-empty values will be updated.<br>Default value for Content URL is rtmp://ne.fms.edgecastcdn.net.<br>Required fields: strCredential, strCustomerId OR strCustomId <br>Status: 0 for disable, 1 for enable

Returns a L<WebService::Edgecast::auto::Administration::Element::CustomerFmsUpdateResponse|WebService::Edgecast::auto::Administration::Element::CustomerFmsUpdateResponse> object.

 $response = $interface->CustomerFmsUpdate( {
    strCredential =>  $some_value, # string
    strCustomerId =>  $some_value, # string
    strCustomId =>  $some_value, # string
    strStatus =>  $some_value, # string
    strContentURL =>  $some_value, # string
  },,
 );

=head3 CustomerFmsGet

Get customer information for FMS.<br>Required fields: strCredential, strCustomerId OR strCustomId <br>Returns Status: 0 for disable, 1 for enable <br>Returns Content URL

Returns a L<WebService::Edgecast::auto::Administration::Element::CustomerFmsGetResponse|WebService::Edgecast::auto::Administration::Element::CustomerFmsGetResponse> object.

 $response = $interface->CustomerFmsGet( {
    strCredential =>  $some_value, # string
    strCustomerId =>  $some_value, # string
    strCustomId =>  $some_value, # string
  },,
 );

=head3 CustomerWmsUpdate

Update WMS. Enable or disable a customer for WMS, and set content URL string. Only non-empty values will be updated.<br>Default value for Content URL is mms://ne.wms.edgecastcdn.net.<br>Required fields: strCredential, strCustomerId OR strCustomId <br>Status: 0 for disable, 1 for enable 

Returns a L<WebService::Edgecast::auto::Administration::Element::CustomerWmsUpdateResponse|WebService::Edgecast::auto::Administration::Element::CustomerWmsUpdateResponse> object.

 $response = $interface->CustomerWmsUpdate( {
    strCredential =>  $some_value, # string
    strCustomerId =>  $some_value, # string
    strCustomId =>  $some_value, # string
    strStatus =>  $some_value, # string
    strContentURL =>  $some_value, # string
  },,
 );

=head3 CustomerWmsGet

Get customer information for WMS.<br>Required fields: strCredential, strCustomerId OR strCustomId <br>Returns Status: 0 for disable, 1 for enable <br>Returns Content URL

Returns a L<WebService::Edgecast::auto::Administration::Element::CustomerWmsGetResponse|WebService::Edgecast::auto::Administration::Element::CustomerWmsGetResponse> object.

 $response = $interface->CustomerWmsGet( {
    strCredential =>  $some_value, # string
    strCustomerId =>  $some_value, # string
    strCustomId =>  $some_value, # string
  },,
 );

=head3 CustomerAccessModuleUpdate

This method allows you to update access to the MCC on the customer level. The first two levels of access modules correspond to MCC navigation items.<br>The CustomerAdd method will by default allow the customer access to all modules EXCEPT Token Auth for all media types, and Advanced Reports & Analytics.<br>All users created for this customer will have access to what the customer has by default, but you may modify access at the user level by using CustomerUserAccessModuleUpdate.<br>Required fields: strCredential, strCustomerId OR strCustomId, intAccessModuleId, intStatus <br>Status: 0 for disable, 1 for enable <br>Please consult the API documentation for the access module ID mapping. <br>

Returns a L<WebService::Edgecast::auto::Administration::Element::CustomerAccessModuleUpdateResponse|WebService::Edgecast::auto::Administration::Element::CustomerAccessModuleUpdateResponse> object.

 $response = $interface->CustomerAccessModuleUpdate( {
    strCredential =>  $some_value, # string
    strCustomerId =>  $some_value, # string
    strCustomId =>  $some_value, # string
    intAccessModuleId =>  $some_value, # int
    intStatus =>  $some_value, # short
  },,
 );

=head3 CustomerAccessModuleGet

Gets whether a customer has access to a module in the MCC. The first two levels of access modules correspond to MCC navigation items.<br>The CustomerAdd method will by default allow the customer access to all modules EXCEPT Token Auth for all media types, and Advanced Reports & Analytics.<br>All users created for this customer will have access to what the customer has by default, but you may modify access at the user level by using CustomerUserAccessModuleUpdate.<br>Required fields: strCredential, strCustomerId OR strCustomId, intAccessModuleId <br>Returns Status: 0 for disabled, 1 for enabled <br>Please consult the API documentation for the access module ID mapping. <br>

Returns a L<WebService::Edgecast::auto::Administration::Element::CustomerAccessModuleGetResponse|WebService::Edgecast::auto::Administration::Element::CustomerAccessModuleGetResponse> object.

 $response = $interface->CustomerAccessModuleGet( {
    strCredential =>  $some_value, # string
    strCustomerId =>  $some_value, # string
    strCustomId =>  $some_value, # string
    intAccessModuleId =>  $some_value, # int
  },,
 );

=head3 CustomerUserAccessModuleUpdate

This method is used to update access to the Media Control Center at the user level. The first two levels of access modules correspond to MCC navigation items.<br>Even though user access may be enabled, the customer must also have access to a module in order for the user to. To modify customer access, use CustomerAccessModuleUpdate.<br>Required fields: strCredential, strCustomerId OR strCustomId, intCustomerUserId, intAccessModuleId, intStatus <br>Status: 0 for disable, 1 for enable <br>Please consult the API documentation for the access module ID mapping. <br>

Returns a L<WebService::Edgecast::auto::Administration::Element::CustomerUserAccessModuleUpdateResponse|WebService::Edgecast::auto::Administration::Element::CustomerUserAccessModuleUpdateResponse> object.

 $response = $interface->CustomerUserAccessModuleUpdate( {
    strCredential =>  $some_value, # string
    strCustomerId =>  $some_value, # string
    strCustomId =>  $some_value, # string
    intCustomerUserId =>  $some_value, # unsignedInt
    intAccessModuleId =>  $some_value, # int
    intStatus =>  $some_value, # short
  },,
 );

=head3 CustomerUserAccessModuleGet

Gets whether a user has access to a module in the MCC. The first two levels of access modules correspond to MCC navigation items.<br>Even though user access may be enabled, the customer must also have access to a module in order for the user to. To modify customer access, use CustomerAccessModuleUpdate.<br>Required fields: strCredential, intCustomerUserId, intAccessModuleId <br>Returns Status: 0 for disabled, 1 for enabled <br>Please consult the API documentation for the access module ID mapping. <br>

Returns a L<WebService::Edgecast::auto::Administration::Element::CustomerUserAccessModuleGetResponse|WebService::Edgecast::auto::Administration::Element::CustomerUserAccessModuleGetResponse> object.

 $response = $interface->CustomerUserAccessModuleGet( {
    strCredential =>  $some_value, # string
    intCustomerUserId =>  $some_value, # unsignedInt
    intAccessModuleId =>  $some_value, # int
  },,
 );

=head3 CustomerOriginAdvancedUpdate

Updates an existing customer origin entry of media type id 3 or 8 (Http large and Http small).<br>To update customer origins of media type id 2 - Flash, please use CustomerOriginUpdate API instead.<br>Required fields: strCredential, strCustomerId OR strCustomId, intCustomerOriginId, strDirName,<br>strHttpLoadBalMode and strHttpHostnames OR strHttpsLoadBalMode and strHttpsHostnames.<br> Load balance options are: "PF" (for Primary and Failover), and "RR" (for Round Robin).<br>Hostnames should be complete with a valid protocol and optionally a port number.<br>List of hostnames used in strHttpHostnames or strHttpsHostnames should be separated by commas ",".<br>HTTP host header value should not include the protocol part.<br>List of Shield POP Codes should be separated by commas ",".<br>Origin Shield information is for customers who have Origin Shield enabled. Origin Shield only applies to Large Object (Media Type 3) and Small Object (Media Type 8).<br>

Returns a L<WebService::Edgecast::auto::Administration::Element::CustomerOriginAdvancedUpdateResponse|WebService::Edgecast::auto::Administration::Element::CustomerOriginAdvancedUpdateResponse> object.

 $response = $interface->CustomerOriginAdvancedUpdate( {
    strCredential =>  $some_value, # string
    strCustomerId =>  $some_value, # string
    strCustomId =>  $some_value, # string
    intCustomerOriginId =>  $some_value, # int
    strDirName =>  $some_value, # string
    strHttpLoadBalMode =>  $some_value, # string
    strHttpHostnames =>  $some_value, # string
    strHttpsLoadBalMode =>  $some_value, # string
    strHttpsHostnames =>  $some_value, # string
    strHostHeaderValue =>  $some_value, # string
    strShieldPopCodes =>  $some_value, # string
  },,
 );

=head3 CustomerOriginUpdate

You may also use CustomerOriginAdvancedUpdate API, for media types Http Large and Http Small, to control more advanced settings.<br>Updates an existing customer origin entry.<br>Required fields: strCredential, strCustomerId OR strCustomId, strCustomerOriginId, strOriginString,<br>Origin Shield: For No, enter "0". For Yes, enter "1". This is for customers who have Origin Shield enabled. Origin Shield only applies to Large Object (Media Type 3) and Small Object (Media Type 8).<br>

Returns a L<WebService::Edgecast::auto::Administration::Element::CustomerOriginUpdateResponse|WebService::Edgecast::auto::Administration::Element::CustomerOriginUpdateResponse> object.

 $response = $interface->CustomerOriginUpdate( {
    strCredential =>  $some_value, # string
    strCustomerId =>  $some_value, # string
    strCustomId =>  $some_value, # string
    intCustomerOriginId =>  $some_value, # int
    strOriginString =>  $some_value, # string
    strOriginShield =>  $some_value, # string
  },,
 );

=head3 DeliveryRegionsGet

Returns a list of available Delivery Regions and their ids.<br>Required field: strCredential.<br/><b>North America /Europe</b> – utilizing this regional delivery selection will deliver content to users all over the world, but do so only from the POPs located in North America and Europe (therefore this excludes the 3 POPs in APAC).<br/><b>Global Standard</b> - utilizing the Global CDN platform leverages all 16 POP's globally, all North American and European transit routes, and global peering routes (excludes select premium APAC routes in Hong Kong, Japan, and Australia POPs).<br/><b>Global + Premium Asia</b> – utilizes the Global Standard network as well as Premium APAC Routes. The Premium APAC Routes will leverage the 3 POP's in APAC(Hong Kong, Tokyo, and Australia), distributing traffic across both the transit providers in region and peering routes established in each market/exchange. When this is selected for a particular customer, the usage will be metered separately for all APAC POPs; Pricing in the North America and Europe POPs will be at the Global Standard pricing and Pricing for APAC will be at the Premium APAC Route pricing.<br/>

Returns a L<WebService::Edgecast::auto::Administration::Element::DeliveryRegionsGetResponse|WebService::Edgecast::auto::Administration::Element::DeliveryRegionsGetResponse> object.

 $response = $interface->DeliveryRegionsGet( {
    strCredential =>  $some_value, # string
  },,
 );

=head3 CustomerDeliveryRegionUpdate

Updates the delivery region setting for an existing customer.<br>Use this API to modify the delivery region for an exisitng customer.<br>Required fields: strCredential, strCustomerId OR strCustomId, and intDeliveryRegionId.<br>You may use DeliveryRegionsGet API for a listing of available regions and their Ids.<br><b>North America /Europe</b> – utilizing this regional delivery selection will deliver content to users all over the world, but do so only from the POPs located in North America and Europe (therefore this excludes the 3 POPs in APAC).<br/><b>Global Standard</b> - utilizing the Global CDN platform leverages all 16 POP's globally, all North American and European transit routes, and global peering routes (excludes select premium APAC routes in Hong Kong, Japan, and Australia POPs).<br/><b>Global + Premium Asia</b> – utilizes the Global Standard network as well as Premium APAC Routes. The Premium APAC Routes will leverage the 3 POP's in APAC(Hong Kong, Tokyo, and Australia), distributing traffic across both the transit providers in region and peering routes established in each market/exchange. When this is selected for a particular customer, the usage will be metered separately for all APAC POPs; Pricing in the North America and Europe POPs will be at the Global Standard pricing and Pricing for APAC will be at the Premium APAC Route pricing.<br/>

Returns a L<WebService::Edgecast::auto::Administration::Element::CustomerDeliveryRegionUpdateResponse|WebService::Edgecast::auto::Administration::Element::CustomerDeliveryRegionUpdateResponse> object.

 $response = $interface->CustomerDeliveryRegionUpdate( {
    strCredential =>  $some_value, # string
    strCustomerId =>  $some_value, # string
    strCustomId =>  $some_value, # string
    intDeliveryRegionId =>  $some_value, # int
  },,
 );

=head3 CustomerOriginAdvancedAdd

Creates a new customer origin.<br>Use this API to create new customer origins of type Http Large (Media Type 3), and Http Small (Media Type 8).<br>You may use CustomerOriginAdd API for Flash (Media Type 2) customer origins.<br>Required fields: strCredential, strCustomerId OR strCustomId, intMediaType, strDirName,<br>strHttpLoadBalMode and strHttpHostnames OR strHttpsLoadBalMode and strHttpsHostnames.<br> Load balance options are: "PF" (for Primary and Failover), and "RR" (for Round Robin).<br>Hostnames should be complete with a valid protocol and optionally a port number.<br>List of hostnames used in strHttpHostnames or strHttpsHostnames should be separated by commas ",".<br>HTTP host header value should not include the protocol part.<br>List of Shield POP Codes should be separated by commas ",".<br>Origin Shield information is for customers who have Origin Shield enabled. Origin Shield only applies to Large Object (Media Type 3) and Small Object (Media Type 8).<br>

Returns a L<WebService::Edgecast::auto::Administration::Element::CustomerOriginAdvancedAddResponse|WebService::Edgecast::auto::Administration::Element::CustomerOriginAdvancedAddResponse> object.

 $response = $interface->CustomerOriginAdvancedAdd( {
    strCredential =>  $some_value, # string
    strCustomerId =>  $some_value, # string
    strCustomId =>  $some_value, # string
    intMediaType =>  $some_value, # int
    strDirName =>  $some_value, # string
    strHttpLoadBalMode =>  $some_value, # string
    strHttpHostnames =>  $some_value, # string
    strHttpsLoadBalMode =>  $some_value, # string
    strHttpsHostnames =>  $some_value, # string
    strHostHeaderValue =>  $some_value, # string
    strShieldPopCodes =>  $some_value, # string
  },,
 );

=head3 CustomerOriginAdd

You may also use CustomerOriginAdvancedAdd API, for HTTP Large and Small media types, to control more advanced settings.<br>Create customer origin.<br>Required fields: strCredential, strCustomerId OR strCustomId, intMediaType, strOriginString <br>Origin Shield: For no, enter "0". For yes, enter "1". This is for customers who have Origin Shield enabled. Origin Shield only applies to Large Object (Media Type 3) and Small Object (Media Type 8).<br>

Returns a L<WebService::Edgecast::auto::Administration::Element::CustomerOriginAddResponse|WebService::Edgecast::auto::Administration::Element::CustomerOriginAddResponse> object.

 $response = $interface->CustomerOriginAdd( {
    strCredential =>  $some_value, # string
    strCustomerId =>  $some_value, # string
    strCustomId =>  $some_value, # string
    intMediaType =>  $some_value, # int
    strOriginString =>  $some_value, # string
    strOriginShield =>  $some_value, # string
  },,
 );

=head3 CustomerOriginDelete

Delete a customer origin. <br>Required fields: strCredential, strCustomerId OR strCustomId, intCustomerOriginId <br>

Returns a L<WebService::Edgecast::auto::Administration::Element::CustomerOriginDeleteResponse|WebService::Edgecast::auto::Administration::Element::CustomerOriginDeleteResponse> object.

 $response = $interface->CustomerOriginDelete( {
    strCredential =>  $some_value, # string
    strCustomerId =>  $some_value, # string
    strCustomId =>  $some_value, # string
    intCustomerOriginId =>  $some_value, # int
  },,
 );

=head3 OriginShieldPOPsGet

Returns a list of available Origin Shield POPs for the specified customer.<br>Required fields: strCredential, and either a strCustomerId or a strCustomId.

Returns a L<WebService::Edgecast::auto::Administration::Element::OriginShieldPOPsGetResponse|WebService::Edgecast::auto::Administration::Element::OriginShieldPOPsGetResponse> object.

 $response = $interface->OriginShieldPOPsGet( {
    strCredential =>  $some_value, # string
    strCustomerId =>  $some_value, # string
    strCustomId =>  $some_value, # string
  },,
 );

=head3 CustomerOriginAdvancedGet

Get a customer origin information<br>Required fields: strCredential, strCustomerId OR strCustomId, intCustomerOriginId

Returns a L<WebService::Edgecast::auto::Administration::Element::CustomerOriginAdvancedGetResponse|WebService::Edgecast::auto::Administration::Element::CustomerOriginAdvancedGetResponse> object.

 $response = $interface->CustomerOriginAdvancedGet( {
    strCredential =>  $some_value, # string
    strCustomerId =>  $some_value, # string
    strCustomId =>  $some_value, # string
    intCustomerOriginId =>  $some_value, # int
  },,
 );

=head3 CustomerOriginGet

You may also use CustomerOriginAdvancedGet API which provides complete details for each origin.<br>Get a customer origin information<br>Required fields: strCredential, strCustomerId OR strCustomId, intCustomerOriginId <br>Status: 0 for disable, 1 for enable

Returns a L<WebService::Edgecast::auto::Administration::Element::CustomerOriginGetResponse|WebService::Edgecast::auto::Administration::Element::CustomerOriginGetResponse> object.

 $response = $interface->CustomerOriginGet( {
    strCredential =>  $some_value, # string
    strCustomerId =>  $some_value, # string
    strCustomId =>  $some_value, # string
    intCustomerOriginId =>  $some_value, # int
  },,
 );

=head3 CustomerOriginsAdvancedGet

Gets all customer origins of a given media type for a specific customer.<br>Required fields: strCredential, strCustomerId OR strCustomId, and intMediaType

Returns a L<WebService::Edgecast::auto::Administration::Element::CustomerOriginsAdvancedGetResponse|WebService::Edgecast::auto::Administration::Element::CustomerOriginsAdvancedGetResponse> object.

 $response = $interface->CustomerOriginsAdvancedGet( {
    strCredential =>  $some_value, # string
    strCustomerId =>  $some_value, # string
    strCustomId =>  $some_value, # string
    intMediaType =>  $some_value, # int
  },,
 );

=head3 CustomerOriginsGet

You may also use CustomerOriginsAdvancedGet API for complete details of each origin.<br>Gets list of customer origins for a customer.<br>Required fields: strCredential, strCustomerId OR strCustomId, intMediaType

Returns a L<WebService::Edgecast::auto::Administration::Element::CustomerOriginsGetResponse|WebService::Edgecast::auto::Administration::Element::CustomerOriginsGetResponse> object.

 $response = $interface->CustomerOriginsGet( {
    strCredential =>  $some_value, # string
    strCustomerId =>  $some_value, # string
    strCustomId =>  $some_value, # string
    intMediaType =>  $some_value, # int
  },,
 );

=head3 CustomerCnameAdd

Create customer cname. Cname can be to the EdgeCast origin or to your customer origin. If EdgeCast origin, the cname will point to /00xxxx/, xxxx being your alphanumeric customer hex id. If customer origin, the cname will point to /80xxxx/yourorigin.com. You must create a customer origin first using CustomerOriginAdd.<br>Required fields: strCredential, strCustomerId OR strCustomId, intMediaType, strCname, intOriginId <br>Origin Id: Enter the customer origin id of the origin you would like to use, or enter -1 for EdgeCast origin.<br>MediaTypeId: 3 for Large Object, 2 for Flash, 8 for Small Object<br>

Returns a L<WebService::Edgecast::auto::Administration::Element::CustomerCnameAddResponse|WebService::Edgecast::auto::Administration::Element::CustomerCnameAddResponse> object.

 $response = $interface->CustomerCnameAdd( {
    strCredential =>  $some_value, # string
    strCustomerId =>  $some_value, # string
    strCustomId =>  $some_value, # string
    intMediaType =>  $some_value, # int
    strCname =>  $some_value, # string
    intOriginId =>  $some_value, # int
    strDirPath =>  $some_value, # string
  },,
 );

=head3 CustomerCnameDelete

Delete a customer cname. <br>Required fields: strCredential, strCustomerId OR strCustomId, intCustomerCnameId <br>

Returns a L<WebService::Edgecast::auto::Administration::Element::CustomerCnameDeleteResponse|WebService::Edgecast::auto::Administration::Element::CustomerCnameDeleteResponse> object.

 $response = $interface->CustomerCnameDelete( {
    strCredential =>  $some_value, # string
    strCustomerId =>  $some_value, # string
    strCustomId =>  $some_value, # string
    intCustomerCnameId =>  $some_value, # unsignedInt
  },,
 );

=head3 CustomerCnameGet

Get a customer cname information<br>Required fields: strCredential, strCustomerId OR strCustomId, intCustomerCnameId <br>Status: 0 for disable, 1 for enable

Returns a L<WebService::Edgecast::auto::Administration::Element::CustomerCnameGetResponse|WebService::Edgecast::auto::Administration::Element::CustomerCnameGetResponse> object.

 $response = $interface->CustomerCnameGet( {
    strCredential =>  $some_value, # string
    strCustomerId =>  $some_value, # string
    strCustomId =>  $some_value, # string
    intCustomerCnameId =>  $some_value, # unsignedInt
  },,
 );

=head3 CustomerCnamesGet

Gets list of customer cnames for a customer.<br>Required fields: strCredential, strCustomerId OR strCustomId, intMediaType<br>MediaTypeId: 3 for HTTP<br>

Returns a L<WebService::Edgecast::auto::Administration::Element::CustomerCnamesGetResponse|WebService::Edgecast::auto::Administration::Element::CustomerCnamesGetResponse> object.

 $response = $interface->CustomerCnamesGet( {
    strCredential =>  $some_value, # string
    strCustomerId =>  $some_value, # string
    strCustomId =>  $some_value, # string
    intMediaType =>  $some_value, # int
  },,
 );

=head3 CustomerUrlUpdate

Update CDN Domain URLs for customer. Only non-empty URLs will be updated.<br>Required fields: strCredential, strCustomerId OR strCustomId, strDomainTypeId, strUrl <br>Domain Types are as follows:<br>&nbsp;&nbsp;-HTTP Large Object URL = 1<br>&nbsp;&nbsp;-HTTPS Large Object URL= 2<br>&nbsp;&nbsp;-HTTP Small Object URL = 3<br>&nbsp;&nbsp;-HTTPS Small Object URL = 4<br>&nbsp;&nbsp;-Windows Live and On-Demand URL = 5<br>&nbsp;&nbsp;-Windows Live Origin DCA URL = 6<br>&nbsp;&nbsp;-Windows Live Origin SJO URL = 7<br>&nbsp;&nbsp;-Windows Live Origin AMS URL = 8<br>&nbsp;&nbsp;-Flash On-Demand URL = 9<br>&nbsp;&nbsp;-Flash Live Origin DCA URL = 10<br>&nbsp;&nbsp;-Flash Live Origin LAX URL = 11<br>&nbsp;&nbsp;-Flash Live Origin LHR URL = 12<br>&nbsp;&nbsp;-Flash Live Player DCA URL = 13<br>&nbsp;&nbsp;-Flash Live Player LAX URL = 14<br>&nbsp;&nbsp;-Flash Live Player LHR URL = 15<br>&nbsp;&nbsp;-Flash Live Streamcast Origin DCA URL = 16<br>&nbsp;&nbsp;-Flash Live Streamcast Origin LAX URL = 17<br>&nbsp;&nbsp;-Flash Live Streamcast Origin AMS URL = 18<br>&nbsp;&nbsp;-Flash Live Streamcast Origin SYD URL = 19<br>&nbsp;&nbsp;-Flash Live Streamcast Player URL = 20<br>&nbsp;&nbsp;-FTP LAX URL = 21<br>&nbsp;&nbsp;-FTP AMS URL = 22<br>

Returns a L<WebService::Edgecast::auto::Administration::Element::CustomerUrlUpdateResponse|WebService::Edgecast::auto::Administration::Element::CustomerUrlUpdateResponse> object.

 $response = $interface->CustomerUrlUpdate( {
    strCredential =>  $some_value, # string
    strCustomerId =>  $some_value, # string
    strCustomId =>  $some_value, # string
    strDomainTypeId =>  $some_value, # string
    strUrl =>  $some_value, # string
  },,
 );

=head3 CustomerServiceUpdate

Enable or disable services / features for a customer.<br>Required fields: strCredential, strCustomerId OR strCustomId, intServiceId, intStatus <br>Service Ids: <br>&nbsp;&nbsp;-Advanced Reports = 7<br>&nbsp;&nbsp;-Real-Time Stats = 8<br>&nbsp;&nbsp;-Token Auth = 9<br>&nbsp;&nbsp;-Edge Performance Analytics = 10<br>&nbsp;&nbsp;-Rules Engine = 17<br>Status: <br>&nbsp;&nbsp;-Enable = 1<br>&nbsp;&nbsp;-Disable = 0<br>

Returns a L<WebService::Edgecast::auto::Administration::Element::CustomerServiceUpdateResponse|WebService::Edgecast::auto::Administration::Element::CustomerServiceUpdateResponse> object.

 $response = $interface->CustomerServiceUpdate( {
    strCredential =>  $some_value, # string
    strCustomerId =>  $some_value, # string
    strCustomId =>  $some_value, # string
    intServiceId =>  $some_value, # int
    intStatus =>  $some_value, # short
  },,
 );



=head1 AUTHOR

Generated by SOAP::WSDL on Wed Dec 22 13:08:42 2010

=cut