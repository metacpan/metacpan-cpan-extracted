package Simple::JSON::Mock::Class;

use Moo;
extends 'LWP::UserAgent::JSON';
with 'Test::Mock::LWP::Distilled', 'Test::Mock::LWP::Distilled::JSON';

sub filename_suffix { 'not-used-in-these-tests' }

sub distilled_request_from_request {
    return 'Ignored';
}

1;
