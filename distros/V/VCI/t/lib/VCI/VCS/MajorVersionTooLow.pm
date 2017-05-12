package VCI::VCS::MajorVersionTooLow;
use Moose;

extends 'VCI::VCS::Test';

override 'api_version' => sub {
    return { major => (VCI->api_version->{major} - 1), 
             api   => 0 };
};

1;
