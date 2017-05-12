# Test the interface to the persistence layer

use strict;
use Test;
use WebSphere::MQTT::Client;

BEGIN { plan tests => 19 }

our $tres;
our (@rx_messages, @tx_messages);

package PersistTest;

sub new {
  my $class = shift;
  bless {}, $class;
}

sub open {
  $tres .= ":open";
  0;  # ok
}

sub reset {
  $tres .= ":reset";
  0;
}

sub close {
  $tres .= ":close";
  0;
}

sub getAllSentMessages {
  $tres .= ":getAllSentMessages";
  @tx_messages;
}

sub getAllReceivedMessages {
  $tres .= ":getAllReceivedMessages";
  @rx_messages;
}

sub addSentMessage {
  $tres .= ":addSentMessage";
  0;
}

package main;
my ($mqtt,$rc);

# Basic test of synchronous connect (which we know will fail, given that
# we point to a stupid port)

$tres = "";
$mqtt = WebSphere::MQTT::Client->new(
	#Debug => 1,
	Persist => PersistTest->new(),
	Hostname => '127.0.0.1',
	Port => 59999,
	retry_count => 0,
	retry_interval => 0,
);
ok( $tres eq "" );
$rc = $mqtt->connect();
ok( $rc eq "FAILED" );
ok( $tres eq ":open:reset:reset:close" );
# On a connect() failure, the API calls disconnect() automatically.
# So instead of CONNECTION_BROKEN you get CONN_HANDLE_ERROR
$rc = $mqtt->publish("bar", "Topic1", 1);
ok( $rc eq "CONN_HANDLE_ERROR" );

# Now try connecting with clean_start=>0. This should invoke
# the persistence mechanism to read in any queued items.

# Note: these are garbage messages, i.e. not formatted in scada structure,
# and because they cannot be decoded they cause the connect to fail.
# (In fact they cause mspStorePublication to segfault unless you patch it)
@tx_messages = (1,"one",2,"two",3,"three");
@rx_messages = (4,"four",5,"five",6,"six");

$tres = "";
$mqtt = WebSphere::MQTT::Client->new(
	#Debug => 1,
	Persist => PersistTest->new(),
	Hostname => '127.0.0.1',
	Port => 59999,
	retry_count => 0,
	retry_interval => 0,
	clean_start => 0,
);
ok( $tres eq "" );
$rc = $mqtt->connect();
ok( $rc eq "PERSISTENCE_FAILED" );  # since we give garbage in getAllReceivedMessages
ok( $tres eq ":open:getAllSentMessages:getAllReceivedMessages" );

# Try again with no garbage rx messages

@rx_messages = ();

$tres = "";
$mqtt = WebSphere::MQTT::Client->new(
	#Debug => 1,
	Persist => PersistTest->new(),
	Hostname => '127.0.0.1',
	Port => 59999,
	retry_count => 0,
	retry_interval => 0,
	clean_start => 0,
);
ok( $tres eq "" );
$rc = $mqtt->connect();
ok( $rc eq "FAILED" );
ok( $tres eq ":open:getAllSentMessages:getAllReceivedMessages:close" );

# connect() can return other results like HOSTNAME_NOT_FOUND

$mqtt = WebSphere::MQTT::Client->new(
	#Debug => 1,
	Persist => PersistTest->new(),
	Hostname => 'flurble.example',
	Port => 59999,
	retry_count => 0,
	retry_interval => 0,
);
$rc = $mqtt->connect();
ok( $rc eq "HOSTNAME_NOT_FOUND" );

# Now try with an asynchronous connect. This leaves the connection in
# CONNECTING state, which means the persistence interface is active and
# we can publish messages even though the server connection isn't up

$tres = "";
$mqtt = WebSphere::MQTT::Client->new(
	#Debug => 1,
	Persist => PersistTest->new(),
	Hostname => '127.0.0.1',
	Port => 59999,
	retry_count => 10,
	retry_interval => 10,
	clean_start => 0,
	async => 1,
);
$rc = $mqtt->connect();
ok( ! $rc );
ok( $tres eq ":open:getAllSentMessages:getAllReceivedMessages" );

# No persistence calls made for QOS 0 messages
$tres = "";
$rc = $mqtt->publish("foo", "Topic1", 0);
ok( ! $rc );
ok( $tres eq "" );

# A very big message (>32768 bytes) will be rejected
$tres = "";
$rc = $mqtt->publish("x" x 33000, "Topic1", 1);
ok( $rc eq "Q_FULL" );
ok( $tres eq "" );

# QOS 1 will persist the message
$tres = "";
$rc = $mqtt->publish("bar", "Topic1", 1);
ok( ! $rc );
ok( $tres eq ":addSentMessage" );

exit;
