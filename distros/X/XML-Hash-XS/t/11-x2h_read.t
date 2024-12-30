package main;
use strict;
use warnings;

use Test::More tests => 6;
use Data::Dumper;
$Data::Dumper::Indent = 0;
$Data::Dumper::Sortkeys = 1;

use XML::Hash::XS 'xml2hash';
$XML::Hash::XS::keep_root = 0;

our $xml_decl_utf8 = qq{<?xml version="1.0" encoding="utf-8"?>};

{
    is
        Dumper(xml2hash('t/test.xml', keep_root => 1)),
        Dumper({
root => {
    attr1 => '1',
    attr2 => '2',
    item  => ['1', '2', '3'],
    node1 => 'value1',
    node2 => {
        attr1   => '1',
        content => 'value2',
    }
}
}),
        'read from file',
    ;
}

{
    use utf8;
    is
        xml2hash('<root>Привет!</root>', buf_size => 2),
        "Привет!",
        'read from string with buf_size=2',
    ;
}

{
    use utf8;
    is
        xml2hash('<?xml version="1.0" encoding="utf-8"?><root>Привет!</root>', buf_size => 2),
        "Привет!",
        'read from string with buf_size=2 and xml decl',
    ;
}

{
    use utf8;
    ## no critic (InputOutput::ProhibitBarewordFileHandles)
    open(DATA, '<:encoding(UTF-8)', 't/test_utf8.xml') or die "Can't open file 't/test_utf8.xml'";
    ## use critic
    is
        xml2hash(*DATA),
        "Привет!",
        'read from file handle',
    ;
    close DATA;
}

{
    tie *DATA, 'MyReader', '<?xml version="1.0" encoding="utf-8"?><root>Привет!</root>';
    use utf8;
    is
        xml2hash(*DATA, buf_size => 2),
        "Привет!",
        'read from tied handle',
    ;
    untie *DATA;
}

{
    eval { xml2hash('t/test_null_terminated.xml') };
    ok(!$@, 'read from the null-terminated file');
}

package MyReader;
use base 'Tie::Handle';

sub TIEHANDLE {
    my ($class, $str) = @_;
    bless {str => $str, pos => 0, len => length($str)}, $class;
}

sub READ {
    my $bufref = \$_[1];
    my ($self, undef, $len, $offset) = @_;

    $offset ||= 0;

    if (($self->{pos} + $len) > $self->{len}) {
        $len = $self->{len} - $self->{pos};
    }
    if ($len > 0) {
        $$bufref = substr($$bufref, 0, $offset) . substr($self->{str}, $self->{pos}, $len);
        $self->{pos} += $len;
    }
    return $len;
}

sub WRITE {}
sub PRINT {}
