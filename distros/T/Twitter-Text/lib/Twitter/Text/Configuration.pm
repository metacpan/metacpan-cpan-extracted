package
    Twitter::Text::Configuration; # hide from PAUSE
use strict;
use warnings;
use JSON::XS ();
use Path::Tiny qw(path);
use File::Share qw(dist_file);

# internal use only, do not use this module directly.

my %config_cache;

sub configuration_from_file {
    my $config_name = shift;

    return $config_cache{$config_name} if exists $config_cache{$config_name};

    return $config_cache{$config_name} ||= JSON::XS::decode_json(path(dist_file('Twitter-Text', "config/$config_name.json"))->slurp);
}

sub V1 {
    return configuration_from_file('v1');
}

sub V2 {
    return configuration_from_file('v2');
}

sub V3 {
    return configuration_from_file('v3');
}

sub default_configuration {
    return V3;
}

1;
