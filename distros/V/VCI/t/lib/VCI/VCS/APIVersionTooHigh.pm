package VCI::VCS::APIVersionTooHigh;
use Moose;

extends 'VCI::VCS::Test';

override 'api_version' => sub {
    return { major => VCI->api_version->{major}, api => 1000 };
};

1;
