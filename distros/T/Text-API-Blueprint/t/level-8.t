#!perl

use t::tests;
use Text::API::Blueprint qw(Compile);

plan tests => 6;

################################################################################

tdt( Compile(), <<'EOT', 'Compile()' );
FORMAT: 1A8
EOT

################################################################################

tdt( Compile( {} ), <<'EOT', 'Compile({})' );
FORMAT: 1A8
EOT

################################################################################

tdt( Compile( { host => 'host' } ), <<'EOT', 'Compile({host})' );
FORMAT: 1A8
HOST: host
EOT

################################################################################

tdt( Compile( { name => 'name' } ), <<'EOT', 'Compile({name})' );
FORMAT: 1A8

# name
EOT

################################################################################

tdt( Compile( { host => 'host', name => 'name' } ),
    <<'EOT', 'Compile({host,name})' );
FORMAT: 1A8
HOST: host

# name
EOT

################################################################################

tdt(
    Compile(
        {
            host        => 'host',
            name        => 'name',
            description => 'description1',
            resources   => [
                {
                    description => 'description2',
                    uri         => 'uri'
                }
            ],
            groups => [
                foo => 'bar'
            ]
        }
    ),
    <<'EOT', 'Compile({host,name,description,resources,groups})' );
FORMAT: 1A8
HOST: host

# name

description1

## uri

description2

# Group foo

bar
EOT

################################################################################

done_testing;
