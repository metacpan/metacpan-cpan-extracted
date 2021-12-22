use strict;
use warnings;

use Test::More 'no_plan';

use URL::XS;


my $expected_url_fields = [sort qw/scheme host port path query fragment username password/];

subtest 'parse minimal url' => sub {
    ok my $r = URL::XS::parse_url('http://example.com');
    base_parsed_url_tests($r, [qw/username password port path query fragment/]);
    is $r->{scheme}, 'http', 'right url scheme';
    is $r->{host}, 'example.com', 'right url host';
};

subtest 'parse url with empty path (/)' => sub {
    ok my $r = URL::XS::parse_url('http://example.com/');
    base_parsed_url_tests($r, [qw/username password port path query fragment/]);
    is $r->{scheme}, 'http', 'right url scheme';
    is $r->{host}, 'example.com', 'right url host';
};

subtest 'parse url with path' => sub {
    ok my $r = URL::XS::parse_url('http://example.com/some-path');
    base_parsed_url_tests($r, [qw/username password port query fragment/]);
    is $r->{scheme}, 'http', 'right url scheme';
    is $r->{host}, 'example.com', 'right url host';
    is $r->{path}, 'some-path', 'right url path';
};

subtest 'parse url with port' => sub {
    ok my $r = URL::XS::parse_url('http://example.com:80');
    base_parsed_url_tests($r, [qw/username password path query fragment/]);
    is $r->{scheme}, 'http', 'right url scheme';
    is $r->{host}, 'example.com', 'right url host';
    cmp_ok $r->{port}, '==', 80, 'right http port';
};

subtest 'parse url with query' => sub {
    ok my $r = URL::XS::parse_url('http://example.com?query=only');
    base_parsed_url_tests($r, [qw/username password port path fragment/]);
    is $r->{scheme}, 'http', 'right url scheme';
    is $r->{host}, 'example.com', 'right url host';
    is $r->{query}, 'query=only', 'right url query';
};

subtest 'parse url with fragment' => sub {
    ok my $r = URL::XS::parse_url('http://example.com#frag=f1');
    base_parsed_url_tests($r, [qw/username password port path query/]);
    is $r->{scheme}, 'http', 'right url scheme';
    is $r->{host}, 'example.com', 'right url host';
    is $r->{fragment}, 'frag=f1', 'right url fragment';
};

subtest 'parse url with credentials' => sub {
    ok my $r = URL::XS::parse_url('http://u:p@example.com');
    base_parsed_url_tests($r, [qw/port path query fragment/]);
    is $r->{scheme}, 'http', 'right url scheme';
    is $r->{host}, 'example.com', 'right url host';
    is $r->{username}, 'u', 'right username';
    is $r->{password}, 'p', 'right password';
};

subtest 'parse url with port and path' => sub {
    ok my $r = URL::XS::parse_url('http://example.com:8080/port/and/path');
    base_parsed_url_tests($r, [qw/username password query fragment/]);
    is $r->{scheme}, 'http', 'right url scheme';
    is $r->{host}, 'example.com', 'right url host';
    cmp_ok $r->{port}, '==', 8080, 'right url port';
    is $r->{path}, 'port/and/path', 'right url path';
};

subtest 'parse url with port and query' => sub {
    ok my $r = URL::XS::parse_url('http://example.com:8080?query=portANDquery');
    base_parsed_url_tests($r, [qw/username password path fragment/]);
    is $r->{scheme}, 'http', 'right url scheme';
    is $r->{host}, 'example.com', 'right url host';
    cmp_ok $r->{port}, '==', 8080, 'right url port';
    is $r->{query}, 'query=portANDquery', 'right url query';
};

subtest 'parse url with port and fragment' => sub {
    ok my $r = URL::XS::parse_url('http://example.com:8080#f1');
    base_parsed_url_tests($r, [qw/username password path query/]);
    is $r->{scheme}, 'http', 'right url scheme';
    is $r->{host}, 'example.com', 'right url host';
    cmp_ok $r->{port}, '==', 8080, 'port is expected';
    is $r->{fragment}, 'f1', 'right url fragment';
};

