package Test::Run::CmdLine::Plugin::YamlTest;

use strict;
use warnings;


sub private_non_direct_backend_env_mapping
{
    my $self = shift;

    return
    [
        {
            type => "yamldata",
            env => "TEST_RUN_YAML_TEST",
            arg => "yaml_test",
        },
    ];
}

1;

