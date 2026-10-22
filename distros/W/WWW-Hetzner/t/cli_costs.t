use strict;
use warnings;
use Test::More;
use lib 't/lib';

use JSON::MaybeXS qw(decode_json);
use Test::WWW::Hetzner::Mock;
use WWW::Hetzner::CLI::Cmd::Costs;

{
    package Test::CLICostsMain;
    sub new    { my ($class, %args) = @_; return bless { %args }, $class }
    sub cloud  { $_[0]->{cloud} }
    sub output { $_[0]->{output} }
}

sub capture_stdout {
    my ($code) = @_;
    my $buf = '';
    open(my $capture, '>', \$buf) or die "can't open scalar filehandle: $!";
    my $old_fh = select($capture);
    my $ok = eval { $code->(); 1 };
    my $err = $@;
    select($old_fh);
    close($capture);
    die $err unless $ok;
    return $buf;
}

my %LIST = (
    servers        => 'costs_servers',
    volumes        => 'costs_volumes',
    primary_ips    => 'costs_primary_ips',
    floating_ips   => 'costs_floating_ips',
    load_balancers => 'costs_load_balancers',
);

sub run_costs {
    my (%args) = @_;
    my $seen = $args{seen} // {};
    my @routes = ('GET /pricing' => load_fixture('costs_pricing'));
    for my $res (keys %LIST) {
        push @routes, "GET /$res" => sub {
            my ($method, $path, %opts) = @_;
            $seen->{$res} = $opts{params} // {};
            return load_fixture($LIST{$res});
        };
    }
    my $main = Test::CLICostsMain->new(
        cloud  => mock_cloud(@routes),
        output => $args{output} // 'table',
    );
    local @ARGV = @{ $args{argv} // [] };
    my $cmd = WWW::Hetzner::CLI::Cmd::Costs->new_with_options;
    return capture_stdout(sub { $cmd->execute([], [$main]) });
}

subtest 'text table' => sub {
    my $out = run_costs(argv => ['--net']);

    like($out, qr/^Prices: net, EUR \(VAT 19%\)/m, 'header says net');
    like($out, qr/NAME\s+KIND\s+TYPE\s+LOCATION\s+STATUS\s+EUR\/h\s+EUR\/month/,
        'column header');
    like($out, qr/^web-1\s+server\s+cx23\s+fsn1\s+running\s+0\.0088\s+5\.49$/m,
        'server row');
    like($out, qr/^web-1\s+server_backup\s+cx23\s+fsn1\s+running\s+0\.0018\s+1\.10$/m,
        'backup row');
    like($out, qr/^db-1\s+server\s+cpx32\s+sin\s+off\s+0\.0785\s+48\.99$/m,
        'stopped server row, sin price');
    like($out, qr/^data-1\s+volume\s+10 GB\s+fsn1\s+available\s+0\.0009\*\s+0\.57$/m,
        'volume row, derived hourly marked');
    like($out, qr/^vip\s+floating_ip\s+ipv4\s+fsn1\s+assigned\s+0\.0048\*\s+3\.00$/m,
        'floating ip row');
    like($out, qr/^lb-1\s+load_balancer\s+lb11\s+fsn1\s+-\s+0\.0112\s+6\.99$/m,
        'load balancer row');
    like($out, qr/^TOTAL\s+0\.1647\s+102\.73$/m, 'total line');
    like($out, qr/^\* hourly derived as monthly \/ 624h/m, 'derived footnote');
};

subtest 'gross by default' => sub {
    my $out = run_costs();
    like($out, qr/^Prices: gross, EUR/m, 'header says gross');
    like($out, qr/^web-1\s+server\s+cx23\s+fsn1\s+running\s+0\.0105\s+6\.53$/m,
        'gross server row');
};

subtest '--label filters every list' => sub {
    my %seen;
    my $out = run_costs(argv => ['--label', 'citiai-env=live'], seen => \%seen);
    is($seen{$_}{label_selector}, 'citiai-env=live', "$_ filtered") for sort keys %LIST;
    like($out, qr/label selector: citiai-env=live/, 'selector shown in header');
};

subtest '--json' => sub {
    my $out = run_costs(argv => ['--json', '--net']);
    my $data = eval { decode_json($out) };
    ok($data, 'valid JSON') or return diag($out);
    is($data->{price}, 'net', 'price flag');
    is($data->{currency}, 'EUR', 'currency');
    is(scalar @{ $data->{resources} }, 10, 'all rows');
    is(sprintf('%.2f', $data->{totals}{monthly}), '102.73', 'monthly total');
    is(sprintf('%.6f', $data->{totals}{hourly}), '0.164685', 'hourly total');
};

subtest 'global -o json' => sub {
    my $out = run_costs(output => 'json');
    my $data = eval { decode_json($out) };
    ok($data, 'valid JSON') or return diag($out);
    is($data->{price}, 'gross', 'gross by default');
};

done_testing;
