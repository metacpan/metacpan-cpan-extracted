use strict;
use warnings;
use utf8;

use lib 't/lib';

use Mojo::IOLoop;
use Mojo::Promise;
use Test::More;
use VPNDetection;
use VPNDetectionTest::Origin;

# The user agent of the request being decided on: sent with a lookup, my_ip and
# each batch entry, cached on the address and the agent, never on a bogon.

my $GOOGLEBOT = 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)';
my $CHROME = 'Mozilla/5.0 (X11; Linux x86_64) Chrome/131.0 Safari/537.36';

# The verdict the origin answers for an agent, so two agents' answers differ.
sub verdict_for {
    my ($agent) = @_;
    return { agent => 'Googlebot', kind => 'bot', verdict => $agent eq $GOOGLEBOT ? 'verified' : 'not_bot' };
}

my @bodies;
my $delay = 0;
my $origin = VPNDetectionTest::Origin->new(sub {
    my ($c) = @_;
    if ($c->req->url->path->to_string eq '/batch') {
        my $json = $c->req->json;
        push @bodies, $json;
        my $agents = $json->{user_agents} || {};
        return $c->render(json => {
            results => { map {
                ($_ => { ip => $_, is_vpn => \0, defined $agents->{$_} ? (user_agent => verdict_for($agents->{$_})) : () })
            } @{ $json->{ips} } },
            errors => {},
        });
    }
    my $agent = $c->req->url->query->param('user_agent');
    my ($ip) = $c->req->url->path->to_string =~ m{^/(.*)};
    $ip = '8.8.4.4' if $ip eq 'myip';
    my $body = { ip => $ip, is_vpn => \0, defined $agent ? (user_agent => verdict_for($agent)) : () };
    return $delay ? VPNDetectionTest::Origin::slow_json($c, $body, $delay) : $c->render(json => $body);
});

sub client {
    return VPNDetection->new(base_url => $origin->url, api_key => 'k', retries => 0, @_);
}

# The decoded user_agent each request carried, undef where it carried none.
sub agents_sent {
    return map { $_->{query}{user_agent} } $origin->requests;
}

# Read through eval, so a release without the member fails at the assertion
# rather than ending the file.
sub has_ua {
    my ($result) = @_;
    my $has = eval { $result->has('user_agent') };
    return defined $has ? $has : 'no reader';
}

sub ua_of {
    my ($result) = @_;
    return eval { $result->user_agent };
}

sub verdict_of {
    my ($result) = @_;
    my $ua = ua_of($result);
    return ref $ua eq 'HASH' ? $ua->{verdict} : undef;
}

