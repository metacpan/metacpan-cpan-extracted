package WebService::Slack::WebApi::Exception;
use strict;
use warnings;
use utf8;
use parent 'Exception::Tiny';

package WebService::Slack::WebApi::Exception::FailureResponse;
use parent -norequire, 'WebService::Slack::WebApi::Exception';
use Class::Accessor::Lite (
    ro => [qw/ response /],
);

1;

