# XML::Document::Transport test harness

# strict
use strict;

#load test
use Test::More tests => 6;

# load modules
BEGIN {
   use_ok("XML::Document::Transport");
}

# debugging
use Data::Dumper;

# T E S T   H A R N E S S --------------------------------------------------

# test the test system
ok(1);

# read from data block
my @buffer = <DATA>;
chomp @buffer;  

my $xml = "";
foreach my $i ( 0 ... $#buffer ) {
   $xml = $xml . $buffer[$i];
}   

my $object = new XML::Document::Transport( XML => $xml );

my $role = $object->role( );
is( $role, "ack", "comparing roles" );

my $origin = $object->origin( );
is( $origin, "ivo://uk.org.estar/pl.edu.ogle#OGLE-2006-BLG-296", "comparing <Origin> strings" );

my $response = $object->response( );
is( $response, "ivo://talons.lanl/#", "comparing <Response> strings" );

my $timestamp = $object->time( );
is( $timestamp, "2005-04-15T23:59:59", "comparing <TimeStamp> strings" );

# T I M E   A T   T H E   B A R ---------------------------------------------

exit;  

# D A T A   B L O C K --------------------------------------------------------

__DATA__
<?xml version="1.0" encoding="UTF-8"?>

<trn:Transport role="ack" version="0.1" 
    xmlns:trn="http://www.telescope-networks.org/xml/Transport/v0.1" 
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://www.telescope-networks.org/xml/Transport/v0.1 http://www.telescope-networks.org/schema/Transport-v0.1.xsd">

<Origin>ivo://uk.org.estar/pl.edu.ogle#OGLE-2006-BLG-296</Origin>
<Response>ivo://talons.lanl/#</Response>
<TimeStamp>2005-04-15T23:59:59</TimeStamp>
<Meta>
  <Group name="Server Parameters" >
    <Param name="HOST" value="astro.lanl.gov" />
    <Param name="PORT" value="43003"  />
  </Group>
  <Param name="STORED" ucd="meta.ref.url" value="http://astro.lanl.gov/cgi-bin/query.pl?id=OGLE-2006-BLG-296" />
</Meta>
</trn:Transport>
