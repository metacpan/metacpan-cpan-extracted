
package WebService::Edgecast::auto::Reporting::Typemap::EdgeCastWebServices;
BEGIN {
  $WebService::Edgecast::auto::Reporting::Typemap::EdgeCastWebServices::VERSION = '0.01.00';
}
use strict;
use warnings;

our $typemap_1 = {
               'TrafficUsageGet/intUsageUnits' => 'SOAP::WSDL::XSD::Typelib::Builtin::int',
               'CacheStatusStatsGet/datEndDate' => 'SOAP::WSDL::XSD::Typelib::Builtin::dateTime',
               'StorageUsageGetMaxResponse' => 'WebService::Edgecast::auto::Reporting::Element::StorageUsageGetMaxResponse',
               'CacheStatusStatsGet' => 'WebService::Edgecast::auto::Reporting::Element::CacheStatusStatsGet',
               'CnameStatsGet/strCredential' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'FileStatsGetResponse/FileStatsGetResult/File/lngDownloadAttempts' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
               'CustomerBytesTransferredGetResponse/CustomerBytesTransferredGetResult' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
               'FileStatsGetResponse' => 'WebService::Edgecast::auto::Reporting::Element::FileStatsGetResponse',
               'Fault/faultcode' => 'SOAP::WSDL::XSD::Typelib::Builtin::anyURI',
               'DirStatsGetResponse/DirStatsGetResult/Directory/strDirName' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'TrafficUsageGet/intRegion' => 'SOAP::WSDL::XSD::Typelib::Builtin::int',
               'StorageUsageGetMaxResponse/StorageUsageGetMaxResult' => 'SOAP::WSDL::XSD::Typelib::Builtin::double',
               'DirStatsGet/datEndDate' => 'SOAP::WSDL::XSD::Typelib::Builtin::dateTime',
               'FileStatsGet/datBeginDate' => 'SOAP::WSDL::XSD::Typelib::Builtin::dateTime',
               'TrafficUsageGet/strCredential' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'StorageUsageGetLatest/strCredential' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'CacheStatusStatsGet/intMediaType' => 'SOAP::WSDL::XSD::Typelib::Builtin::int',
               'CustomerBytesTransferredByMediaTypeGetResponse' => 'WebService::Edgecast::auto::Reporting::Element::CustomerBytesTransferredByMediaTypeGetResponse',
               'TrafficUsageGet' => 'WebService::Edgecast::auto::Reporting::Element::TrafficUsageGet',
               'CompleteDownloadsGetResponse/CompleteDownloadsGetResult/File/lngAvgDuration' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
               'CustomerBytesTransferredGet/datBeginDate' => 'SOAP::WSDL::XSD::Typelib::Builtin::dateTime',
               'CacheStatusStatsGetResponse/CacheStatusStatsGetResult/CacheStatus/lngHits' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
               'FileStatsGetResponse/FileStatsGetResult/File/lngAvgDuration' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
               'DirStatsGetResponse/DirStatsGetResult/Directory/lngBytes' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
               'CompleteDownloadsGetResponse' => 'WebService::Edgecast::auto::Reporting::Element::CompleteDownloadsGetResponse',
               'StorageUsageGetMax/datBeginDate' => 'SOAP::WSDL::XSD::Typelib::Builtin::dateTime',
               'TrafficUsageGetResponse' => 'WebService::Edgecast::auto::Reporting::Element::TrafficUsageGetResponse',
               'DirStatsGet/strCustomerId' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'CustomerBytesTransferredGet' => 'WebService::Edgecast::auto::Reporting::Element::CustomerBytesTransferredGet',
               'CustomerBytesTransferredByMediaTypeGet/datEndDate' => 'SOAP::WSDL::XSD::Typelib::Builtin::dateTime',
               'DirStatsGet/strCredential' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'FileStatsGetResponse/FileStatsGetResult' => 'WebService::Edgecast::auto::Reporting::Type::Files',
               'CompleteDownloadsGetResponse/CompleteDownloadsGetResult/File/lngCompleteDownloads' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
               'CnameStatsGetResponse/CnameStatsGetResult/Cname/strName' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'FileStatsGetResponse/FileStatsGetResult/File/lngDailyUniques' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
               'Fault/faultstring' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'StorageUsageGetMax' => 'WebService::Edgecast::auto::Reporting::Element::StorageUsageGetMax',
               'DirStatsGetResponse/DirStatsGetResult/Directory/lngAvgDuration' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
               'TrafficUsageGet/datBeginDate' => 'SOAP::WSDL::XSD::Typelib::Builtin::dateTime',
               'FileStatsGet/strCredential' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'StorageUsageGetLatestResponse' => 'WebService::Edgecast::auto::Reporting::Element::StorageUsageGetLatestResponse',
               'CompleteDownloadsGet/datEndDate' => 'SOAP::WSDL::XSD::Typelib::Builtin::dateTime',
               'FileStatsGet/datEndDate' => 'SOAP::WSDL::XSD::Typelib::Builtin::dateTime',
               'CacheStatusStatsGetResponse/CacheStatusStatsGetResult/CacheStatus' => 'WebService::Edgecast::auto::Reporting::Type::CacheStatus',
               'CnameStatsGet/datEndDate' => 'SOAP::WSDL::XSD::Typelib::Builtin::dateTime',
               'Fault/detail' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'CnameStatsGetResponse/CnameStatsGetResult/Cname/lngBytes' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
               'CustomerBytesTransferredByMediaTypeGet/datBeginDate' => 'SOAP::WSDL::XSD::Typelib::Builtin::dateTime',
               'CacheStatusStatsGet/strCredential' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'CompleteDownloadsGet/intMediaType' => 'SOAP::WSDL::XSD::Typelib::Builtin::int',
               'CustomerBytesTransferredByMediaTypeGetResponse/CustomerBytesTransferredByMediaTypeGetResult' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
               'CnameStatsGet/intMediaType' => 'SOAP::WSDL::XSD::Typelib::Builtin::int',
               'CustomerBytesTransferredByMediaTypeGet/strCredential' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'CompleteDownloadsGet/strCustomerId' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'DirStatsGet/datBeginDate' => 'SOAP::WSDL::XSD::Typelib::Builtin::dateTime',
               'DirStatsGetResponse' => 'WebService::Edgecast::auto::Reporting::Element::DirStatsGetResponse',
               'CustomerBytesTransferredByMediaTypeGet/intMediaType' => 'SOAP::WSDL::XSD::Typelib::Builtin::int',
               'StorageUsageGetLatest/strCustomerId' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'StorageUsageGetMax/datEndDate' => 'SOAP::WSDL::XSD::Typelib::Builtin::dateTime',
               'TrafficUsageGet/intMediaType' => 'SOAP::WSDL::XSD::Typelib::Builtin::int',
               'FileStatsGetResponse/FileStatsGetResult/File/strFileName' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'CustomerBytesTransferredByMediaTypeGet' => 'WebService::Edgecast::auto::Reporting::Element::CustomerBytesTransferredByMediaTypeGet',
               'FileStatsGetResponse/FileStatsGetResult/File' => 'WebService::Edgecast::auto::Reporting::Type::File',
               'CustomerBytesTransferredGet/strCredential' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'FileStatsGetResponse/FileStatsGetResult/File/lngBytes' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
               'CompleteDownloadsGet' => 'WebService::Edgecast::auto::Reporting::Element::CompleteDownloadsGet',
               'CnameStatsGet' => 'WebService::Edgecast::auto::Reporting::Element::CnameStatsGet',
               'CnameStatsGetResponse/CnameStatsGetResult' => 'WebService::Edgecast::auto::Reporting::Type::Cnames',
               'CnameStatsGetResponse/CnameStatsGetResult/Cname/lngHits' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
               'CustomerBytesTransferredGetResponse' => 'WebService::Edgecast::auto::Reporting::Element::CustomerBytesTransferredGetResponse',
               'TrafficUsageGetResponse/TrafficUsageGetResult' => 'SOAP::WSDL::XSD::Typelib::Builtin::double',
               'CompleteDownloadsGetResponse/CompleteDownloadsGetResult/File/strFileName' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'TrafficUsageGet/strCustomerId' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'CnameStatsGet/datBeginDate' => 'SOAP::WSDL::XSD::Typelib::Builtin::dateTime',
               'CompleteDownloadsGetResponse/CompleteDownloadsGetResult/File/lngDownloadAttempts' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
               'CacheStatusStatsGetResponse/CacheStatusStatsGetResult' => 'WebService::Edgecast::auto::Reporting::Type::CacheStatuses',
               'DirStatsGet/intMediaType' => 'SOAP::WSDL::XSD::Typelib::Builtin::int',
               'FileStatsGet/intMediaType' => 'SOAP::WSDL::XSD::Typelib::Builtin::int',
               'CnameStatsGetResponse' => 'WebService::Edgecast::auto::Reporting::Element::CnameStatsGetResponse',
               'DirStatsGetResponse/DirStatsGetResult/Directory' => 'WebService::Edgecast::auto::Reporting::Type::Directory',
               'CompleteDownloadsGetResponse/CompleteDownloadsGetResult' => 'WebService::Edgecast::auto::Reporting::Type::Files',
               'DirStatsGetResponse/DirStatsGetResult/Directory/lngHits' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
               'CacheStatusStatsGetResponse' => 'WebService::Edgecast::auto::Reporting::Element::CacheStatusStatsGetResponse',
               'FileStatsGet' => 'WebService::Edgecast::auto::Reporting::Element::FileStatsGet',
               'StorageUsageGetMax/strCredential' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'CompleteDownloadsGetResponse/CompleteDownloadsGetResult/File/lngHits' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
               'StorageUsageGetLatestResponse/StorageUsageGetLatestResult' => 'SOAP::WSDL::XSD::Typelib::Builtin::double',
               'CacheStatusStatsGet/strCustomerId' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'StorageUsageGetLatest' => 'WebService::Edgecast::auto::Reporting::Element::StorageUsageGetLatest',
               'FileStatsGet/strCustomerId' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'StorageUsageGetMax/strCustomerId' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'DirStatsGetResponse/DirStatsGetResult' => 'WebService::Edgecast::auto::Reporting::Type::Directories',
               'CustomerBytesTransferredByMediaTypeGet/strCustomerId' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'DirStatsGet' => 'WebService::Edgecast::auto::Reporting::Element::DirStatsGet',
               'Fault' => 'SOAP::WSDL::SOAP::Typelib::Fault11',
               'CustomerBytesTransferredGet/strCustomerId' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'FileStatsGetResponse/FileStatsGetResult/File/lngCompleteDownloads' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
               'Fault/faultactor' => 'SOAP::WSDL::XSD::Typelib::Builtin::token',
               'CustomerBytesTransferredGet/datEndDate' => 'SOAP::WSDL::XSD::Typelib::Builtin::dateTime',
               'CacheStatusStatsGetResponse/CacheStatusStatsGetResult/CacheStatus/strName' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'CnameStatsGet/strCustomerId' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'CompleteDownloadsGet/strCredential' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'FileStatsGetResponse/FileStatsGetResult/File/lngHits' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
               'CnameStatsGetResponse/CnameStatsGetResult/Cname' => 'WebService::Edgecast::auto::Reporting::Type::Cname',
               'CompleteDownloadsGetResponse/CompleteDownloadsGetResult/File/lngDailyUniques' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
               'CompleteDownloadsGet/datBeginDate' => 'SOAP::WSDL::XSD::Typelib::Builtin::dateTime',
               'CompleteDownloadsGetResponse/CompleteDownloadsGetResult/File' => 'WebService::Edgecast::auto::Reporting::Type::File',
               'CompleteDownloadsGetResponse/CompleteDownloadsGetResult/File/lngBytes' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
               'CacheStatusStatsGet/datBeginDate' => 'SOAP::WSDL::XSD::Typelib::Builtin::dateTime'
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

WebService::Edgecast::auto::Reporting::Typemap::EdgeCastWebServices - typemap for EdgeCastWebServices

=head1 VERSION

version 0.01.00

=head1 DESCRIPTION

Typemap created by SOAP::WSDL for map-based SOAP message parsers.

=cut