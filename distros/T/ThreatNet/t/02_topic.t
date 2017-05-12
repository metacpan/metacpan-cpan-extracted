#!/usr/bin/perl

# SQL::String basic functionality tests

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}





# Does everything load?
use Test::More 'tests' => 24;
use ThreatNet::Topic ();

# Sample strings
my $string1 = 'threatnet://ali.as/threatnet/topic/iponly open, tolerant, devel';
my $string2 = 'threatnet://ali.as/threatnet/topic/iponly';





# Create a new plain SQL object
my $Topic = ThreatNet::Topic->new($string1);
isa_ok( $Topic, 'ThreatNet::Topic' );
ok( $Topic, 'A ThreatNet::Topic object is true' );
is( "$Topic", $string1, 'Object stringifies back to original string' );

# Check the accessors
is( $Topic->topic, $string1, '->topic matches original string' );
isa_ok( $Topic->URI, 'URI' );
is( $Topic->config, 'open, tolerant, devel', '->config returns as expected' );
is( $Topic->URI->as_string, 'threatnet://ali.as/threatnet/topic/iponly', 'URI matches original' );






# Check for a no-config string
$Topic = ThreatNet::Topic->new($string2);
isa_ok( $Topic, 'ThreatNet::Topic' );
ok( $Topic, 'A ThreatNet::Topic object is true' );
is( "$Topic", $string2, 'Object stringifies back to original string' );
is( $Topic->topic, $string2, '->topic matches original string' );
isa_ok( $Topic->URI, 'URI' );
is( $Topic->config, '', '->config is a null stirng' );
is( $Topic->URI->as_string, 'threatnet://ali.as/threatnet/topic/iponly', 'URI matches original' );





# Check various bad things
my @bad = (
	'',
	' ',
	' threatnet://ali.as/threatnet',
	'foo://ali.as/threatnet',
	'threatnet:///threatnet',
	'/threatnet',
	'threatnet://ali.as',
	[],
	{},
	\"constant",
	);

foreach my $topic ( @bad ) {
	$Topic = ThreatNet::Topic->new($topic);
	is( $Topic, undef, 'Bad topic string returns undef' );
}

exit(0);