subtest 'a lookup sends its user agent percent-encoded, and reads the verdict' => sub {
    $origin->reset;
    my $agent = "$GOOGLEBOT a&b=c#d%e;f?g é";
    my $result = eval { client()->lookup('8.8.8.8', user_agent => $agent) };
    is($@, '', 'a lookup takes user_agent');
    is($origin->count, 1, 'one request');
    my ($request) = $origin->requests;
    is($request->{query}{user_agent}, $agent, 'the agent reached the origin whole');
    my $raw = $request->{raw_query} // '';
    like($raw, qr/\Auser_agent=[^&]*\z/, 'as the one query parameter, its & escaped');
    like($raw, qr/%2Bhttp%3A%2F%2Fwww\.google\.com%2Fbot\.html%29/, 'its + : / and ) percent-encoded');
    unlike($raw, qr/[#;?]|\+http/, 'no reserved character raw');
    like($raw, qr/%C3%A9\z/, 'and a character past ASCII as its UTF-8');
    is(has_ua($result), 1, 'the answer carries user_agent');
    is_deeply(ua_of($result), verdict_for($agent), 'read as served');
    is_deeply([$result ? $result->fields : ()], ['is_vpn', 'user_agent'], 'and listed among the fields served');
};

subtest 'a lookup without an agent, or with an empty one, sends none' => sub {
    $origin->reset;
    my $client = client();
    my $plain = eval { $client->lookup('8.8.8.8') };
    my $empty = eval { $client->lookup('9.9.9.9', user_agent => '') };
    is($@, '', 'an empty agent is taken');
    is_deeply([agents_sent()], [undef, undef], 'neither request carried user_agent');
    ok(!grep({ ($_->{raw_query} // '') =~ /user_agent/ } $origin->requests), 'not even empty');
    is(has_ua($plain), 0, 'an answer to no agent has no user_agent');
    is(ua_of($plain), undef, 'and reads it as undef');
    is(has_ua($empty), 0, 'nor an answer to an empty one');
    eval { $client->lookup('9.9.9.9') };
    is($origin->count, 2, 'an empty agent is cached as no agent');
};

subtest 'an agent longer than 1024 characters is sent whole' => sub {
    $origin->reset;
    my $agent = 'a' x 2000;
    eval { client()->lookup('8.8.8.8', user_agent => $agent) };
    is($@, '', 'never refused');
    is_deeply([map { length } agents_sent()], [2000], 'all 2000 characters reached the origin');
};

subtest 'the cache keys on the address and the agent' => sub {
    $origin->reset;
    my $client = client();
    my @answers = map {
        my $agent = $_;
        eval { $client->lookup('8.8.8.8', defined $agent ? (user_agent => $agent) : ()) };
    } undef, $GOOGLEBOT, $CHROME, $GOOGLEBOT, undef, $CHROME;
    is($origin->count, 3, 'three requests for one address and three agents, none for a repeated pair');
    is_deeply([agents_sent()], [undef, $GOOGLEBOT, $CHROME], 'each pair asked once');
    is_deeply([map { verdict_of($_) } @answers],
        [undef, 'verified', 'not_bot', 'verified', undef, 'not_bot'], 'and each pair answered as its own');
};

subtest 'concurrent misses share one request for one address and agent' => sub {
    $origin->reset;
    $delay = 0.2;
    my $client = client();
    my @promises = eval {
        map { $client->lookup_p('8.8.8.8', user_agent => $_) } ($GOOGLEBOT) x 5, ($CHROME) x 5;
    };
    push @promises, eval { $client->lookup_batch_p(['8.8.8.8'], user_agents => { '8.8.8.8' => $GOOGLEBOT }) };
    is($@, '', 'every call is taken');
    my @verdicts;
    Mojo::Promise->all(@promises)->then(sub { @verdicts = map { $_->[0] } @_ })->wait if @promises == 11;
    $delay = 0;
    is($origin->count, 2, 'two requests for ten lookups and a batch over two pairs');
    is_deeply([map { verdict_of(ref $_ eq 'HASH' ? $_->{'8.8.8.8'} : $_) } @verdicts],
        [('verified') x 5, ('not_bot') x 5, 'verified'], 'each waiter took its own pair\'s answer');
};

subtest 'a batch sends user_agents keyed by each address as sent, only where one is set' => sub {
    $origin->reset;
    @bodies = ();
    my $client = client();
    my $answers = eval {
        $client->lookup_batch(['::ffff:8.8.8.8', '1.1.1.1', '9.9.9.9', '10.0.0.1'], user_agents => {
            '::ffff:8.8.8.8' => $GOOGLEBOT, '9.9.9.9' => '', '10.0.0.1' => $GOOGLEBOT, '7.7.7.7' => $CHROME,
        });
    };
    is($@, '', 'a batch takes user_agents');
    is(scalar @bodies, 1, 'one POST /batch');
    is_deeply([sort @{ $bodies[0]{ips} || [] }], ['1.1.1.1', '8.8.8.8', '9.9.9.9'], 'the bogon left out');
    is_deeply($bodies[0]{user_agents}, { '8.8.8.8' => $GOOGLEBOT },
        'only the address with an agent, keyed as sent: the IPv4 a mapped address carries');
    is_deeply($answers && ua_of($answers->{'::ffff:8.8.8.8'}), verdict_for($GOOGLEBOT),
        'answered under the spelling asked');
    is($answers && has_ua($answers->{'10.0.0.1'}), 0, 'a bogon has no user_agent');
    is($answers && has_ua($answers->{'1.1.1.1'}), 0, 'an address with no agent has none');

    $origin->reset;
    eval { $client->lookup('8.8.8.8', user_agent => $GOOGLEBOT) };
    is($origin->count, 0, "a batch entry's answer is cached on its address and agent");
    eval { $client->lookup('8.8.8.8', user_agent => $CHROME) };
    is($origin->count, 1, 'apart from another agent\'s');

    @bodies = ();
    eval { client()->lookup_batch(['1.1.1.1', '9.9.9.9'], user_agents => { '9.9.9.9' => '' }) };
    eval { client()->lookup_batch(['1.1.1.1', '9.9.9.9']) };
    is_deeply([map { exists $_->{user_agents} ? 1 : 0 } @bodies], [0, 0], 'no entry with an agent sends no user_agents');
};

subtest 'a chunk sends user_agents only when one of its own entries has one' => sub {
    @bodies = ();
    my @ips = map { "8.$_->[0].$_->[1].1" } map { my $a = $_; map { [$a, $_] } 1 .. 100 } 1 .. 11;
    eval { client()->lookup_batch([@ips[0 .. 1000]], concurrency => 1, user_agents => { $ips[1000] => $CHROME }) };
    is($@, '', 'a batch of 1001 is taken');
    is_deeply([map { scalar @{ $_->{ips} } } @bodies], [1000, 1], 'two chunks');
    is_deeply([map { $_->{user_agents} } @bodies], [undef, { $ips[1000] => $CHROME }], 'only the second carries one');
};

subtest 'a bogon is answered locally, with no user_agent' => sub {
    $origin->reset;
    my $result = eval { client()->lookup('10.0.0.1', user_agent => $GOOGLEBOT) };
    is($@, '', 'a bogon lookup takes user_agent');
    is($origin->count, 0, 'and sends nothing');
    is(has_ua($result), 0, 'its answer has no user_agent');
};

subtest 'my_ip sends its agent and is never cached' => sub {
    $origin->reset;
    my $client = client();
    my @answers = map { eval { $client->my_ip(user_agent => $GOOGLEBOT) } } 1 .. 2;
    is($@, '', 'my_ip takes user_agent');
    is_deeply([agents_sent()], [$GOOGLEBOT, $GOOGLEBOT], 'both calls asked, each carrying the agent');
    is_deeply(ua_of($answers[0]), verdict_for($GOOGLEBOT), 'and read the verdict');
};

subtest 'an agent that is not a string is refused before any request' => sub {
    $origin->reset;
    my $client = client();
    eval { $client->lookup('8.8.8.8', user_agent => [$GOOGLEBOT]) };
    like($@, qr/user_agent must be a string/, 'a lookup refuses a reference');
    eval { $client->my_ip(user_agent => {}) };
    like($@, qr/user_agent must be a string/, 'my_ip too');
    eval { $client->lookup_batch(['8.8.8.8'], user_agents => [$GOOGLEBOT]) };
    like($@, qr/user_agents must be a hash reference/, 'a batch refuses a list of agents');
    eval { $client->lookup_batch(['8.8.8.8'], user_agents => { '8.8.8.8' => \1 }) };
    like($@, qr/user_agent must be a string/, 'and an agent that is a reference');
    is($origin->count, 0, 'with nothing sent');
};

subtest 'a served user_agent missing a member is a retried server_error' => sub {
    my $served;
    my $broken = VPNDetectionTest::Origin->new(sub { $_[0]->render(json => $served) });
    for my $member (qw(agent kind verdict)) {
        $served = { ip => '8.8.8.8', is_vpn => \0, user_agent => verdict_for($GOOGLEBOT) };
        delete $served->{user_agent}{$member};
        $broken->reset;
        my $client = VPNDetection->new(base_url => $broken->url, retries => 1, cache_size => 0);
        eval { $client->lookup('8.8.8.8', user_agent => $GOOGLEBOT) };
        my $error = $@;
        is(ref $error && $error->can('kind') ? $error->kind . ' after ' . $broken->count : "$error",
            'server_error after 2', "user_agent without $member");
    }
};

done_testing();
