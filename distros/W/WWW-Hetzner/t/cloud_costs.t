#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Test::WWW::Hetzner::Mock;
use WWW::Hetzner::Cloud::Costs;

my %LIST = (
    servers        => 'costs_servers',
    volumes        => 'costs_volumes',
    primary_ips    => 'costs_primary_ips',
    floating_ips   => 'costs_floating_ips',
    load_balancers => 'costs_load_balancers',
);

# Routes for /pricing and the five resource lists. %seen records the query
# parameters each request arrived with.
sub costs_routes {
    my (%args) = @_;
    my $seen = $args{seen} // {};
    my %override = %{ $args{override} // {} };

    my @routes = ('GET /pricing' => sub {
        my ($method, $path, %opts) = @_;
        $seen->{pricing} = $opts{params} // {};
        return $override{pricing} // load_fixture('costs_pricing');
    });
    for my $res (sort keys %LIST) {
        push @routes, "GET /$res" => sub {
            my ($method, $path, %opts) = @_;
            $seen->{$res} = $opts{params} // {};
            return $override{$res} // load_fixture($LIST{$res});
        };
    }
    return @routes;
}

sub num { sprintf '%.6f', $_[0] }

sub rows_by {
    my ($costs) = @_;
    return { map { ("$_->{kind}:$_->{name}" => $_) } @{ $costs->{resources} } };
}

subtest 'net prices for every resource kind, per location' => sub {
    my $cloud = mock_cloud(costs_routes());
    my $costs = $cloud->costs(price => 'net');

    is($costs->{price}, 'net', 'result says net');
    is($costs->{currency}, 'EUR', 'currency');
    is($costs->{vat_rate}, '19.00', 'vat rate');
    is($costs->{hours_per_month}, 624, 'hourly divisor exposed');

    my $r = rows_by($costs);
    is(scalar @{ $costs->{resources} }, 10, 'ten rows');

    my %expect = (
        'server:web-1'        => [ 'cx23',  'fsn1', 'running',    0.0088,   5.49,  0 ],
        'server_backup:web-1' => [ 'cx23',  'fsn1', 'running',    0.00176,  1.098, 0 ],
        'server:db-1'         => [ 'cpx32', 'sin',  'off',        0.0785,  48.99,  0 ],
        'server:old-1'        => [ 'cpx32', 'fsn1', 'running',    0.0569,  35.49,  0 ],
        'volume:data-1'       => [ '10 GB', 'fsn1', 'available',  0.572 / 624, 0.572, 1 ],
        'primary_ip:web-1-v4' => [ 'ipv4',  'fsn1', 'assigned',   0.0008,   0.50,  0 ],
        'primary_ip:web-1-v6' => [ 'ipv6',  'fsn1', 'assigned',   0,        0,     0 ],
        'primary_ip:spare-sin'=> [ 'ipv4',  'sin',  'unassigned', 0.0010,   0.60,  0 ],
        'floating_ip:vip'     => [ 'ipv4',  'fsn1', 'assigned',   3 / 624,  3.00,  1 ],
        'load_balancer:lb-1'  => [ 'lb11',  'fsn1', undef,        0.0112,   6.99,  0 ],
    );

    for my $key (sort keys %expect) {
        my ($type, $loc, $status, $h, $m, $derived) = @{ $expect{$key} };
        my $row = $r->{$key};
        ok($row, "$key present") or next;
        is($row->{type}, $type, "$key type");
        is($row->{location}, $loc, "$key location");
        is($row->{status}, $status, "$key status");
        is(num($row->{hourly}), num($h), "$key hourly");
        is(num($row->{monthly}), num($m), "$key monthly");
        is($row->{hourly_derived}, $derived, "$key hourly_derived");
    }

    is($r->{'volume:data-1'}{size}, 10, 'volume size carried');
    is($r->{'server:web-1'}{id}, 101, 'id carried');

    # Same type, two locations, two prices.
    isnt(num($r->{'server:db-1'}{monthly}), num($r->{'server:old-1'}{monthly}),
        'cpx32 priced differently in sin and fsn1');

    is(num($costs->{totals}{monthly}), num(102.73), 'monthly total');
    is(num($costs->{totals}{hourly}), num(0.164685), 'hourly total');
    is_deeply($costs->{warnings}, [], 'no warnings');
};

subtest 'entities read location from current and legacy shapes' => sub {
    my $cloud = mock_cloud(costs_routes());

    my %srv = map { ($_->name => $_) } @{ $cloud->servers->list_all };
    is($srv{'web-1'}->location, 'fsn1', 'server location object');
    is($srv{'old-1'}->location, 'fsn1', 'server datacenter.location fallback');
    is($srv{'web-1'}->backup_window, '22-02', 'server backup_window');
    ok(!defined $srv{'db-1'}->backup_window, 'no backup_window when disabled');
    is($srv{'web-1'}->data->{location}{name}, 'fsn1', 'server data keeps location');

    my ($pip) = @{ $cloud->primary_ips->list_all };
    is($pip->location, 'fsn1', 'primary ip location object');
    is($pip->data->{location}{name}, 'fsn1', 'primary ip data keeps location');

    my $legacy = load_fixture('primary_ips_list')->{primary_ips}[0];
    $legacy->{datacenter}{location} = { name => 'nbg1' };
    require WWW::Hetzner::Cloud::PrimaryIP;
    my $old = WWW::Hetzner::Cloud::PrimaryIP->new(client => $cloud, %$legacy);
    is($old->location, 'nbg1', 'primary ip datacenter.location fallback');
};

subtest 'gross is the default' => sub {
    my $cloud = mock_cloud(costs_routes());
    my $costs = $cloud->costs;

    is($costs->{price}, 'gross', 'result says gross');
    my $r = rows_by($costs);
    is(num($r->{'server:web-1'}{monthly}), num(6.5331), 'cx23 gross monthly');
    is(num($r->{'server:web-1'}{hourly}), num(0.0105), 'cx23 gross hourly');
    is(num($r->{'volume:data-1'}{monthly}), num(0.681), 'volume gross monthly');
    is(num($r->{'floating_ip:vip'}{monthly}), num(3.57), 'floating ip gross monthly');
};

subtest 'invalid price option dies' => sub {
    my $cloud = mock_cloud(costs_routes());
    eval { $cloud->costs(price => 'brutto') };
    like($@, qr/price must be 'net' or 'gross'/, 'rejected');
};

subtest 'label_selector reaches every list request' => sub {
    my %seen;
    my $cloud = mock_cloud(costs_routes(seen => \%seen));
    my $costs = $cloud->costs(label_selector => 'citiai-env=live');

    for my $res (sort keys %LIST) {
        is($seen{$res}{label_selector}, 'citiai-env=live', "$res filtered");
    }
    ok(!exists $seen{pricing}{label_selector}, 'pricing not filtered');
    is($costs->{label_selector}, 'citiai-env=live', 'selector echoed in result');
};

subtest 'no label_selector without the option' => sub {
    my %seen;
    my $cloud = mock_cloud(costs_routes(seen => \%seen));
    my $costs = $cloud->costs;

    for my $res (sort keys %LIST) {
        ok(!exists $seen{$res}{label_selector}, "$res unfiltered");
    }
    ok(!defined $costs->{label_selector}, 'no selector in result');
};

subtest 'missing price: warning, excluded from total' => sub {
    my $servers = load_fixture('costs_servers');
    $servers->{servers} = [{
        id => 109, name => 'exotic', status => 'running',
        server_type => { name => 'cx99' },
        location    => { name => 'fsn1' },
    }];
    my $empty = sub { my $k = shift; return { $k => [] } };

    my $cloud = mock_cloud(costs_routes(override => {
        servers        => $servers,
        volumes        => $empty->('volumes'),
        primary_ips    => $empty->('primary_ips'),
        floating_ips   => $empty->('floating_ips'),
        load_balancers => $empty->('load_balancers'),
    }));
    my $costs = $cloud->costs(price => 'net');

    is(scalar @{ $costs->{resources} }, 1, 'row still listed');
    ok(!defined $costs->{resources}[0]{monthly}, 'no monthly price');
    ok(!defined $costs->{resources}[0]{hourly}, 'no hourly price');
    is($costs->{totals}{monthly}, 0, 'excluded from monthly total');
    is(scalar @{ $costs->{warnings} }, 1, 'one warning');
    like($costs->{warnings}[0], qr/exotic.*cx99.*fsn1/, 'warning names the resource');
};

subtest 'empty project' => sub {
    my $cloud = mock_cloud(costs_routes(override => {
        map { ($_ => { $_ => [] }) } keys %LIST
    }));
    my $costs = $cloud->costs;
    is_deeply($costs->{resources}, [], 'no rows');
    is($costs->{totals}{hourly}, 0, 'hourly total 0');
    is($costs->{totals}{monthly}, 0, 'monthly total 0');
};

subtest 'only GET requests are sent' => sub {
    my @methods;
    my @routes = costs_routes();
    my @wrapped;
    while (my ($k, $v) = splice @routes, 0, 2) {
        push @wrapped, $k => sub { push @methods, $_[0]; $v->(@_) };
    }
    my $cloud = mock_cloud(@wrapped);
    $cloud->costs;
    is(scalar @methods, 6, 'six requests: pricing + five lists');
    is_deeply([ grep { $_ ne 'GET' } @methods ], [], 'all GET');
};

done_testing;