subtest 'parse url with port and credentials' => sub {
    ok my $r = URL::XS::parse_url('http://u:p@example.com:8080');
    base_parsed_url_tests($r, [qw/path query fragment/]);
    is $r->{scheme}, 'http', 'right url scheme';
    is $r->{host}, 'example.com', 'right url host';
    is $r->{username}, 'u', 'right username';
    is $r->{password}, 'p', 'right password';
    cmp_ok $r->{port}, '==', 8080, 'right port';
};

subtest 'parse url with path and query' => sub {
    ok my $r = URL::XS::parse_url('http://example.com/path/and/query?q=yes');
    base_parsed_url_tests($r, [qw/username password port fragment/]);
    is $r->{scheme}, 'http', 'right url scheme';
    is $r->{host}, 'example.com', 'right url host';
    is $r->{path}, 'path/and/query', 'right url path';
    is $r->{query}, 'q=yes', 'right url query';
};

subtest 'parse url with path and fragment' => sub {
    ok my $r = URL::XS::parse_url('http://example.com/path/and#fragment');
    base_parsed_url_tests($r, [qw/username password port query/]);
    is $r->{scheme}, 'http', 'right url scheme';
    is $r->{host}, 'example.com', 'right url host';
    is $r->{path}, 'path/and', 'right url path';
    is $r->{fragment}, 'fragment', 'right url fragment';
};

subtest 'parse url with query and fragment' => sub {
    ok my $r = URL::XS::parse_url('http://example.com?q=yes#f1');
    base_parsed_url_tests($r, [qw/username password port path/]);
    is $r->{scheme}, 'http', 'right url scheme';
    is $r->{host}, 'example.com', 'right url host';
    is $r->{query}, 'q=yes', 'right url query';
    is $r->{fragment}, 'f1', 'right url fragment';
};

subtest 'parse url with query and credentials' => sub {
    ok my $r = URL::XS::parse_url('http://u:p@example.com?q=yes');
    base_parsed_url_tests($r, [qw/path port fragment/]);
    is $r->{scheme}, 'http', 'right url scheme';
    is $r->{host}, 'example.com', 'right url host';
    is $r->{username}, 'u', 'right username';
    is $r->{password}, 'p', 'right password';
    is $r->{query}, 'q=yes', 'right url query';
};

subtest 'parse url with empty credentials' => sub {
    ok my $r = URL::XS::parse_url('http://:@example.com');
    base_parsed_url_tests($r, [qw/username password port path query fragment/]);
    is $r->{scheme}, 'http', 'right url scheme';
    is $r->{host}, 'example.com', 'right url host';
};

subtest 'parse url with port and empty credentials' => sub {
    ok my $r = URL::XS::parse_url('http://:@example.com:89');
    base_parsed_url_tests($r, [qw/username password path query fragment/]);
    is $r->{scheme}, 'http', 'right url scheme';
    is $r->{host}, 'example.com', 'right url host';
    cmp_ok $r->{port}, '==', 89, 'right port';
};

subtest 'parse complex url' => sub {
    ok my $r = URL::XS::parse_url(
        'https://jack:password@localhost:8989/path/to/test?query=yes&q=jack#fragment1'
    );
    is $r->{scheme}, 'https', 'right url scheme';
    is $r->{username}, 'jack', 'right username';
    is $r->{password}, 'password', 'right password';
    is $r->{host}, 'localhost', 'right url host';
    cmp_ok $r->{port}, '==', 8989, 'right port';
    is $r->{path}, 'path/to/test', 'right url path';
    is $r->{query}, 'query=yes&q=jack', 'right url query';
    is $r->{fragment}, 'fragment1', 'right url fragment';
};

sub base_parsed_url_tests {
    my ($parsed_url_result, $expected_undefined) = @_;

    is_deeply [sort keys %$parsed_url_result], $expected_url_fields, 'right url fields';
    ok !$parsed_url_result->{$_}, "$_ is undef" for @$expected_undefined;
}

done_testing;
