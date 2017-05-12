package WWW::Google::Contacts::Data;
{
    $WWW::Google::Contacts::Data::VERSION = '0.39';
}

use strict;
use warnings;

use XML::Simple ();
use Encode;

sub decode_xml {
    my ( $class, $content ) = @_;

    my $xmls = XML::Simple->new;
    my $data = $xmls->XMLin(
        decode_utf8($content),
        SuppressEmpty => undef,
        KeyAttr       => []
    );
    return $data;
}

sub encode_xml {
    my ( $class, $content ) = @_;

    my $xmls = XML::Simple->new;
    my $xml = $xmls->XMLout( $content, KeepRoot => 1 );
    return encode_utf8($xml);
}

1;
