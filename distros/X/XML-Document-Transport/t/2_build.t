# XML::Document::Transport test harness

# strict
use strict;

#load test
use Test::More tests => 18;

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

my $object = new XML::Document::Transport();
my $document = $object->build( 
     Role => 'ack',
     Origin => 'ivo://uk.org.estar/estar.ex#',
     Response => 'ivo://talons.lanl/#',
     TimeStamp => '2005-04-16T00:00:03',
     Meta => [ { Group => [ { Name  => 'stored',
                  UCD   => 'meta.ref.url',
           Value => 'http://www.estar.org.uk/cgi-bin/query.cgi?message=12345' },
               { Name  => 'misc',
                 UCD   => 'misc.junk',
                 Value => 'unknown' } ] },
               { Name  => 'stored',
                  UCD   => 'meta.ref.url',
           Value => 'http://www.estar.org.uk/cgi-bin/query.cgi?message=12345' },
               { Name  => 'misc',
                 UCD   => 'misc.junk',
                 Value => 'unknown' } ],
                                   
    );

print "\n\n$document\n\n";
                  
my @xml = split( /\n/, $document );
foreach my $i ( 0 ... $#buffer ) {
   is( $xml[$i], $buffer[$i], "comparing line $i in XML document" );
}

my $origin = $object->origin( );
is( $origin, "ivo://uk.org.estar/estar.ex#", "comparing ID strings" );


# T I M E   A T   T H E   B A R ---------------------------------------------

exit;  

# D A T A   B L O C K --------------------------------------------------------

__DATA__
<?xml version="1.0" encoding="UTF-8"?>

<trn:Transport role="ack" version="0.1" xmlns:trn="http://www.telescope-networks.org/xml/Transport/v0.1" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.telescope-networks.org/xml/Transport/v0.1 http://www.telescope-networks.org/schema/Transport-v0.1.xsd">
    <Origin>ivo://uk.org.estar/estar.ex#</Origin>
    <Response>ivo://talons.lanl/#</Response>
    <TimeStamp>2005-04-16T00:00:03</TimeStamp>
    <Meta>
        <Group>
            <Param name="stored" ucd="meta.ref.url" value="http://www.estar.org.uk/cgi-bin/query.cgi?message=12345" />
            <Param name="misc" ucd="misc.junk" value="unknown" />
        </Group>
        <Param name="stored" ucd="meta.ref.url" value="http://www.estar.org.uk/cgi-bin/query.cgi?message=12345" />
        <Param name="misc" ucd="misc.junk" value="unknown" />
    </Meta>
</trn:Transport>
