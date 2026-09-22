use strict;
use warnings;
use Test::More;
use WWW::Hetzner::HTTPResponse;
use lib 't/lib';
use Test::WWW::Hetzner::Mock;

sub attempt {
    my ($code) = @_;
    my ($result, $error);
    my $ok = eval {
        $result = $code->();
        1;
    };
    $error = $@ unless $ok;
    return ($result, $error // '');
}

sub list_all {
    my ($api, %params) = @_;
    return attempt(sub { $api->list_all(%params) });
}

sub ids {
    my ($entities) = @_;
    return [ map { $_->id } @{ $entities // [] } ];
}

sub rrset_names {
    my ($rrsets) = @_;
    return [ map { $_->name . q{/} . $_->type } @{ $rrsets // [] } ];
}

sub pagination {
    my (%params) = @_;
    return {
        pagination => {
            page          => $params{page},
            per_page      => $params{per_page},
            previous_page => $params{previous_page},
            next_page     => $params{next_page},
            last_page     => $params{last_page},
            total_entries => $params{total_entries},
        },
    };
}

sub servers_page {
    my (%params) = @_;
    my $page = load_fixture('servers_list');
    $page->{servers}[0]{id}   = $params{id};
    $page->{servers}[0]{name} = $params{name};
    $page->{meta} = pagination(
        page          => $params{page},
        per_page      => $params{per_page},
        previous_page => $params{previous_page},
        next_page     => $params{next_page},
        last_page     => $params{last_page},
        total_entries => $params{total_entries},
    );
    return $page;
}

sub actions_page {
    my (%params) = @_;
    my $page = load_fixture('actions_list');
    $page->{actions} = [ $page->{actions}[0] ];
    $page->{actions}[0]{id} = $params{id};
    $page->{meta} = pagination(
        page          => $params{page},
        per_page      => $params{per_page},
        previous_page => $params{previous_page},
        next_page     => $params{next_page},
        last_page     => $params{last_page},
        total_entries => $params{total_entries},
    );
    return $page;
}

subtest 'Servers list remains one page while list_all follows all pages' => sub {
    my $first = servers_page(
        id => 1, name => 'first-server', page => 1, per_page => 2,
        next_page => 2, last_page => 2, total_entries => 2,
    );
    my $second = servers_page(
        id => 2, name => 'second-server', page => 2, per_page => 2,
        previous_page => 1, last_page => 2, total_entries => 2,
    );
    my @seen;
    my $cloud = mock_cloud(
        'GET /servers' => sub {
            my ($method, $path, %opts) = @_;
            push @seen, {
                params  => $opts{params},
                request => $opts{request},
            };
            my $page = ($opts{params} // {})->{page} // 1;
            return $page == 1 ? $first : $second;
        },
    );

    my $single = $cloud->servers->list(per_page => 2);
    is_deeply(ids($single), [1], 'list remains a single-page request');
    is(scalar @seen, 1, 'list makes one request despite next_page metadata');

    @seen = ();
    my %params = (
        label_selector => 'env=production',
        per_page       => 2,
        sort           => [ 'id', 'name:asc' ],
    );
    my ($servers, $error) = list_all($cloud->servers, %params);

    ok($cloud->servers->can('list_all'), 'Servers exposes additive list_all');
    is($error, '', 'Servers list_all completes without an error');
    is_deeply(ids($servers), [1, 2], 'Servers list_all combines both pages');
    is_deeply([ map { $_->{params} } @seen ], [
        {
            label_selector => 'env=production',
            per_page       => '2',
            sort           => [ 'id', 'name:asc' ],
        },
        {
            label_selector => 'env=production',
            page           => '2',
            per_page       => '2',
            sort           => [ 'id', 'name:asc' ],
        },
    ], 'per_page, filter, and repeated sort values continue on every page');
    isa_ok($seen[0]{request}, 'WWW::Hetzner::HTTPRequest', 'first pagination request is available raw');
    isa_ok($seen[1]{request}, 'WWW::Hetzner::HTTPRequest', 'following pagination request is available raw');
    is_deeply(\%params, {
        label_selector => 'env=production',
        per_page       => 2,
        sort           => [ 'id', 'name:asc' ],
    }, 'list_all does not mutate caller parameters');
};

subtest 'Actions list_all honors an explicit starting page' => sub {
    my $third = actions_page(
        id => 300, page => 3, per_page => 50,
        previous_page => 2, next_page => 4, last_page => 4, total_entries => 200,
    );
    my $fourth = actions_page(
        id => 400, page => 4, per_page => 50,
        previous_page => 3, last_page => 4, total_entries => 200,
    );
    my @seen;
    my $cloud = mock_cloud(
        'GET /actions' => sub {
            my ($method, $path, %opts) = @_;
            push @seen, {
                params  => $opts{params},
                request => $opts{request},
            };
            return ($opts{params} // {})->{page} == 3 ? $third : $fourth;
        },
    );
    my %params = (
        page     => 3,
        per_page => 50,
        status   => 'running',
        sort     => [ 'id', 'command' ],
    );
    my ($actions, $error) = list_all($cloud->actions, %params);

    ok($cloud->actions->can('list_all'), 'Actions exposes additive list_all');
    is($error, '', 'Actions list_all completes without an error');
    is_deeply(ids($actions), [300, 400], 'Actions list_all begins at explicit page and collects later pages');
    is_deeply([ map { $_->{params} } @seen ], [
        {
            page     => '3',
            per_page => '50',
            status   => 'running',
            sort     => [ 'id', 'command' ],
        },
        {
            page     => '4',
            per_page => '50',
            status   => 'running',
            sort     => [ 'id', 'command' ],
        },
    ], 'Actions keeps explicit page, per_page, filter, and repeated sort values');
    isa_ok($seen[0]{request}, 'WWW::Hetzner::HTTPRequest', 'Actions initial request is available raw');
    isa_ok($seen[1]{request}, 'WWW::Hetzner::HTTPRequest', 'Actions following request is available raw');
    is_deeply(\%params, {
        page     => 3,
        per_page => 50,
        status   => 'running',
        sort     => [ 'id', 'command' ],
    }, 'Actions list_all does not mutate explicit caller parameters');
};

subtest 'RRSets list_all uses its nested path and accepts a response without meta' => sub {
    my $page = load_fixture('rrsets_list');
    $page->{rrsets} = [ $page->{rrsets}[0] ];
    delete $page->{meta};
    my @seen;
    my $cloud = mock_cloud(
        'GET /zones/42/rrsets' => sub {
            my ($method, $path, %opts) = @_;
            push @seen, {
                params  => $opts{params},
                request => $opts{request},
            };
            return $page;
        },
    );

    my ($rrsets, $error) = list_all($cloud->zones->rrsets(42), type => 'A', per_page => 5);

    ok($cloud->zones->rrsets(42)->can('list_all'), 'RRSets exposes additive list_all');
    is($error, '', 'RRSets response without meta is treated as one page');
    is_deeply(rrset_names($rrsets), ['@/A'], 'RRSets list_all wraps the one response');
    is_deeply([ map { $_->{params} } @seen ], [{ type => 'A', per_page => '5' }], 'RRSets sends filters once to its nested endpoint');
    is(scalar @seen, 1, 'RRSets does not invent a follow-up page without metadata');
    isa_ok($seen[0]{request}, 'WWW::Hetzner::HTTPRequest', 'RRSet nested request is available raw');
};

subtest 'Image name lookup finds a match on the second page' => sub {
    my $first = load_fixture('images_list');
    $first->{images} = [ $first->{images}[0] ];
    $first->{images}[0]{id} = 1;
    $first->{images}[0]{name} = 'not-the-target';
    $first->{meta} = pagination(
        page => 1, per_page => 1, next_page => 2, last_page => 2, total_entries => 2,
    );
    my $second = load_fixture('images_list');
    $second->{images} = [ $second->{images}[1] ];
    $second->{images}[0]{id} = 2;
    $second->{images}[0]{name} = 'target-image';
    $second->{meta} = pagination(
        page => 2, per_page => 1, previous_page => 1, last_page => 2, total_entries => 2,
    );
    my @seen;
    my $cloud = mock_cloud(
        'GET /images' => sub {
            my ($method, $path, %opts) = @_;
            push @seen, {
                params  => $opts{params},
                request => $opts{request},
            };
            my $page = ($opts{params} // {})->{page} // 1;
            return $page == 1 ? $first : $second;
        },
    );

    my ($image, $error) = attempt(sub { $cloud->images->get_by_name('target-image') });

    ok($cloud->images->can('list_all'), 'Images exposes additive list_all for name lookup');
    is($error, '', 'image name lookup completes without an error');
    isa_ok($image, 'WWW::Hetzner::Cloud::Image', 'image name lookup returns a wrapped image');
    is($image ? $image->name : undef, 'target-image', 'image name lookup reaches the match on page two');
    is_deeply([ map { $_->{params} } @seen ], [
        { name => 'target-image' },
        { name => 'target-image', page => '2' },
    ], 'image name filter is retained on every page');
    isa_ok($seen[0]{request}, 'WWW::Hetzner::HTTPRequest', 'image initial request is available raw');
    isa_ok($seen[1]{request}, 'WWW::Hetzner::HTTPRequest', 'image following request is available raw');
};

subtest 'list_all rejects non-advancing and cyclical next_page values' => sub {
    for my $case (
        {
            name => 'non-advancing next_page',
            pages => {
                1 => servers_page(
                    id => 1, name => 'first-server', page => 1, per_page => 1,
                    next_page => 1, last_page => 2, total_entries => 2,
                ),
            },
            expected_requests => 1,
        },
        {
            name => 'cyclical next_page',
            pages => {
                1 => servers_page(
                    id => 1, name => 'first-server', page => 1, per_page => 1,
                    next_page => 2, last_page => 2, total_entries => 2,
                ),
                2 => servers_page(
                    id => 2, name => 'second-server', page => 2, per_page => 1,
                    previous_page => 1, next_page => 1, last_page => 2, total_entries => 2,
                ),
            },
            expected_requests => 2,
        },
    ) {
        subtest $case->{name} => sub {
            my @seen;
            my $cloud = mock_cloud(
                'GET /servers' => sub {
                    my ($method, $path, %opts) = @_;
                    push @seen, $opts{params};
                    my $page = ($opts{params} // {})->{page} // 1;
                    return $case->{pages}{$page};
                },
            );

            my ($servers, $error) = list_all($cloud->servers, per_page => 1);

            ok($cloud->servers->can('list_all'), 'Servers exposes list_all for pagination validation');
            ok(!defined $servers, 'invalid next_page does not return an accumulated partial result');
            unlike($error, qr/Can't locate object method "list_all"/, 'list_all reaches pagination validation');
            ok(length $error, 'invalid next_page raises an error');
            is(scalar @seen, $case->{expected_requests}, 'stops before requesting a repeated or non-advancing page');
        };
    }
};

subtest 'list_all propagates a following-page error without returning partial results' => sub {
    my $first = servers_page(
        id => 1, name => 'first-server', page => 1, per_page => 1,
        next_page => 2, last_page => 2, total_entries => 2,
    );
    my @seen;
    my $cloud = mock_cloud(
        'GET /servers' => sub {
            my ($method, $path, %opts) = @_;
            push @seen, $opts{params};
            my $page = ($opts{params} // {})->{page} // 1;
            return $first if $page == 1;
            return WWW::Hetzner::HTTPResponse->new(
                status  => 500,
                content => '{"error":{"message":"page two unavailable"}}',
            );
        },
    );

    my ($servers, $error) = list_all($cloud->servers, per_page => 1);

    ok($cloud->servers->can('list_all'), 'Servers exposes list_all for following-page failures');
    ok(!defined $servers, 'following-page failure does not return a partial result');
    like($error, qr/page two unavailable/, 'following-page API error is propagated');
    is(scalar @seen, 2, 'second page was attempted before its API error propagated');
};

done_testing;
