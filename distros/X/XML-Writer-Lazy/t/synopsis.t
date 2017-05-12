#!perl

use strict;
use warnings;

use Test::More;
use XML::Writer::Lazy;

my $writer = XML::Writer::Lazy->new( OUTPUT => 'self');
my $title  = "My Title!";

$writer->lazily(<<"XML");
    <html>
        <head>
            <title>$title</title>
    </head>
    <body>
        <p>Pipe in literal XML</p>
XML

$writer->startTag( "p", "class" => "simple" );
$writer->characters("Alongside the usual interface");
$writer->characters("123456789");
$writer->lazily("</p></body></html>");


is( $writer->to_string() . "\n", <<'XML', "Synopsis output as expected" );
<html>
        <head>
            <title>My Title!</title>
    </head>
    <body>
        <p>Pipe in literal XML</p><p class="simple">Alongside the usual interface123456789</p></body></html>
XML

done_testing();