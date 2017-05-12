use inc::Module::Install;

if( -e 'MANIFEST.SKIP' ) {
    system( 'pod2text lib/WebService/Buxfer.pm > README' );
}

# Define metadata
name                'WebService-Buxfer';
all_from            'lib/WebService/Buxfer.pm';

# Specific dependencies
requires 'Moose';
requires 'JSON::XS';
requires 'URI';
requires 'LWP';
requires 'HTTP::Request::Common';

WriteAll;
