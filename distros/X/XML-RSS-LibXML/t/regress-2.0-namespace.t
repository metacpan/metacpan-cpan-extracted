use strict;
use Test::More tests => 8;
use XML::RSS::LibXML;

for my $ver (qw( 1.0 2.0 )) {
    my $feed = XML::RSS::LibXML->new( version => $ver );
    $feed->channel(title => "Hello world");
    $feed->channel(webMaster => "foobar");
    $feed->channel->{dc}{creator} = "foobar";

    my $string = $feed->as_string;
    like $string, qr/xmlns:dc="[^"]+"/, "namespace declaration for $ver";
    like $string, qr{<dc:creator>foobar</dc:creator>}, "actual element for $ver";

    $string = $feed->parse($feed->as_string)->as_string;
    like $string, qr/xmlns:dc="[^"]+"/, "namespace declaration for $ver";
    like $string, qr{<dc:creator>foobar</dc:creator>}, "actual element for $ver";
}
