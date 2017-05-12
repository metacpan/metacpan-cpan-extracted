
use strict;
use Test;


# use a BEGIN block so we print our plan before WebSphere::MQTT::Client is loaded
BEGIN { plan tests => 3 }

# load WebSphere::MQTT::Client
use WebSphere::MQTT::Client;


# Helpful notes.  All note-lines must start with a "#".
print "# I'm testing WebSphere::MQTT::Client version $WebSphere::MQTT::Client::VERSION\n";

# Module has loaded sucessfully 
ok(1);



# Now try creating a new WebSphere::MQTT::Client object
my $mqtt = WebSphere::MQTT::Client->new(
        #Debug => 1,
        Hostname => '127.0.0.1',
        Port => 59999,
	retry_count => 0,
	retry_interval => 0,
);

ok( $mqtt );

my $rc = $mqtt->connect();
ok( $rc eq 'FAILED' );

#$mqtt->disconnect();
#ok( 1 );

exit;

