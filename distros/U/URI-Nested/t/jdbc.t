#!/usr/bin/perl -w

use strict;
use Test::More;
use utf8;
use URI;

JDBC: {
    package URI::jdbc;
    use base 'URI::Nested';
}

is +URI::jdbc->prefix, 'jdbc', 'Prefix should be "jdbc"';

isa_ok my $uri = URI->new('jdbc:'), 'URI::jdbc', 'Empty JDBC URI';
is $uri->scheme, 'jdbc', 'Empty JDBC URI should have scheme "jdbc"';
isa_ok $uri->nested_uri, 'URI::_generic', 'Nested URI';
ok $uri->nested_uri->eq(URI->new('')), 'Nested URI should be empty';
ok $uri->eq('jdbc:'), 'URI should eq "jdbc:"';
is $uri->as_string, 'jdbc:', 'String should be "jdbc:"';

# Try a more interesting URI.
my $str = 'jdbc:oracle:scott/tiger@//myhost:1521/myservicename';
isa_ok $uri = URI->new($str), 'URI::jdbc', 'Oracle JDBC URI';
is $uri->scheme, 'jdbc', 'Oracle JDBC URI should have scheme "jdbc"';
ok $uri->eq($str), 'Oracle JDBC URI should eq string';
is $uri->as_string, $str, 'Oracle JDBC String should be correct';

# Check the nested URI.
$str =~ s/^jdbc://;
isa_ok $uri = $uri->nested_uri, 'URI::_generic', 'Nested Oracle URI';
ok $uri->eq($str), 'Oracle URI should eq string';
is $uri->as_string, $str, 'Oracle String should be correct';

# Try a Postgres URL.
$str = 'jdbc:postgresql://localhost/test?user=fred&password=secret&ssl=true';
isa_ok $uri = URI->new($str), 'URI::jdbc', 'Postgres JDBC URI';
is $uri->scheme, 'jdbc', 'Postgres JDBC URI should have scheme "jdbc"';
ok $uri->eq($str), 'Postgres JDBC URI should eq string';
is $uri->as_string, $str, 'Postgres JDBC String should be correct';

# Check the nested URI.
$str =~ s/^jdbc://;
isa_ok $uri = $uri->nested_uri, 'URI::_generic', 'Nested Postgres URI';
ok $uri->eq($str), 'Postgres URI should eq string';
is $uri->as_string, $str, 'Postgres String should be correct';

done_testing;
