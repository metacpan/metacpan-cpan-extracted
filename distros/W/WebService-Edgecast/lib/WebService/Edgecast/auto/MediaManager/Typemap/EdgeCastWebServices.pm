
package WebService::Edgecast::auto::MediaManager::Typemap::EdgeCastWebServices;
BEGIN {
  $WebService::Edgecast::auto::MediaManager::Typemap::EdgeCastWebServices::VERSION = '0.01.00';
}
use strict;
use warnings;

our $typemap_1 = {
               'WmsPubPointGetResponse/WmsPubPointGetResult/PullSource' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'FmsLiveAuthStreamKeyAdd/strCredential' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'WmsPubPointGet/intId' => 'SOAP::WSDL::XSD::Typelib::Builtin::int',
               'FmsLiveAuthGlobalKeyUpdate/strGlobalKey' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'WmsPubPointsGet/strCustomerId' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'PurgeFileFromEdgeMemory/intMediaType' => 'SOAP::WSDL::XSD::Typelib::Builtin::int',
               'WmsPubPointGet/strCredential' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'TokenDirAdd' => 'WebService::Edgecast::auto::MediaManager::Element::TokenDirAdd',
               'TokenEncrypt/strCredential' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'LoadFileToEdge/strCredential' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'WmsPubPointAdd/blnEnableBuffering' => 'SOAP::WSDL::XSD::Typelib::Builtin::boolean',
               'WmsPubPointUpdate' => 'WebService::Edgecast::auto::MediaManager::Element::WmsPubPointUpdate',
               'FmsLiveAuthStreamKeysGet/strCustomerId' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'WmsPubPointDeleteResponse/WmsPubPointDeleteResult' => 'SOAP::WSDL::XSD::Typelib::Builtin::int',
               'WmsPubPointsGetResponse/WmsPubPointsGetResult/WmsPubPoint/Id' => 'SOAP::WSDL::XSD::Typelib::Builtin::int',
               'FmsLiveAuthStreamKeyGet/strCredential' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'FmsLiveAuthStreamKeyAdd/strCustomerId' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'FmsLiveAuthStreamKeyUpdateResponse' => 'WebService::Edgecast::auto::MediaManager::Element::FmsLiveAuthStreamKeyUpdateResponse',
               'WmsPubPointsGetResponse/WmsPubPointsGetResult/WmsPubPoint/Name' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'PurgeFileFromEdgeResponse/PurgeFileFromEdgeResult' => 'SOAP::WSDL::XSD::Typelib::Builtin::short',
               'WmsPubPointMethodsGet/strCustomerId' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'FmsLiveAuthStreamKeyUpdate/strStreamKey' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'FmsLiveAuthGlobalKeyUpdate' => 'WebService::Edgecast::auto::MediaManager::Element::FmsLiveAuthGlobalKeyUpdate',
               'FmsLiveAuthGlobalKeyGetResponse' => 'WebService::Edgecast::auto::MediaManager::Element::FmsLiveAuthGlobalKeyGetResponse',
               'WmsPubPointUpdateResponse/WmsPubPointUpdateResult' => 'SOAP::WSDL::XSD::Typelib::Builtin::int',
               'WmsPubPointMethodsGetResponse/WmsPubPointMethodsGetResult/WmsPubPointMethod/Id' => 'SOAP::WSDL::XSD::Typelib::Builtin::int',
               'FmsLiveAuthStreamKeysGet' => 'WebService::Edgecast::auto::MediaManager::Element::FmsLiveAuthStreamKeysGet',
               'TokenEncrypt/strKey' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'PurgeFileFromEdge' => 'WebService::Edgecast::auto::MediaManager::Element::PurgeFileFromEdge',
               'WmsPubPointGetResponse/WmsPubPointGetResult/Id' => 'SOAP::WSDL::XSD::Typelib::Builtin::int',
               'WmsPubPointGetResponse/WmsPubPointGetResult' => 'WebService::Edgecast::auto::MediaManager::Type::WmsPubPoint',
               'TokenEncrypt' => 'WebService::Edgecast::auto::MediaManager::Element::TokenEncrypt',
               'FmsLiveAuthGlobalKeyUpdate/strCustomerId' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'WmsPubPointMethodsGet' => 'WebService::Edgecast::auto::MediaManager::Element::WmsPubPointMethodsGet',
               'FmsLiveAuthStreamKeyGet/strCustomerId' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'LoadFileToEdge' => 'WebService::Edgecast::auto::MediaManager::Element::LoadFileToEdge',
               'FmsLiveAuthGlobalKeyGet' => 'WebService::Edgecast::auto::MediaManager::Element::FmsLiveAuthGlobalKeyGet',
               'PurgeFileFromEdge/strCredential' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'PurgeFileFromEdgeMemoryResponse' => 'WebService::Edgecast::auto::MediaManager::Element::PurgeFileFromEdgeMemoryResponse',
               'WmsPubPointUpdate/strName' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'WmsPubPointsGetResponse/WmsPubPointsGetResult/WmsPubPoint/PullSource' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'WmsPubPointDelete/strCustomerId' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'LoadFileToEdge/strCustomerId' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'WmsPubPointsGetResponse/WmsPubPointsGetResult' => 'WebService::Edgecast::auto::MediaManager::Type::ArrayOfWmsPubPoint',
               'FmsLiveAuthStreamKeyAddResponse/FmsLiveAuthStreamKeyAddResult' => 'SOAP::WSDL::XSD::Typelib::Builtin::int',
               'FmsLiveAuthStreamKeyAdd/strStreamPath' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'WmsPubPointAdd/strPullSourceUrl' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'FmsLiveAuthGlobalKeyUpdateResponse' => 'WebService::Edgecast::auto::MediaManager::Element::FmsLiveAuthGlobalKeyUpdateResponse',
               'WmsPubPointGetResponse/WmsPubPointGetResult/MethodId' => 'SOAP::WSDL::XSD::Typelib::Builtin::int',
               'WmsPubPointGetResponse/WmsPubPointGetResult/PushUrl' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'TokenDirAdd/intMediaType' => 'SOAP::WSDL::XSD::Typelib::Builtin::int',
               'WmsPubPointsGet' => 'WebService::Edgecast::auto::MediaManager::Element::WmsPubPointsGet',
               'WmsPubPointGetResponse/WmsPubPointGetResult/MethodName' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'TokenKeyUpdateResponse/TokenKeyUpdateResult' => 'SOAP::WSDL::XSD::Typelib::Builtin::short',
               'WmsPubPointUpdate/blnEnableBuffering' => 'SOAP::WSDL::XSD::Typelib::Builtin::boolean',
               'FmsLiveAuthStreamKeyGet' => 'WebService::Edgecast::auto::MediaManager::Element::FmsLiveAuthStreamKeyGet',
               'FmsLiveAuthStreamKeyGetResponse/FmsLiveAuthStreamKeyGetResult' => 'WebService::Edgecast::auto::MediaManager::Type::FmsLiveAuthKey',
               'TokenKeyUpdate/strKey' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'FmsLiveAuthStreamKeysGetResponse/FmsLiveAuthStreamKeysGetResult' => 'WebService::Edgecast::auto::MediaManager::Type::ArrayOfFmsLiveAuthKey',
               'WmsPubPointAdd/strCustomerId' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'FmsLiveAuthStreamKeyDelete' => 'WebService::Edgecast::auto::MediaManager::Element::FmsLiveAuthStreamKeyDelete',
               'FmsLiveAuthStreamKeyGetResponse' => 'WebService::Edgecast::auto::MediaManager::Element::FmsLiveAuthStreamKeyGetResponse',
               'TokenEncryptResponse/TokenEncryptResult' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'FmsLiveAuthGlobalKeyGet/strCustomerId' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'TokenDirAdd/strDir' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'LoadFileToEdgeResponse' => 'WebService::Edgecast::auto::MediaManager::Element::LoadFileToEdgeResponse',
               'FmsLiveAuthStreamKeyAdd' => 'WebService::Edgecast::auto::MediaManager::Element::FmsLiveAuthStreamKeyAdd',
               'WmsPubPointDelete/intId' => 'SOAP::WSDL::XSD::Typelib::Builtin::int',
               'WmsPubPointGetResponse' => 'WebService::Edgecast::auto::MediaManager::Element::WmsPubPointGetResponse',
               'WmsPubPointAddResponse' => 'WebService::Edgecast::auto::MediaManager::Element::WmsPubPointAddResponse',
               'WmsPubPointAdd/strName' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'LoadFileToEdgeResponse/LoadFileToEdgeResult' => 'SOAP::WSDL::XSD::Typelib::Builtin::short',
               'PurgeFileFromEdgeMemoryResponse/PurgeFileFromEdgeMemoryResult' => 'SOAP::WSDL::XSD::Typelib::Builtin::short',
               'WmsPubPointGet/strCustomerId' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'Fault' => 'SOAP::WSDL::SOAP::Typelib::Fault11',
               'FmsLiveAuthStreamKeyDeleteResponse' => 'WebService::Edgecast::auto::MediaManager::Element::FmsLiveAuthStreamKeyDeleteResponse',
               'WmsPubPointGetResponse/WmsPubPointGetResult/Name' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'PurgeFileFromEdgeMemory/strPath' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'Fault/faultactor' => 'SOAP::WSDL::XSD::Typelib::Builtin::token',
               'WmsPubPointsGetResponse/WmsPubPointsGetResult/WmsPubPoint/MethodId' => 'SOAP::WSDL::XSD::Typelib::Builtin::int',
               'FmsLiveAuthStreamKeyUpdate/intId' => 'SOAP::WSDL::XSD::Typelib::Builtin::int',
               'FmsLiveAuthStreamKeyAddResponse' => 'WebService::Edgecast::auto::MediaManager::Element::FmsLiveAuthStreamKeyAddResponse',
               'WmsPubPointMethodsGet/strCredential' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'FmsLiveAuthStreamKeyUpdate/strCredential' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'FmsLiveAuthStreamKeyGetResponse/FmsLiveAuthStreamKeyGetResult/Id' => 'SOAP::WSDL::XSD::Typelib::Builtin::int',
               'WmsPubPointUpdate/strCustomerId' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'WmsPubPointAddResponse/WmsPubPointAddResult' => 'SOAP::WSDL::XSD::Typelib::Builtin::int',
               'PurgeFileFromEdge/strCustomerId' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'WmsPubPointAdd/intMethodId' => 'SOAP::WSDL::XSD::Typelib::Builtin::int',
               'TokenDirAdd/strCredential' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'Fault/faultcode' => 'SOAP::WSDL::XSD::Typelib::Builtin::anyURI',
               'WmsPubPointMethodsGetResponse' => 'WebService::Edgecast::auto::MediaManager::Element::WmsPubPointMethodsGetResponse',
               'LoadFileToEdge/strPath' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'PurgeFileFromEdgeResponse' => 'WebService::Edgecast::auto::MediaManager::Element::PurgeFileFromEdgeResponse',
               'WmsPubPointGetResponse/WmsPubPointGetResult/Url' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'WmsPubPointDelete' => 'WebService::Edgecast::auto::MediaManager::Element::WmsPubPointDelete',
               'TokenDirAddResponse' => 'WebService::Edgecast::auto::MediaManager::Element::TokenDirAddResponse',
               'WmsPubPointsGet/strCredential' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'WmsPubPointsGetResponse/WmsPubPointsGetResult/WmsPubPoint/MethodName' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'WmsPubPointUpdate/intId' => 'SOAP::WSDL::XSD::Typelib::Builtin::int',
               'TokenKeyUpdate/intMediaType' => 'SOAP::WSDL::XSD::Typelib::Builtin::int',
               'FmsLiveAuthStreamKeysGetResponse/FmsLiveAuthStreamKeysGetResult/FmsLiveAuthKey/Id' => 'SOAP::WSDL::XSD::Typelib::Builtin::int',
               'WmsPubPointMethodsGetResponse/WmsPubPointMethodsGetResult/WmsPubPointMethod' => 'WebService::Edgecast::auto::MediaManager::Type::WmsPubPointMethod',
               'PurgeFileFromEdgeMemory/strCustomerId' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'FmsLiveAuthStreamKeyUpdateResponse/FmsLiveAuthStreamKeyUpdateResult' => 'SOAP::WSDL::XSD::Typelib::Builtin::int',
               'TokenDirAddResponse/TokenDirAddResult' => 'SOAP::WSDL::XSD::Typelib::Builtin::short',
               'WmsPubPointMethodsGetResponse/WmsPubPointMethodsGetResult/WmsPubPointMethod/Name' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'Fault/faultstring' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'WmsPubPointsGetResponse' => 'WebService::Edgecast::auto::MediaManager::Element::WmsPubPointsGetResponse',
               'FmsLiveAuthStreamKeysGetResponse' => 'WebService::Edgecast::auto::MediaManager::Element::FmsLiveAuthStreamKeysGetResponse',
               'WmsPubPointsGetResponse/WmsPubPointsGetResult/WmsPubPoint/Url' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'FmsLiveAuthStreamKeysGet/strCredential' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'LoadFileToEdge/intMediaType' => 'SOAP::WSDL::XSD::Typelib::Builtin::int',
               'WmsPubPointGet' => 'WebService::Edgecast::auto::MediaManager::Element::WmsPubPointGet',
               'WmsPubPointsGetResponse/WmsPubPointsGetResult/WmsPubPoint/TypeName' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'PurgeFileFromEdge/intMediaType' => 'SOAP::WSDL::XSD::Typelib::Builtin::int',
               'FmsLiveAuthGlobalKeyGet/strCredential' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'Fault/detail' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'FmsLiveAuthStreamKeyAdd/strStreamKey' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'PurgeFileFromEdge/strPath' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'TokenKeyUpdate' => 'WebService::Edgecast::auto::MediaManager::Element::TokenKeyUpdate',
               'WmsPubPointDelete/strCredential' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'PurgeFileFromEdgeMemory/strCredential' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'TokenEncrypt/strArgs' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'TokenEncryptResponse' => 'WebService::Edgecast::auto::MediaManager::Element::TokenEncryptResponse',
               'TokenKeyUpdate/strCustomerId' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'WmsPubPointDeleteResponse' => 'WebService::Edgecast::auto::MediaManager::Element::WmsPubPointDeleteResponse',
               'WmsPubPointMethodsGetResponse/WmsPubPointMethodsGetResult' => 'WebService::Edgecast::auto::MediaManager::Type::ArrayOfWmsPubPointMethod',
               'WmsPubPointGetResponse/WmsPubPointGetResult/TypeName' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'WmsPubPointsGetResponse/WmsPubPointsGetResult/WmsPubPoint/EnableBuffering' => 'SOAP::WSDL::XSD::Typelib::Builtin::boolean',
               'WmsPubPointUpdate/intMethodId' => 'SOAP::WSDL::XSD::Typelib::Builtin::int',
               'FmsLiveAuthStreamKeyGet/intId' => 'SOAP::WSDL::XSD::Typelib::Builtin::int',
               'WmsPubPointAdd' => 'WebService::Edgecast::auto::MediaManager::Element::WmsPubPointAdd',
               'FmsLiveAuthGlobalKeyUpdateResponse/FmsLiveAuthGlobalKeyUpdateResult' => 'SOAP::WSDL::XSD::Typelib::Builtin::int',
               'TokenKeyUpdateResponse' => 'WebService::Edgecast::auto::MediaManager::Element::TokenKeyUpdateResponse',
               'TokenKeyUpdate/strCredential' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'FmsLiveAuthStreamKeyDelete/strCustomerId' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'WmsPubPointUpdateResponse' => 'WebService::Edgecast::auto::MediaManager::Element::WmsPubPointUpdateResponse',
               'FmsLiveAuthStreamKeysGetResponse/FmsLiveAuthStreamKeysGetResult/FmsLiveAuthKey/Path' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'WmsPubPointGetResponse/WmsPubPointGetResult/EnableBuffering' => 'SOAP::WSDL::XSD::Typelib::Builtin::boolean',
               'WmsPubPointUpdate/strPullSourceUrl' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'FmsLiveAuthStreamKeyDelete/strCredential' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'FmsLiveAuthStreamKeyDeleteResponse/FmsLiveAuthStreamKeyDeleteResult' => 'SOAP::WSDL::XSD::Typelib::Builtin::int',
               'FmsLiveAuthGlobalKeyUpdate/strCredential' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'FmsLiveAuthStreamKeyGetResponse/FmsLiveAuthStreamKeyGetResult/Key' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'FmsLiveAuthStreamKeyDelete/intId' => 'SOAP::WSDL::XSD::Typelib::Builtin::int',
               'WmsPubPointUpdate/strCredential' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'FmsLiveAuthStreamKeysGetResponse/FmsLiveAuthStreamKeysGetResult/FmsLiveAuthKey/Key' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'WmsPubPointsGetResponse/WmsPubPointsGetResult/WmsPubPoint' => 'WebService::Edgecast::auto::MediaManager::Type::WmsPubPoint',
               'WmsPubPointAdd/strCredential' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'FmsLiveAuthStreamKeyGetResponse/FmsLiveAuthStreamKeyGetResult/Path' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'WmsPubPointsGetResponse/WmsPubPointsGetResult/WmsPubPoint/PushUrl' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'TokenDirAdd/strCustomerId' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'FmsLiveAuthStreamKeyUpdate/strCustomerId' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'PurgeFileFromEdgeMemory' => 'WebService::Edgecast::auto::MediaManager::Element::PurgeFileFromEdgeMemory',
               'FmsLiveAuthStreamKeyUpdate' => 'WebService::Edgecast::auto::MediaManager::Element::FmsLiveAuthStreamKeyUpdate',
               'FmsLiveAuthStreamKeyUpdate/strStreamPath' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'FmsLiveAuthStreamKeysGetResponse/FmsLiveAuthStreamKeysGetResult/FmsLiveAuthKey' => 'WebService::Edgecast::auto::MediaManager::Type::FmsLiveAuthKey',
               'FmsLiveAuthGlobalKeyGetResponse/FmsLiveAuthGlobalKeyGetResult' => 'SOAP::WSDL::XSD::Typelib::Builtin::string'
             };
;

sub get_class {
  my $name = join '/', @{ $_[1] };
  return $typemap_1->{ $name };
}

sub get_typemap {
    return $typemap_1;
}

1;

__END__

__END__

=pod

=head1 NAME

WebService::Edgecast::auto::MediaManager::Typemap::EdgeCastWebServices - typemap for EdgeCastWebServices

=head1 VERSION

version 0.01.00

=head1 DESCRIPTION

Typemap created by SOAP::WSDL for map-based SOAP message parsers.

=cut