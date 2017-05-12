#!/usr/bin/perl
use v5.14;

use WebService::Bonusly;
use JSON;
use Test::More;
use Test::Exception;
use Test::MockObject;
use YAML qw( LoadFile );

my %api = %{ LoadFile('api.yml') };

my $res = Test::MockObject->new;
$res->set_always(content => '{}');

my $ua = Test::MockObject->new;
$ua->set_always(get => $res);
$ua->set_always(delete => $res);
$ua->set_always(post => $res);
$ua->set_always(put => $res);

my $bly = WebService::Bonusly->new(
    token       => 'test',
    base_url    => "test/",
    ua          => $ua,
    _json_flags => { canonical => 1 },
);

plan tests => scalar keys %api;

for my $service_name (sort keys %api) {
    my $service = $bly->$service_name;

    subtest "Service $service" => sub {
        plan tests => 2 + scalar keys %{ $api{ $service_name } };

        isa_ok $service, 'WebService::Bonusly::Service';
        can_ok($service, keys %{ $api{ $service_name } });

        for my $action (sort keys %{ $api{ $service_name } }) {
            my $def = $api{$service_name}{$action};
            my $allow_any = grep { $_ eq '*' } @{ $def->{optional} // [] };

            subtest "Action $action" => sub {
                my @optional = grep { $_ ne '*' } @{ $def->{optional} // [] };
                my @required = @{ $def->{required} // [] };

                my $i = 1;
                my %vals;
                while (@required) {
                    throws_ok {
                        $service->$action(%vals);
                    } qr/parameter $required[0] is required/;

                    my $key = shift @required;
                    $vals{ $key } = $i++;
                }

                my $expected_path = "test/$def->{path}";
                $expected_path =~ s/:id/$vals{id}/;
                $expected_path .= '?access_token=test'
                    unless defined $def->{token} && $def->{token} == 0;

                while (1) {
                    $service->$action(%vals);

                    my $this_expected_path = $expected_path;

                    my ($name, $args) = $ua->next_call;
                    my (undef, $path, @fields) = @$args;
                    my $content;
                    my $headers = [];
                    while (my ($key, $value) = splice @fields, 0, 2) {
                        if ($key eq 'Content') {
                            $content = $value;
                        }
                        else {
                            push @$headers, $key => $value;
                        }
                    }

                    is($name, $def->{method} ? lc $def->{method} : 'get', "$service_name.$action uses correct method");

                    my %post_vals = %vals;
                    delete $post_vals{id};

                    if (!defined $def->{method} || $def->{method} eq 'GET' || $def->{method} eq 'DELETE') {
                        $this_expected_path .= join('&', '', map { "$_=$post_vals{$_}" } sort keys %post_vals);
                    }
                    is($path, $this_expected_path, "$service_name.$action posted to correct path");

                    if ($def->{method} eq 'POST' || $def->{method} eq 'PUT') {
                        is_deeply(
                            $headers,
                            [ 'Content-Type' => 'application/json' ],
                        );

                        is($content, to_json(\%post_vals, { canonical => 1 }));
                    }

                    # TODO Add test for %custom_properties validation

                    my $key = shift @optional;
                    last unless $key;
                    if ($key =~ s/^%//) {
                        $vals{ $key } = {};
                    }
                    else {
                        $vals{ $key } = $i++;
                    }
                }

                $service->$action(%vals, some_outlier_param_never_used => -1);
                my ($name, $args) = $ua->next_call;
                my (undef, $path, @fields) = @$args;
                my $content;
                my $headers = [];
                while (my ($key, $value) = splice @fields, 0, 2) {
                    if ($key eq 'Content') {
                        $content = $value;
                    }
                    else {
                        push @$headers, $key => $value;
                    }
                }

                my %post_vals = %vals;
                delete $post_vals{id};
                $post_vals{some_outlier_param_never_used} = -1
                    if $allow_any;

                if (!defined $def->{method} || $def->{method} eq 'GET' || $def->{method} eq 'DELETE') {
                    $expected_path .= join('&', '', map { "$_=$post_vals{$_}" } sort keys %post_vals);
                }
                is($path, $expected_path, "$service_name.$action posted to correct path");

                if ($def->{method} eq 'POST' || $def->{method} eq 'PUT') {
                    is_deeply(
                        $headers,
                        [ 'Content-Type' => 'application/json' ],
                    );

                    is($content, to_json(\%post_vals, { canonical => 1 }));
                }
            };
        }
    };
}
