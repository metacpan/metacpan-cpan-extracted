package VCI::VCS::MajorVersionTooHigh;
use Moose;

extends 'VCI::VCS::Test';

override 'api_version' => sub {
    return { major => 100, api => 0 };
};

1;
