package VCI::VCS::VersionJustRight;
use Moose;

extends 'VCI::VCS::Test';

sub api_version {
    return VCI->api_version;
}

1;
