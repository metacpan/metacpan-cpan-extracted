package VCI::VCS::APIVersionTooLow;
use Moose;

extends 'VCI::VCS::Test';

override 'api_version' => sub {
    return { major => VCI->api_version->{major}, 
             api => (VCI->api_version->{api} - 1) };
};

1;
