use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Test::WWW::Hetzner::Mock;

my $fixture_list = load_fixture('robot_rdns_list');
my $fixture_get  = load_fixture('robot_rdns_get');

# what was sent, and with which HTTP method
my @calls;

my $robot = mock_robot(
    'GET /rdns'                 => $fixture_list,
    'GET /rdns/203.0.113.50'    => $fixture_get,
    'PUT /rdns/203.0.113.50'    => sub {
        my ($method, $path, %opts) = @_;
        push @calls, [$method, $path, $opts{body}];
        return { rdns => { ip => '203.0.113.50', ptr => $opts{body}{ptr} } };
    },
    'POST /rdns/203.0.113.50'   => sub {
        my ($method, $path, %opts) = @_;
        push @calls, [$method, $path, $opts{body}];
        return { rdns => { ip => '203.0.113.50', ptr => $opts{body}{ptr} } };
    },
    'DELETE /rdns/203.0.113.50' => sub {
        my ($method, $path, %opts) = @_;
        push @calls, [$method, $path, undef];
        return '';
    },
);

subtest 'list rdns entries' => sub {
    my $entries = $robot->rdns->list;
    is(ref($entries), 'ARRAY', 'Returns arrayref');
    is(scalar(@$entries), 2, 'Has 2 entries');

    isa_ok($entries->[0], 'WWW::Hetzner::Robot::RDNS');
    is($entries->[0]->ip, '203.0.113.50', 'ip');
    is($entries->[0]->ptr, 'dedi-1.omnicorp.example', 'ptr');
    is($entries->[1]->ip, '203.0.113.51', 'second ip');
    is($entries->[1]->ptr, 'mail.omnicorp.example', 'second ptr');
};

subtest 'get rdns entry' => sub {
    my $entry = $robot->rdns->get('203.0.113.50');
    isa_ok($entry, 'WWW::Hetzner::Robot::RDNS');
    is($entry->ip, '203.0.113.50', 'ip');
    is($entry->ptr, 'dedi-1.omnicorp.example', 'ptr');
};

subtest 'create uses PUT, update uses POST' => sub {
    @calls = ();

    my $created = $robot->rdns->create('203.0.113.50', 'new.omnicorp.example');
    isa_ok($created, 'WWW::Hetzner::Robot::RDNS');
    is($created->ptr, 'new.omnicorp.example', 'created ptr echoed back');

    my $updated = $robot->rdns->update('203.0.113.50', 'other.omnicorp.example');
    is($updated->ptr, 'other.omnicorp.example', 'updated ptr echoed back');

    is_deeply(\@calls, [
        ['PUT',  '/rdns/203.0.113.50', { ptr => 'new.omnicorp.example' }],
        ['POST', '/rdns/203.0.113.50', { ptr => 'other.omnicorp.example' }],
    ], 'create PUTs, update POSTs, both send ptr');
};

subtest 'delete rdns entry' => sub {
    @calls = ();
    $robot->rdns->delete('203.0.113.50');
    is_deeply(\@calls, [['DELETE', '/rdns/203.0.113.50', undef]], 'DELETE issued');
};

subtest 'entity writes back through the client' => sub {
    @calls = ();

    my $entry = $robot->rdns->get('203.0.113.50');
    $entry->ptr('changed.omnicorp.example');
    my $result = $entry->update;
    is($result->{ptr}, 'changed.omnicorp.example', 'update returns the new entry');

    $entry->delete;

    is_deeply(\@calls, [
        ['POST',   '/rdns/203.0.113.50', { ptr => 'changed.omnicorp.example' }],
        ['DELETE', '/rdns/203.0.113.50', undef],
    ], 'entity update POSTs the current ptr, delete DELETEs');
};

subtest 'required parameters are enforced' => sub {
    like(exception(sub { $robot->rdns->get() }),    qr/IP address required/, 'get without ip');
    like(exception(sub { $robot->rdns->create('203.0.113.50') }), qr/ptr required/, 'create without ptr');
    like(exception(sub { $robot->rdns->update('203.0.113.50') }), qr/ptr required/, 'update without ptr');
    like(exception(sub { $robot->rdns->delete() }), qr/IP address required/, 'delete without ip');
};

sub exception {
    my ($code) = @_;
    my $ok = eval { $code->(); 1 };
    return $ok ? '' : $@;
}

done_testing;
