use strict;
use warnings;

use Test::More tests => 56;

BEGIN{ use_ok( "XML::Stream","Tree", "Node" ); }

my @packets;
$packets[0] = "<blah test='2'><bingo/></blah>";
$packets[1] = "<foo test='3'>
        <bar/>
    <bingo/></foo>";
$packets[2] = "<last test='5'>
        <test1>
            <test2>
                <test3>This is a test.</test3>
            </test2>
        </test1>
    <bingo/></last>";
$packets[3] = "<a>
        <b>
            <c>
                <d>
                    <e>
                        <e>foo1</e>
                    </e>
                </d>
                <q>
                    <d>
                        <e>foo2</e>
                    </d>
                </q>
            </c>
        </b>
    <bingo/></a>";
$packets[4] = "<e>bar<bingo/></e>";
$packets[5] = "<library>
        <pamphlet>
            <section><para>pA</para></section>
        </pamphlet>
        <book>
            <chapter>
                <section><para>p1</para><para>p2</para></section>
            </chapter>
            <chapter>
                <section><para test='b'>p7</para><para>p8</para></section>
            </chapter>      
            <chapter>
                <section><para>p13</para><para test='a'>p14</para></section>
            </chapter>
            <appendix>
                <section><para>p19</para><para>p20</para></section>
            </appendix>
        </book>
    <bingo/></library>";
$packets[6] = "<filter id='a' mytest='2'>valueA<bingo/></filter>";
$packets[7] = "<filter id='b' mytest='1'>valueB<bingo/></filter>";
$packets[8] = "<filter>valueC<bingo/></filter>";
$packets[9] = "<newfilter bar='1'><sub>foo1</sub><bingo/></newfilter>";
$packets[10] = "<newfilter bar='2'><add>foo2</add><bingo/></newfilter>";
$packets[11] = "<newfilter bar='3'><div>foo3</div><bingo/></newfilter>";
$packets[12] = "<newfilter foo='1'><sub>foo4</sub><bingo/></newfilter>";
$packets[13] = "<newfilter foo='2'><add>foo5</add><bingo/></newfilter>";
$packets[14] = "<newfilter foo='3'><div>foo6</div><bingo/></newfilter>";
$packets[15] = "<startest>
        <foo test='1'/>
        <bar/>
        <bing test='2'/>
    <bingo/></startest>";
$packets[16] = "<cdata_test test='6'>This is cdata with &lt;tags/&gt; embedded &lt;in&gt;it&lt;/in&gt;.<bingo/></cdata_test>";

my $packetIndex;
foreach my $xmlType ("tree","node")
{
    my $stream = XML::Stream->new(style => $xmlType);
    ok( defined($stream), "new() - $xmlType" );
    isa_ok( $stream, "XML::Stream" );

    $packetIndex = 0;
    $stream->SetCallBacks(node => sub{ onPacket($xmlType, @_) });

    my $sid = $stream->OpenFile("t/test.xml");
    while( my %status = $stream->Process())
    {
        last if ($status{$sid} == -1);
    }
}

sub onPacket
{
    my $xmlType     = shift;
    my $sid         = shift;

    if ($xmlType eq "tree")
    {
        my $tree = shift;

        my $test = XML::Stream::BuildXML($tree, "<bingo/>");
        $test =~ s/\r//g;
        is( $test, $packets[$packetIndex], "packet[$packetIndex]" );
    }
    if ($xmlType eq "node")
    {
        my $node = shift;

        my $test = XML::Stream::BuildXML($node, "<bingo/>");
        $test =~ s/\r//g;
        is( $test, $packets[$packetIndex], "packet[$packetIndex]" );

        $node->add_raw_xml("<bingo/>");
        
        $test = XML::Stream::BuildXML($node);
        $test =~ s/\r//g;
        is( $test, $packets[$packetIndex], "packet[$packetIndex]" );
    }
    $packetIndex++;
}

