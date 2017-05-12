use strict;
use warnings;
use Test::More;
use WWW::Google::Cloud::Messaging::Constants;

is MissingRegistration, 'MissingRegistration';
is InvalidRegistration, 'InvalidRegistration';
is MismatchSenderId   , 'MismatchSenderId';
is NotRegistered      , 'NotRegistered';
is MessageTooBig      , 'MessageTooBig';
is InvalidDataKey     , 'InvalidDataKey';
is InvalidTtl         , 'InvalidTtl';
is Unavailable        , 'Unavailable';
is InternalServerError, 'InternalServerError';
is InvalidPackageName,  'InvalidPackageName';

done_testing;
