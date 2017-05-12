package ZCS::Admin::Interfaces::Admin::AdminSoap12;
use strict;
use warnings;
use Class::Std::Fast::Storable;
use Scalar::Util qw(blessed);
use base qw(SOAP::WSDL::Client::Base);

# only load if it hasn't been loaded before
require ZCS::Admin::Typemaps::Admin
    if not ZCS::Admin::Typemaps::Admin->can('get_class');

sub START {
    $_[0]->set_proxy('https://localhost:7071/service/admin/soap') if not $_[2]->{proxy};
    $_[0]->set_class_resolver('ZCS::Admin::Typemaps::Admin')
        if not $_[2]->{class_resolver};

    $_[0]->set_prefix($_[2]->{use_prefix}) if exists $_[2]->{use_prefix};
}

sub Auth {
    my ($self, $body, $header) = @_;
    die "Auth must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'Auth',
        soap_action => 'urn:zimbraAdmin/Auth',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( ZCS::Admin::Elements::AuthRequest )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub DelegateAuth {
    my ($self, $body, $header) = @_;
    die "DelegateAuth must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'DelegateAuth',
        soap_action => 'urn:zimbraAdmin/DelegateAuth',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( ZCS::Admin::Elements::DelegateAuthRequest )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( ZCS::Admin::Elements::context )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub SearchDirectory {
    my ($self, $body, $header) = @_;
    die "SearchDirectory must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'SearchDirectory',
        soap_action => 'urn:zimbraAdmin/SearchDirectory',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( ZCS::Admin::Elements::SearchDirectoryRequest )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( ZCS::Admin::Elements::context )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub CreateDomain {
    my ($self, $body, $header) = @_;
    die "CreateDomain must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'CreateDomain',
        soap_action => 'urn:zimbraAdmin/CreateDomain',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( ZCS::Admin::Elements::CreateDomainRequest )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( ZCS::Admin::Elements::context )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub ModifyDomain {
    my ($self, $body, $header) = @_;
    die "ModifyDomain must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'ModifyDomain',
        soap_action => 'urn:zimbraAdmin/ModifyDomain',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( ZCS::Admin::Elements::ModifyDomainRequest )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( ZCS::Admin::Elements::context )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub GetDomain {
    my ($self, $body, $header) = @_;
    die "GetDomain must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'GetDomain',
        soap_action => 'urn:zimbraAdmin/GetDomain',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( ZCS::Admin::Elements::GetDomainRequest )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( ZCS::Admin::Elements::context )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub GetAllDomains {
    my ($self, $body, $header) = @_;
    die "GetAllDomains must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'GetAllDomains',
        soap_action => 'urn:zimbraAdmin/GetAllDomains',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( ZCS::Admin::Elements::GetAllDomainsRequest )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( ZCS::Admin::Elements::context )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub DeleteDomain {
    my ($self, $body, $header) = @_;
    die "DeleteDomain must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'DeleteDomain',
        soap_action => 'urn:zimbraAdmin/DeleteDomain',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( ZCS::Admin::Elements::DeleteDomainRequest )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( ZCS::Admin::Elements::context )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub GetServer {
    my ($self, $body, $header) = @_;
    die "GetServer must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'GetServer',
        soap_action => 'urn:zimbraAdmin/GetServer',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( ZCS::Admin::Elements::GetServerRequest )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( ZCS::Admin::Elements::context )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub GetAllServers {
    my ($self, $body, $header) = @_;
    die "GetAllServers must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'GetAllServers',
        soap_action => 'urn:zimbraAdmin/GetAllServers',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( ZCS::Admin::Elements::GetAllServersRequest )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( ZCS::Admin::Elements::context )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub CreateCos {
    my ($self, $body, $header) = @_;
    die "CreateCos must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'CreateCos',
        soap_action => 'urn:zimbraAdmin/CreateCos',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( ZCS::Admin::Elements::CreateCosRequest )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( ZCS::Admin::Elements::context )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub GetCos {
    my ($self, $body, $header) = @_;
    die "GetCos must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'GetCos',
        soap_action => 'urn:zimbraAdmin/GetCos',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( ZCS::Admin::Elements::GetCosRequest )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( ZCS::Admin::Elements::context )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub GetAllCos {
    my ($self, $body, $header) = @_;
    die "GetAllCos must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'GetAllCos',
        soap_action => 'urn:zimbraAdmin/GetAllCos',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( ZCS::Admin::Elements::GetAllCosRequest )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( ZCS::Admin::Elements::context )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub ModifyCos {
    my ($self, $body, $header) = @_;
    die "ModifyCos must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'ModifyCos',
        soap_action => 'urn:zimbraAdmin/ModifyCos',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( ZCS::Admin::Elements::ModifyCosRequest )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( ZCS::Admin::Elements::context )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub RenameCos {
    my ($self, $body, $header) = @_;
    die "RenameCos must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'RenameCos',
        soap_action => 'urn:zimbraAdmin/RenameCos',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( ZCS::Admin::Elements::RenameCosRequest )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( ZCS::Admin::Elements::context )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub DeleteCos {
    my ($self, $body, $header) = @_;
    die "DeleteCos must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'DeleteCos',
        soap_action => 'urn:zimbraAdmin/DeleteCos',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( ZCS::Admin::Elements::DeleteCosRequest )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( ZCS::Admin::Elements::context )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub CreateAccount {
    my ($self, $body, $header) = @_;
    die "CreateAccount must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'CreateAccount',
        soap_action => 'urn:zimbraAdmin/CreateAccount',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( ZCS::Admin::Elements::CreateAccountRequest )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( ZCS::Admin::Elements::context )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub ModifyAccount {
    my ($self, $body, $header) = @_;
    die "ModifyAccount must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'ModifyAccount',
        soap_action => 'urn:zimbraAdmin/ModifyAccount',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( ZCS::Admin::Elements::ModifyAccountRequest )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( ZCS::Admin::Elements::context )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub RenameAccount {
    my ($self, $body, $header) = @_;
    die "RenameAccount must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'RenameAccount',
        soap_action => 'urn:zimbraAdmin/RenameAccount',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( ZCS::Admin::Elements::RenameAccountRequest )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( ZCS::Admin::Elements::context )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub GetAccountInfo {
    my ($self, $body, $header) = @_;
    die "GetAccountInfo must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'GetAccountInfo',
        soap_action => 'urn:zimbraAdmin/GetAccountInfo',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( ZCS::Admin::Elements::GetAccountInfoRequest )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( ZCS::Admin::Elements::context )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub GetAccount {
    my ($self, $body, $header) = @_;
    die "GetAccount must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'GetAccount',
        soap_action => 'urn:zimbraAdmin/GetAccount',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( ZCS::Admin::Elements::GetAccountRequest )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( ZCS::Admin::Elements::context )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub GetAccountMembership {
    my ($self, $body, $header) = @_;
    die "GetAccountMembership must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'GetAccountMembership',
        soap_action => 'urn:zimbraAdmin/GetAccountMembership',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( ZCS::Admin::Elements::GetAccountMembershipRequest )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( ZCS::Admin::Elements::context )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub GetAllAccounts {
    my ($self, $body, $header) = @_;
    die "GetAllAccounts must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'GetAllAccounts',
        soap_action => 'urn:zimbraAdmin/GetAllAccounts',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( ZCS::Admin::Elements::GetAllAccountsRequest )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( ZCS::Admin::Elements::context )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub GetAllAdminAccounts {
    my ($self, $body, $header) = @_;
    die "GetAllAdminAccounts must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'GetAllAdminAccounts',
        soap_action => 'urn:zimbraAdmin/GetAllAdminAccounts',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( ZCS::Admin::Elements::GetAllAdminAccountsRequest )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( ZCS::Admin::Elements::context )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub DeleteAccount {
    my ($self, $body, $header) = @_;
    die "DeleteAccount must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'DeleteAccount',
        soap_action => 'urn:zimbraAdmin/DeleteAccount',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( ZCS::Admin::Elements::DeleteAccountRequest )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( ZCS::Admin::Elements::context )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub CheckPasswordStrength {
    my ($self, $body, $header) = @_;
    die "CheckPasswordStrength must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'CheckPasswordStrength',
        soap_action => 'urn:zimbraAdmin/CheckPasswordStrength',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( ZCS::Admin::Elements::CheckPasswordStrengthRequest )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( ZCS::Admin::Elements::context )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub SetPassword {
    my ($self, $body, $header) = @_;
    die "SetPassword must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'SetPassword',
        soap_action => 'urn:zimbraAdmin/SetPassword',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( ZCS::Admin::Elements::SetPasswordRequest )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( ZCS::Admin::Elements::context )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub AddAccountAlias {
    my ($self, $body, $header) = @_;
    die "AddAccountAlias must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'AddAccountAlias',
        soap_action => 'urn:zimbraAdmin/AddAccountAlias',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( ZCS::Admin::Elements::AddAccountAliasRequest )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( ZCS::Admin::Elements::context )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub RemoveAccountAlias {
    my ($self, $body, $header) = @_;
    die "RemoveAccountAlias must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'RemoveAccountAlias',
        soap_action => 'urn:zimbraAdmin/RemoveAccountAlias',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( ZCS::Admin::Elements::RemoveAccountAliasRequest )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( ZCS::Admin::Elements::context )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub EnableArchive {
    my ($self, $body, $header) = @_;
    die "EnableArchive must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'EnableArchive',
        soap_action => 'urn:zimbraAdmin/EnableArchive',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( ZCS::Admin::Elements::EnableArchiveRequest )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( ZCS::Admin::Elements::context )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub DisableArchive {
    my ($self, $body, $header) = @_;
    die "DisableArchive must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'DisableArchive',
        soap_action => 'urn:zimbraAdmin/DisableArchive',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( ZCS::Admin::Elements::DisableArchiveRequest )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( ZCS::Admin::Elements::context )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub ExportMailbox {
    my ($self, $body, $header) = @_;
    die "ExportMailbox must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'ExportMailbox',
        soap_action => 'urn:zimbraAdmin/ExportMailbox',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( ZCS::Admin::Elements::ExportMailboxRequest )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( ZCS::Admin::Elements::context )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub PurgeMovedMailbox {
    my ($self, $body, $header) = @_;
    die "PurgeMovedMailbox must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'PurgeMovedMailbox',
        soap_action => 'urn:zimbraAdmin/PurgeMovedMailbox',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( ZCS::Admin::Elements::PurgeMovedMailboxRequest )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( ZCS::Admin::Elements::context )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub GetDistributionList {
    my ($self, $body, $header) = @_;
    die "GetDistributionList must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'GetDistributionList',
        soap_action => 'urn:zimbraAdmin/GetDistributionList',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( ZCS::Admin::Elements::GetDistributionListRequest )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( ZCS::Admin::Elements::context )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub CreateDistributionList {
    my ($self, $body, $header) = @_;
    die "CreateDistributionList must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'CreateDistributionList',
        soap_action => 'urn:zimbraAdmin/CreateDistributionList',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( ZCS::Admin::Elements::CreateDistributionListRequest )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( ZCS::Admin::Elements::context )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub DeleteDistributionList {
    my ($self, $body, $header) = @_;
    die "DeleteDistributionList must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'DeleteDistributionList',
        soap_action => 'urn:zimbraAdmin/DeleteDistributionList',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( ZCS::Admin::Elements::DeleteDistributionListRequest )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( ZCS::Admin::Elements::context )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub GrantRight {
    my ($self, $body, $header) = @_;
    die "GrantRight must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'GrantRight',
        soap_action => 'urn:zimbraAdmin/GrantRight',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( ZCS::Admin::Elements::GrantRightRequest )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( ZCS::Admin::Elements::context )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub RevokeRight {
    my ($self, $body, $header) = @_;
    die "RevokeRight must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'RevokeRight',
        soap_action => 'urn:zimbraAdmin/RevokeRight',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( ZCS::Admin::Elements::RevokeRightRequest )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( ZCS::Admin::Elements::context )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}




1;



__END__

=pod

=head1 NAME

ZCS::Admin::Interfaces::Admin::AdminSoap12 - SOAP Interface for the Admin Web Service

=head1 SYNOPSIS

 use ZCS::Admin::Interfaces::Admin::AdminSoap12;
 my $interface = ZCS::Admin::Interfaces::Admin::AdminSoap12->new();

 my $response;
 $response = $interface->Auth();
 $response = $interface->DelegateAuth();
 $response = $interface->SearchDirectory();
 $response = $interface->CreateDomain();
 $response = $interface->ModifyDomain();
 $response = $interface->GetDomain();
 $response = $interface->GetAllDomains();
 $response = $interface->DeleteDomain();
 $response = $interface->GetServer();
 $response = $interface->GetAllServers();
 $response = $interface->CreateCos();
 $response = $interface->GetCos();
 $response = $interface->GetAllCos();
 $response = $interface->ModifyCos();
 $response = $interface->RenameCos();
 $response = $interface->DeleteCos();
 $response = $interface->CreateAccount();
 $response = $interface->ModifyAccount();
 $response = $interface->RenameAccount();
 $response = $interface->GetAccountInfo();
 $response = $interface->GetAccount();
 $response = $interface->GetAccountMembership();
 $response = $interface->GetAllAccounts();
 $response = $interface->GetAllAdminAccounts();
 $response = $interface->DeleteAccount();
 $response = $interface->CheckPasswordStrength();
 $response = $interface->SetPassword();
 $response = $interface->AddAccountAlias();
 $response = $interface->RemoveAccountAlias();
 $response = $interface->EnableArchive();
 $response = $interface->DisableArchive();
 $response = $interface->ExportMailbox();
 $response = $interface->PurgeMovedMailbox();
 $response = $interface->GetDistributionList();
 $response = $interface->CreateDistributionList();
 $response = $interface->DeleteDistributionList();
 $response = $interface->GrantRight();
 $response = $interface->RevokeRight();



=head1 DESCRIPTION

SOAP Interface for the Admin web service
located at https://localhost:7071/service/admin/soap.

=head1 SERVICE Admin



=head2 Port AdminSoap12



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



=head3 Auth



Returns a L<ZCS::Admin::Elements::AuthResponse|ZCS::Admin::Elements::AuthResponse> object.

 $response = $interface->Auth( {
    name =>  $some_value, # string
    account =>  { # ZCS::Admin::Types::Account
      a =>  { value => $some_value },
    },
    password =>  $some_value, # string
  },,
 );

=head3 DelegateAuth



Returns a L<ZCS::Admin::Elements::DelegateAuthResponse|ZCS::Admin::Elements::DelegateAuthResponse> object.

 $response = $interface->DelegateAuth( {
    account =>  { value => $some_value },
  },,
 );

=head3 SearchDirectory



Returns a L<ZCS::Admin::Elements::SearchDirectoryResponse|ZCS::Admin::Elements::SearchDirectoryResponse> object.

 $response = $interface->SearchDirectory( {
    query =>  $some_value, # string
  },,
 );

=head3 CreateDomain



Returns a L<ZCS::Admin::Elements::CreateDomainResponse|ZCS::Admin::Elements::CreateDomainResponse> object.

 $response = $interface->CreateDomain( {
    name =>  $some_value, # string
    a =>  { value => $some_value },
  },,
 );

=head3 ModifyDomain



Returns a L<ZCS::Admin::Elements::ModifyDomainResponse|ZCS::Admin::Elements::ModifyDomainResponse> object.

 $response = $interface->ModifyDomain( {
    id =>  $some_value, # string
    a =>  { value => $some_value },
  },,
 );

=head3 GetDomain



Returns a L<ZCS::Admin::Elements::GetDomainResponse|ZCS::Admin::Elements::GetDomainResponse> object.

 $response = $interface->GetDomain( {
    domain =>  { value => $some_value },
  },,
 );

=head3 GetAllDomains



Returns a L<ZCS::Admin::Elements::GetAllDomainsResponse|ZCS::Admin::Elements::GetAllDomainsResponse> object.

 $response = $interface->GetAllDomains(,,
 );

=head3 DeleteDomain



Returns a L<ZCS::Admin::Elements::DeleteDomainResponse|ZCS::Admin::Elements::DeleteDomainResponse> object.

 $response = $interface->DeleteDomain( {
    id =>  $some_value, # string
  },,
 );

=head3 GetServer



Returns a L<ZCS::Admin::Elements::GetServerResponse|ZCS::Admin::Elements::GetServerResponse> object.

 $response = $interface->GetServer( {
    server =>  { value => $some_value },
  },,
 );

=head3 GetAllServers



Returns a L<ZCS::Admin::Elements::GetAllServersResponse|ZCS::Admin::Elements::GetAllServersResponse> object.

 $response = $interface->GetAllServers(,,
 );

=head3 CreateCos



Returns a L<ZCS::Admin::Elements::CreateCosResponse|ZCS::Admin::Elements::CreateCosResponse> object.

 $response = $interface->CreateCos( {
    name =>  $some_value, # string
    a =>  { value => $some_value },
  },,
 );

=head3 GetCos



Returns a L<ZCS::Admin::Elements::GetCosResponse|ZCS::Admin::Elements::GetCosResponse> object.

 $response = $interface->GetCos( {
    cos =>  { value => $some_value },
  },,
 );

=head3 GetAllCos



Returns a L<ZCS::Admin::Elements::GetAllCosResponse|ZCS::Admin::Elements::GetAllCosResponse> object.

 $response = $interface->GetAllCos(,,
 );

=head3 ModifyCos



Returns a L<ZCS::Admin::Elements::ModifyCosResponse|ZCS::Admin::Elements::ModifyCosResponse> object.

 $response = $interface->ModifyCos( {
    id =>  $some_value, # string
    a =>  { value => $some_value },
  },,
 );

=head3 RenameCos



Returns a L<ZCS::Admin::Elements::RenameCosResponse|ZCS::Admin::Elements::RenameCosResponse> object.

 $response = $interface->RenameCos( {
    id =>  $some_value, # string
    newName =>  $some_value, # string
  },,
 );

=head3 DeleteCos



Returns a L<ZCS::Admin::Elements::DeleteCosResponse|ZCS::Admin::Elements::DeleteCosResponse> object.

 $response = $interface->DeleteCos( {
    id =>  $some_value, # string
  },,
 );

=head3 CreateAccount



Returns a L<ZCS::Admin::Elements::CreateAccountResponse|ZCS::Admin::Elements::CreateAccountResponse> object.

 $response = $interface->CreateAccount( {
    name =>  $some_value, # string
    password =>  $some_value, # string
    a =>  { value => $some_value },
  },,
 );

=head3 ModifyAccount



Returns a L<ZCS::Admin::Elements::ModifyAccountResponse|ZCS::Admin::Elements::ModifyAccountResponse> object.

 $response = $interface->ModifyAccount( {
    id =>  $some_value, # string
    a =>  { value => $some_value },
  },,
 );

=head3 RenameAccount



Returns a L<ZCS::Admin::Elements::RenameAccountResponse|ZCS::Admin::Elements::RenameAccountResponse> object.

 $response = $interface->RenameAccount( {
    id =>  $some_value, # string
    newName =>  $some_value, # string
  },,
 );

=head3 GetAccountInfo



Returns a L<ZCS::Admin::Elements::GetAccountInfoResponse|ZCS::Admin::Elements::GetAccountInfoResponse> object.

 $response = $interface->GetAccountInfo( {
    account =>  { value => $some_value },
  },,
 );

=head3 GetAccount



Returns a L<ZCS::Admin::Elements::GetAccountResponse|ZCS::Admin::Elements::GetAccountResponse> object.

 $response = $interface->GetAccount( {
    account =>  { value => $some_value },
  },,
 );

=head3 GetAccountMembership



Returns a L<ZCS::Admin::Elements::GetAccountMembershipResponse|ZCS::Admin::Elements::GetAccountMembershipResponse> object.

 $response = $interface->GetAccountMembership( {
    account =>  { value => $some_value },
  },,
 );

=head3 GetAllAccounts



Returns a L<ZCS::Admin::Elements::GetAllAccountsResponse|ZCS::Admin::Elements::GetAllAccountsResponse> object.

 $response = $interface->GetAllAccounts( {
    domain =>  { value => $some_value },
    server =>  { value => $some_value },
  },,
 );

=head3 GetAllAdminAccounts



Returns a L<ZCS::Admin::Elements::GetAllAdminAccountsResponse|ZCS::Admin::Elements::GetAllAdminAccountsResponse> object.

 $response = $interface->GetAllAdminAccounts(,,
 );

=head3 DeleteAccount



Returns a L<ZCS::Admin::Elements::DeleteAccountResponse|ZCS::Admin::Elements::DeleteAccountResponse> object.

 $response = $interface->DeleteAccount( {
    id =>  $some_value, # string
  },,
 );

=head3 CheckPasswordStrength



Returns a L<ZCS::Admin::Elements::CheckPasswordStrengthResponse|ZCS::Admin::Elements::CheckPasswordStrengthResponse> object.

 $response = $interface->CheckPasswordStrength( {
    id =>  $some_value, # string
    password =>  $some_value, # string
  },,
 );

=head3 SetPassword



Returns a L<ZCS::Admin::Elements::SetPasswordResponse|ZCS::Admin::Elements::SetPasswordResponse> object.

 $response = $interface->SetPassword( {
    id =>  $some_value, # string
    newPassword =>  $some_value, # string
  },,
 );

=head3 AddAccountAlias



Returns a L<ZCS::Admin::Elements::AddAccountAliasResponse|ZCS::Admin::Elements::AddAccountAliasResponse> object.

 $response = $interface->AddAccountAlias( {
    id =>  $some_value, # string
    alias =>  $some_value, # string
  },,
 );

=head3 RemoveAccountAlias



Returns a L<ZCS::Admin::Elements::RemoveAccountAliasResponse|ZCS::Admin::Elements::RemoveAccountAliasResponse> object.

 $response = $interface->RemoveAccountAlias( {
    id =>  $some_value, # string
    alias =>  $some_value, # string
  },,
 );

=head3 EnableArchive



Returns a L<ZCS::Admin::Elements::EnableArchiveResponse|ZCS::Admin::Elements::EnableArchiveResponse> object.

 $response = $interface->EnableArchive( {
    account =>  { value => $some_value },
    archive =>  { # ZCS::Admin::Types::ArchiveSpecifier
      name =>  $some_value, # string
      cos =>  { value => $some_value },
      password =>  $some_value, # string
      a =>  { value => $some_value },
    },
  },,
 );

=head3 DisableArchive



Returns a L<ZCS::Admin::Elements::DisableArchiveResponse|ZCS::Admin::Elements::DisableArchiveResponse> object.

 $response = $interface->DisableArchive( {
    account =>  { value => $some_value },
  },,
 );

=head3 ExportMailbox



Returns a L<ZCS::Admin::Elements::ExportMailboxResponse|ZCS::Admin::Elements::ExportMailboxResponse> object.

 $response = $interface->ExportMailbox( {
    account => ,
  },,
 );

=head3 PurgeMovedMailbox



Returns a L<ZCS::Admin::Elements::PurgeMovedMailboxResponse|ZCS::Admin::Elements::PurgeMovedMailboxResponse> object.

 $response = $interface->PurgeMovedMailbox( {
    mbox => ,
  },,
 );

=head3 GetDistributionList



Returns a L<ZCS::Admin::Elements::GetDistributionListResponse|ZCS::Admin::Elements::GetDistributionListResponse> object.

 $response = $interface->GetDistributionList( {
    dl =>  { value => $some_value },
  },,
 );

=head3 CreateDistributionList



Returns a L<ZCS::Admin::Elements::CreateDistributionListResponse|ZCS::Admin::Elements::CreateDistributionListResponse> object.

 $response = $interface->CreateDistributionList( {
    name =>  $some_value, # string
  },,
 );

=head3 DeleteDistributionList



Returns a L<ZCS::Admin::Elements::DeleteDistributionListResponse|ZCS::Admin::Elements::DeleteDistributionListResponse> object.

 $response = $interface->DeleteDistributionList( {
    id =>  $some_value, # string
  },,
 );

=head3 GrantRight



Returns a L<ZCS::Admin::Elements::GrantRightResponse|ZCS::Admin::Elements::GrantRightResponse> object.

 $response = $interface->GrantRight( {
    target => ,
    grantee => ,
    right => ,
  },,
 );

=head3 RevokeRight



Returns a L<ZCS::Admin::Elements::RevokeRightResponse|ZCS::Admin::Elements::RevokeRightResponse> object.

 $response = $interface->RevokeRight( {
    target => ,
    grantee => ,
    right => ,
  },,
 );



=head1 AUTHOR

Generated by SOAP::WSDL on Fri Oct 21 15:05:29 2011

=cut
