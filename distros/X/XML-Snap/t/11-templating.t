#!perl -T

use Test::More tests => 5;

use XML::Snap;
use Data::Dumper;

$xml = XML::Snap->new('gen');
sub testgen {
    my $xml = shift;
    my $count = $xml->oob('count');
    $count = 4 if not defined $count;
    return sub {
        return undef if $count <= 0;
        my $retval = XML::Snap->new('counter');
        $retval->set('count', $count--);
        ($retval);
    }
}
$xml->add (\&testgen);

is ($xml->string, '<gen><counter count="4"/><counter count="3"/><counter count="2"/><counter count="1"/></gen>');
$xml->oob('count', 2);
is ($xml->string, '<gen><counter count="2"/><counter count="1"/></gen>');
$xml->unoob;
is ($xml->string, '<gen><counter count="4"/><counter count="3"/><counter count="2"/><counter count="1"/></gen>');
is ($xml->rawstring, '<gen><counter count="4"/><counter count="3"/><counter count="2"/><counter count="1"/></gen>');


$xml->write('test.xml');
$xml_back = XML::Snap->load('test.xml');
is ($xml_back->string, '<gen><counter count="4"/><counter count="3"/><counter count="2"/><counter count="1"/></gen>');
unlink ('test.xml');
