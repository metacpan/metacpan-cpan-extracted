#!/usr/bin/perl

use WDDX;
use Time::Local;
use strict;

my $Index = 1;


BEGIN {
## Perl 5.6 broke the Data::Dumper tests (map always returns scalars as strings, not numbers)
## So for now these tests are skipped
#    # Try to use Data::Dumper if we can
#    eval { eval "use Data::Dumper"; };
#    $| = 1;
#    print $Data::Dumper::VERSION ? "1..10\n" : "1..7\n";
    $| = 1;
    print "1..7\n";
}
END   { print "not ok 1\n" unless $Index; }


# Test that WDDX is loaded correctly
compare( $WDDX::VERSION, $WDDX::VERSION );

my $w = new WDDX;


sub compare {
    my( $text1, $text2 ) = @_;
    
    local $^W = 0;
    print "not " unless $text1 eq $text2;
    print "ok $Index\n";
# print "First:\n $text1\nSecond:\n $text2\n\n" unless $text1 eq $text2;
    $Index++;
}


# String
{
    my $t1 = $w->deserialize(
        "<wddxPacket version='1.0'><header/><data>" .
        "<string>a string with &lt;blink&gt;HTML&lt;/blink&gt; &amp; stuff!" .
        "<char code='09'/></string></data></wddxPacket>"
    )->as_scalar;
    
    my $t2 = "a string with <blink>HTML</blink> & stuff!\t";
    
    compare( $t1, $t2 );
}


# Number
{
    my $t1 = $w->deserialize(
        "<wddxPacket version='1.0'><header/><data>" .
        "<number>-3.14159</number>" .
        "</data></wddxPacket>"
    )->as_scalar;
    
    my $t2 = -3.14159;
    
    compare( $t1, $t2 );
}


# Boolean
{
    my $t1 = $w->deserialize(
        "<wddxPacket version='1.0'><header/><data>" .
        "<boolean value='false'/></data></wddxPacket>"
    )->as_scalar;
    
    my $t2 = "";
    
    compare( $t1, $t2 );
}


# Null
{
    my $t1 = $w->deserialize(
        "<wddxPacket version='1.0'><header/><data>" .
        "<null/></data></wddxPacket>"
    )->as_scalar;
    
    my $t2 = undef;
    
    compare( $t1, $t2 );
}


# Datetime
{
    my $t1 = $w->deserialize(
        "<wddxPacket version='1.0'><header/><data>" .
        "<dateTime>1989-08-06T05:34:12</dateTime></data></wddxPacket>"
    )->as_scalar;
    
    my $t2 = timelocal( 12, 34, 5, 6, 7, 89 );
    
    compare( $t1, $t2 );
}


# Binary
{
    my $t1 = $w->deserialize(
        "<wddxPacket version='1.0'><header/><data>" .
        "<binary length='25'>UHJldGVuZCB0aGlzIGlzIGJpbmFyeS4uLg==</binary>" .
        "</data></wddxPacket>"
    )->as_scalar;
    
    my $t2 = "Pretend this is binary...";
    
    compare( $t1, $t2 );
}

## Remaining test are only run if Data::Dumper is installed.
## I may eventually come up with a way to do this w/o using it.

# Array
{
    last unless $Data::Dumper::VERSION;
    
    my $t1 = $w->deserialize(
        "<wddxPacket version='1.0'><header/><data>" .
        "<array length='7'><array length='4'><number>1</number><number>2" .
        "</number><number>3</number><number>4</number></array><string>aaa" .
        "</string><string>bbb</string><string>ccc</string><string>ddd" .
        "</string><boolean value='true'/><null/></array>" .
        "</data></wddxPacket>"
    )->as_arrayref;
    
    my @n = ( 1 .. 4 );
    my @s = qw( aaa bbb ccc ddd );
    my $b = 1;
    my $n = undef;
    
    my $t2 = [ \@n, @s, $b, $n ];
    
    compare( Dumper( $t1 ), Dumper( $t2 ) );
}


# Struct
{
    last unless $Data::Dumper::VERSION;
    
    my $t1 = $w->deserialize(
        "<wddxPacket version='1.0'><header/><data>" .
        "<struct><var name='arr'><array length='4'><number>1</number>" .
        "<number>2</number><number>3</number><number>4</number></array>" .
        "</var></struct>" .
        "</data></wddxPacket>"
    )->as_hashref;
    
    my @n = ( 1 .. 4 );
    my $t2 = { arr => \@n };
    
    compare( Dumper( $t1 ), Dumper( $t2 ) );
}


# Recordset
{
    last unless $Data::Dumper::VERSION;
    
    my $t1 = $w->deserialize(
        "<wddxPacket version='1.0'><header/><data>" .
        "<recordset rowCount='4' fieldNames='NAME,AGE'><field name='NAME'>" .
        "<string>Fred</string><string>Mary</string><string>Maude</string>" .
        "<string>Bud</string></field><field name='AGE'><number>34</number>" .
        "<number>23</number><number>45</number><number>26</number></field>" .
        "</recordset>" .
        "</data></wddxPacket>"
    );
    
    my $names = [ "NAME", "AGE" ];
    my $types = [ "string", "number" ];
    my $data  = [ [ "Fred",  34 ],
                  [ "Mary",  23 ],
                  [ "Maude", 45 ],
                  [ "Bud",   26 ] ];
    
    my $t2 = $w->recordset( $names, $types, $data );
    
    compare( Dumper( $t1 ), Dumper( $t2 ) );
}

