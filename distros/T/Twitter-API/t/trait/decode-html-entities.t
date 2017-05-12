#!perl
use 5.14.1;
use warnings;
use Test::Spec;

package Client {
    use Moo;
    with 'Twitter::API::Trait::DecodeHtmlEntities';
    sub inflate_response {}
}

my $client = Client->new;

describe _decode_html_entities => sub {
    it 'decodes html entities' => sub {
        my $data = {
            string => 'With &amp; and &lt;',
            number => 1234,
            array => [
                'With &amp; and &lt;',
                1234,
                array => [
                    'With &amp; and &lt;',
                    1234,
                ],
                hash => {
                    string => 'With &amp; and &lt;',
                    number => 1234,
                },
            ],
            hash => {
                string => 'With &amp; and &lt;',
                number => 1234,
                array => [
                    'With &amp; and &lt;',
                    1234,
                    hash => {
                        string => 'With &amp; and &lt;',
                        number => 1234,
                    },
                ],
            },
        };
        $client->_decode_html_entities($data);
        is_deeply $data, {
            string => 'With & and <',
            number => 1234,
            array => [
                'With & and <',
                1234,
                array => [
                    'With & and <',
                    1234,
                ],
                hash => {
                    string => 'With & and <',
                    number => 1234,
                },
            ],
            hash => {
                string => 'With & and <',
                number => 1234,
                array => [
                    'With & and <',
                    1234,
                    hash => {
                        string => 'With & and <',
                        number => 1234,
                    },
                ],
            },
        };
    };
};

runtests;
