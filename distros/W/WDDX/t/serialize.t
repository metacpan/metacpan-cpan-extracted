#!/usr/bin/perl

use WDDX;
use Time::Local;
use strict;

my $Index = 1;

BEGIN { $| = 1; print "1..10\n"; }
END   { print "not ok 1\n" unless $Index; }

# Test that it's loaded correctly
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
    my $t1 = $w->serialize(
        $w->string( "a string with <blink>HTML</blink> & stuff!\t" )
    );
    
    my $t2 = "<wddxPacket version='1.0'><header/><data>" .
      "<string>a string with &lt;blink&gt;HTML&lt;/blink&gt; &amp; stuff!" .
      "<char code='09'/></string></data></wddxPacket>";
    
    compare( $t1, $t2 );
}


# Number
{
    my $t1 = $w->serialize(
        $w->number( -3.14159 )
    );
    
    my $t2 = "<wddxPacket version='1.0'><header/><data>" .
      "<number>-3.14159</number></data></wddxPacket>";
    
    compare( $t1, $t2 );
}


# Boolean
{
    my $t1 = $w->serialize(
        $w->boolean( "" )
    );
    
    my $t2 = "<wddxPacket version='1.0'><header/><data>" .
      "<boolean value='false'/></data></wddxPacket>";
    
    compare( $t1, $t2 );
}


# Null
{
    my $t1 = $w->serialize(
        $w->null()
    );
    
    my $t2 = "<wddxPacket version='1.0'><header/><data>" .
      "<null/></data></wddxPacket>";
    
    compare( $t1, $t2 );
}


# Datetime
{
    my $d = $w->datetime( timelocal( 12, 34, 5, 6, 7, 89 ) );
    $d->use_timezone_info( 0 );
    my $t1 = $w->serialize(
        $d
    );
    
    my $t2 = "<wddxPacket version='1.0'><header/><data>" .
      "<dateTime>1989-08-06T05:34:12</dateTime></data></wddxPacket>";
    
    compare( $t1, $t2 );
}


# Binary
{
    my $t1 = $w->serialize(
        $w->binary( "Pretend this is binary..." )
    );
    
    my $t2 = "<wddxPacket version='1.0'><header/><data>" .
      "<binary length='25'>UHJldGVuZCB0aGlzIGlzIGJpbmFyeS4uLg==\n</binary>" .
      "</data></wddxPacket>";
    
    compare( $t1, $t2 );
}


# Array
{
    my @n = map $w->number( $_ ), ( 1 .. 4 );
    my @s = map $w->string( $_ ), qw( aaa bbb ccc ddd );
    my $b = $w->boolean( 1 );
    my $n = $w->null;
    my @a = ( $w->array( \@n ), @s, $b, $n );
    
    my $t1 = $w->serialize(
        $w->array( \@a )
    );
    
    my $t2 = "<wddxPacket version='1.0'><header/><data>" .
      "<array length='7'><array length='4'><number>1</number><number>2" .
      "</number><number>3</number><number>4</number></array><string>aaa" .
      "</string><string>bbb</string><string>ccc</string><string>ddd" .
      "</string><boolean value='true'/><null/></array>" .
      "</data></wddxPacket>";
    
    compare( $t1, $t2 );
}


# Struct
{
    my @n = map $w->number( $_ ), ( 1 .. 4 );
    my $a = $w->array( \@n );
    my %h = ( arr => $a );
    my $t1 = $w->serialize(
        $w->hash( \%h )
    );
    
    my $t2 = "<wddxPacket version='1.0'><header/><data>" .
      "<struct><var name='arr'><array length='4'><number>1</number>" .
      "<number>2</number><number>3</number><number>4</number></array>" .
      "</var></struct>" .
      "</data></wddxPacket>";
    
    compare( $t1, $t2 );
}


# Recordset
{
    my $names = [ "NAME", "AGE" ];
    my $types = [ "string", "number" ];
    my $data  = [ [ "Fred",  34 ],
                  [ "Mary",  23 ],
                  [ "Maude", 45 ],
                  [ "Bud",   26 ] ];
    my $t1 = $w->serialize(
        $w->recordset( $names, $types, $data )
    );
    
    my $t2 = "<wddxPacket version='1.0'><header/><data>" .
      "<recordset rowCount='4' fieldNames='NAME,AGE'><field name='NAME'>" .
      "<string>Fred</string><string>Mary</string><string>Maude</string>" .
      "<string>Bud</string></field><field name='AGE'><number>34</number>" .
      "<number>23</number><number>45</number><number>26</number></field>" .
      "</recordset>" .
      "</data></wddxPacket>";
    
    compare( $t1, $t2 );
}

