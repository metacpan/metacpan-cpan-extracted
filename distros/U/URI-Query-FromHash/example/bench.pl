use strict;
use utf8;
use warnings;

use Benchmark 'cmpthese';
use URI;
use URI::Query::FromHash;

my $args = {
    foo    => 'bar',
    baz    => [ qw/qux quux/ ],
    utf8   => '☃',
    escape => ';/?:@&=+,\$\[\]% ',
};

cmpthese -1, {
    hash2query => sub { hash2query $args },
    uri        => sub {
        my $uri = URI->new;

        $uri->query_form($args);

        $uri->query;
    },
};
