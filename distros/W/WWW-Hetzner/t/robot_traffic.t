use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Test::WWW::Hetzner::Mock;

my $fixture_query       = load_fixture('traffic_query');
my $fixture_query_multi = load_fixture('traffic_query_multi');
my $fixture_query_single = load_fixture('traffic_query_single');

my $robot = mock_robot(
    'POST /traffic' => sub {
        my ($method, $path, %opts) = @_;
        my $body = $opts{body} // {};

        # Return different fixtures based on params
        if ($body->{'ip[]'} && ref $body->{'ip[]'} eq 'ARRAY' && @{$body->{'ip[]'}} > 1) {
            return $fixture_query_multi;
        }
        if ($body->{single_values} && $body->{single_values} eq 'true') {
            return $fixture_query_single;
        }
        return $fixture_query;
    },
);

subtest 'query traffic basic' => sub {
    my $traffic = $robot->traffic->query(
        type => 'day',
        from => '2024-01-01T00',
        to   => '2024-01-02T00',
        ip   => '1.2.3.4',
    );

    is($traffic->{type}, 'day', 'type');
    is($traffic->{from}, '2024-01-01T00', 'from');
    is($traffic->{to}, '2024-01-02T00', 'to');
    ok(exists $traffic->{data}{'1.2.3.4'}, 'has IP data');

    my $ip_data = $traffic->{data}{'1.2.3.4'};
    is($ip_data->{in}, 10.5, 'inbound traffic');
    is($ip_data->{out}, 25.3, 'outbound traffic');
    is($ip_data->{sum}, 35.8, 'total traffic');
};

subtest 'query traffic multiple IPs' => sub {
    my $traffic = $robot->traffic->query(
        type => 'month',
        from => '2024-01-01',
        to   => '2024-02-01',
        ip   => ['1.2.3.4', '5.6.7.8'],
    );

    is($traffic->{type}, 'month', 'type');
    ok(exists $traffic->{data}{'1.2.3.4'}, 'has first IP');
    ok(exists $traffic->{data}{'5.6.7.8'}, 'has second IP');

    is($traffic->{data}{'1.2.3.4'}{sum}, 471.0, 'first IP total');
    is($traffic->{data}{'5.6.7.8'}{sum}, 134.8, 'second IP total');
};

subtest 'query traffic with single_values' => sub {
    my $traffic = $robot->traffic->query(
        type          => 'day',
        from          => '2024-01-01T00',
        to            => '2024-01-01T23',
        ip            => '1.2.3.4',
        single_values => 1,
    );

    is($traffic->{type}, 'day', 'type');
    my $ip_data = $traffic->{data}{'1.2.3.4'};
    ok(exists $ip_data->{'2024-01-01T00'}, 'has hourly data');
    is($ip_data->{'2024-01-01T00'}{sum}, 1.7, 'hourly sum');
};

subtest 'query validation' => sub {
    eval { $robot->traffic->query() };
    like($@, qr/type.*required/i, 'requires type');

    eval { $robot->traffic->query(type => 'day') };
    like($@, qr/from.*required/i, 'requires from');

    eval { $robot->traffic->query(type => 'day', from => '2024-01-01T00') };
    like($@, qr/to.*required/i, 'requires to');

    eval { $robot->traffic->query(type => 'day', from => '2024-01-01T00', to => '2024-01-02T00') };
    like($@, qr/ip.*subnet.*required/i, 'requires ip or subnet');

    eval { $robot->traffic->query(type => 'invalid', from => 'x', to => 'y', ip => '1.2.3.4') };
    like($@, qr/invalid.*type/i, 'validates type');
};

done_testing;
