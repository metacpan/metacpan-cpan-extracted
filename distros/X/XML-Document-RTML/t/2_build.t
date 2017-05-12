# XML::Document::RTML test harness

# strict
use strict;

#load test
use Test::More tests => 94;

# load modules
BEGIN {
   use_ok("XML::Document::RTML");
}

# debugging
use Data::Dumper;

# T E S T   H A R N E S S --------------------------------------------------

# test the test system
ok(1, "Testing the test harness");

# read from data block
my @buffer = <DATA>;
chomp @buffer;  

# Score Request 1
# ---------------

# Create an RTML object
my $object1 = new XML::Document::RTML( 
             Host        => 'exo.astro.ex.ac.uk',
             Port        => '8000',
             ID          => 'IA:aa@bofh.astro.ex.ac.uk:2000:0001',
             User        => 'aa',
             Name        => 'Alasdair Allan',
             Institution => 'University of Exeter',
             Email       => 'aa@astro.ex.ac.uk',
	     Target => 'Test Target',
             RA     => '09 00 00',
             Dec    => '+60 00 00', 
             Snr    => '3.0',
             Flux   => '12.0');

my $message1 = $object1->build( Type => "score" );

# check some tag information
is( $object1->ra(), '09 00 00', "Checking the RA" );
is( $object1->dec(), '+60 00 00', "Checking the Dec" );
is( $object1->signal_to_noise(), "3.0", "Checking the S/N" );
is( $object1->reference_flux(), "12.0", "Checking the S/N" );

#print Dumper( $message1 );

# Score Request 2
# ---------------

# Create an RTML object
my $object2 = new XML::Document::RTML( 
             Port        => '1234',
             Host        => 'localhost',
             ID          => '12345',
             User        => 'TMC/estar',
             Name        => 'Chris Mottram',
             Institution => 'LJM',
             Email       => 'cjm@astro.livjm.ac.uk',
             Target => 'test',
             TargetIdent => 'test-ident',
             RA     => '01 02 03.0',
             Dec    => '+45 56 01.0',
             Exposure => '120',
             Filter => 'R',
             GroupCount  => '2',
             TimeConstraint => [ '2005-01-01T12:00:00',
                                 '2005-12-31T12:00:00' ],
             SeriesCount => '3',
             Interval    => '1H',
             Tolerance   => '30M'  );

# check some tag information
is( $object2->ra(), '01 02 03.0', "Checking the RA" );
is( $object2->dec(), '+45 56 01.0', "Checking the Dec" );

# build the document
my $message2a = $object2->build( Type => "score" );

# check the returned document
my @xml2a = split( /\n/, $message2a );
foreach my $i ( 0 ... $#buffer ) {
   is( $xml2a[$i], $buffer[$i], "comparing line $i in 21st XML document" );
}

# check the document dumped from the buffer
my $message2b = $object2->dump_rtml();
my @xml2b = split( /\n/, $message2b );
foreach my $j ( 0 ... $#buffer ) {
   is( $xml2b[$j], $buffer[$j], "comparing line $j in 2nd XML document" );
}

#print Dumper( $message2a );


# T I M E   A T   T H E   B A R ---------------------------------------------

exit;  

# D A T A   B L O C K --------------------------------------------------------

__DATA__
<?xml version="1.0" encoding="ISO-8859-1"?>
<!DOCTYPE RTML SYSTEM "http://www.estar.org.uk/documents/rtml2.2.dtd">

<RTML version="2.2" type="score">
    <Contact PI="true">
        <Name>Chris Mottram</Name>
        <User>TMC/estar</User>
        <Institution>LJM</Institution>
        <Email>cjm@astro.livjm.ac.uk</Email>
    </Contact>
    <Project />
    <Telescope />
    <IntelligentAgent host="localhost" port="1234">12345</IntelligentAgent>
    <Observation status="ok">
        <Target type="normal" ident="test-ident">
            <TargetName>test</TargetName>
            <Coordinates type="equatorial">
                <RightAscension format="hh mm ss.ss" units="hms">01 02 03.0</RightAscension>
                <Declination format="dd mm ss.ss" units="dms">+45 56 01.0</Declination>
                <Equinox>J2000</Equinox>
            </Coordinates>
        </Target>
        <Device type="camera">
            <Filter>
                <FilterType>R</FilterType>
            </Filter>
        </Device>
        <Schedule priority="3">
            <Exposure type="time" units="seconds">
                <Count>2</Count>120
            </Exposure>
            <TimeConstraint>
                <StartDateTime>2005-01-01T12:00:00</StartDateTime>
                <EndDateTime>2005-12-31T12:00:00</EndDateTime>
            </TimeConstraint>
            <SeriesConstraint>
                <Count>3</Count>
                <Interval>PT1H</Interval>
                <Tolerance>PT30M</Tolerance>
            </SeriesConstraint>
        </Schedule>
    </Observation>
</RTML>
