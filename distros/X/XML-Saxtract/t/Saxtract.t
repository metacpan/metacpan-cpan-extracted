use strict;
use warnings;

use File::Temp;
use Test::More tests => 11;
use XML::Saxtract qw(saxtract_string saxtract_url);

is_deeply(
    saxtract_string(
        "<?xml version='1.0' encoding='UTF-8'?><root>value</root>",
        { '/root' => 'rootValue' }
    ),
    { rootValue => 'value' },
    'simple value'
);

is_deeply(
    saxtract_string(
        "<?xml version='1.0' encoding='UTF-8'?><root id='root' />",
        { '/root/@id' => 'rootId' }
    ),
    { rootId => 'root' },
    'simple attribute'
);

is_deeply(
    saxtract_string(
        "<?xml version='1.0' encoding='UTF-8'?><root id='root'>value</root>",
        {   '/root'     => 'rootValue',
            '/root/@id' => 'rootId'
        }
    ),
    {   rootValue => 'value',
        rootId    => 'root'
    },
    'simple value and attribute'
);

is_deeply(
    saxtract_string(
        "<?xml version='1.0' encoding='UTF-8'?><root xmlns='http://abc'>value</root>",
        {   'http://abc' => 'abc',
            '/root'      => 'rootValue',
            '/abc:root'  => 'abcRootValue'
        }
    ),
    { abcRootValue => 'value' },
    'simple namespaced value'
);

is_deeply(
    saxtract_string(
        "<?xml version='1.0' encoding='UTF-8'?><root xmlns='http://abc'>value</root>",
        {   'http://abc' => 'abc',
            '/root'      => 'rootValue',
            '/abc:root'  => sub {
                my ( $object, $value ) = @_;
                $object->{abcRootValue}  = $value;
                $object->{computedValue} = "computed_$value";
            }
        }
    ),
    {   abcRootValue  => 'value',
        computedValue => 'computed_value'
    },
    'subroutine value setter'
);

is_deeply(
    saxtract_string(
        "<?xml version='1.0' encoding='UTF-8'?><root xmlns:n='http://abc' n:id='root' />",
        {   'http://abc'    => 'abc',
            '/root/@id'     => 'rootId',
            '/root/@abc:id' => 'abcRootId'
        }
    ),
    { abcRootId => 'root' },
    'mismatching namespace prefixes'
);

my $complex_xml = <<XML;
<?xml version='1.0' encoding='UTF-8'?>
<root xmlns='http://abc' xmlns:d='http://def' d:id='1' name='root' d:other='abc'>
  <person id='1'>Lucas</person>
  <d:employee id='2'>Ali</d:employee>
  <person id='3'>Boo</person>
  <d:employee id='4'>Dude</d:employee>
</root>
XML
my $complex_spec = {
    'http://def'     => 'k',
    'http://abc'     => '',
    '/root/@k:id'    => 'id',
    '/root/@name'    => 'name',
    '/root/@k:other' => 'other',
    '/root/person'   => {
        name => 'people',
        type => 'map',
        key  => 'name',
        spec => {
            ''     => 'name',
            '/@id' => 'id'
        }
    },
    '/root/k:employee' => {
        name => 'firstEmployee',
        type => 'first',
        spec => {
            ''     => 'name',
            '/@id' => 'id'
        }
    }
};
my $complex_expected = {
    id     => '1',
    name   => 'root',
    other  => 'abc',
    people => {
        Lucas => {
            name => 'Lucas',
            id   => 1
        },
        Boo => {
            name => 'Boo',
            id   => 3
        }
    },
    firstEmployee => {
        name => 'Ali',
        id   => 2
    }
};

is_deeply( saxtract_string( $complex_xml, $complex_spec ),
    $complex_expected, 'complex with namespaces' );

my $temp = File::Temp->new();
open( my $file_handle, '>', $temp );
print( $temp $complex_xml );
close($temp);
is_deeply( saxtract_url( 'file://' . $temp->filename(), $complex_spec ),
    $complex_expected, 'file complex with namespaces' );

SKIP: {
    eval { require("Test/HTTP/Server.pm"); };
    skip( 'Test::HTTP::Server not installed', 1 ) if ($@);

    my $server = Test::HTTP::Server->new();

    sub Test::HTTP::Server::Request::complex {
        my $self = shift;
        return $complex_xml;
    }
    is_deeply( saxtract_url( $server->uri() . 'complex', $complex_spec ),
        $complex_expected, 'url complex with namespaces' );
}

{
    #subspec namespace
    my $xml = <<'    XML';
    <root xmlns='urn:abc' xmlns:foo='urn:bar' xmlns:baz='urn:bop'>
      <person><baz:id>1</baz:id><foo:name>Lucas</foo:name></person>
      <person><baz:id>3</baz:id><foo:name>Boo</foo:name></person>
    </root>
    XML
    my $spec = {
        'urn:abc' => '',
        '/root'   => {
            type => 'first',
            name => 'root',
            spec => {
                'urn:bar' => 'f',
                '/person' => {
                    name => 'people',
                    type => 'array',
                    spec => {
                        'urn:bop' => '',
                        '/f:name' => 'name',
                        '/id'     => 'id'
                    }
                }
            }
        }
    };
    my $expected = {
        root => {
            people => [
                {   name => 'Lucas',
                    id   => 1
                },
                {   name => 'Boo',
                    id   => 3
                }
            ]
        }
    };

    is_deeply( saxtract_string( $xml, $spec ), $expected, 'subspec namespaces' );
}

{
    #subspec type sub
    my $xml = <<'    XML';
    <root>
      <person><id>1</id><name>Lucas</name></person>
      <person><id>3</id><name>Boo</name></person>
    </root>
    XML
    my $spec = {
        '/root/person' => {
            name => 'people',
            type => sub {
                my ( $object, $value ) = @_;
                $object->{"$value->{name}|$value->{id}"} = $value;
            },
            spec => {
                '/name' => 'name',
                '/id'   => 'id'
            }
        }
    };
    my $expected = {
        people => {
            'Lucas|1' => {
                name => 'Lucas',
                id   => 1
            },
            'Boo|3' => {
                name => 'Boo',
                id   => 3
            }
        }
    };

    is_deeply( saxtract_string( $xml, $spec ), $expected, 'subspec type sub' );

}
