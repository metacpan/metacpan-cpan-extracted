package WWW::FCM::HTTP::Constants;

use strict;
use warnings;
use Exporter 'import';

our @EXPORT = qw{
    FCM_MissingRegistration
    FCM_InvalidRegistration
    FCM_InvalidPackageName
    FCM_MismatchSenderId
    FCM_MessageTooBig
    FCM_InvalidDataKey
    FCM_InvalidTtl
    FCM_Unavailable
    FCM_InternalServerError
    FCM_DeviceMessageRateExceeded
    FCM_TopicsMessageRateExceeded
};

use constant {
    FCM_MissingRegistration       => 'MissingRegistration',
    FCM_InvalidRegistration       => 'InvalidRegistration',
    FCM_InvalidPackageName        => 'InvalidPackageName',
    FCM_MismatchSenderId          => 'MismatchSenderId',
    FCM_MessageTooBig             => 'MessageTooBig',
    FCM_InvalidDataKey            => 'InvalidDataKey',
    FCM_InvalidTtl                => 'InvalidTtl',
    FCM_Unavailable               => 'Unavailable',
    FCM_InternalServerError       => 'InternalServerError',
    FCM_DeviceMessageRateExceeded => 'DeviceMessageRateExceeded',
    FCM_TopicsMessageRateExceeded => 'TopicsMessageRateExceeded',
};

1;
