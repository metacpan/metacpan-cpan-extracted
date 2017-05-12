# ex:ts=4:sw=4:sts=4:et
use warnings;
use strict;
use lib qw(lib);
use Test::More;
use Transmission::Client;
use JSON::MaybeXS;

$SIG{'__DIE__'} = \&Carp::confess;

my($client, $rpc_response, $rpc_request, @torrents);
my $rpc_response_code = 409;

{
    no warnings 'redefine';
    *LWP::UserAgent::post = sub {
        my($lwp, $url, %args) = @_;
        my $res = HTTP::Response->new;
        $rpc_request = $args{'Content'};
        my($tag) = $rpc_request =~ /"tag":\s*(\d+)/;

        $rpc_response =~ s/"tag":\s*\w+/"tag":$tag/;
        $res->code($rpc_response_code);
        $res->content($rpc_response);
        $res->header('X-Transmission-Session-Id' => '1234567890') unless($client->session_id);
        $rpc_response_code = 200 if($rpc_response_code == 409);

        return $res;
    };

    Transmission::Session->meta->add_method(read_all => sub {});
}

{ # generic
    $client = Transmission::Client->new(autodie => 1);
    is($client->_autodie, 1, 'Transmission::Client will die on error');
    is($client->url, 'http://localhost:9091/transmission/rpc', 'default url is set');
    is($client->_url, $client->url, 'default _url is without username/password');
    isa_ok($client->_ua, 'LWP::UserAgent');

    $rpc_response = '{ "tag": TAG, "result": "success", "arguments": 123 }';
    is($client->session_id, '', 'session ID is not set until the first rpc() request');
    is($client->rpc('foo_bar'), 123, 'rpc() request responded with 123');
    request_has(method => 'foo-bar', 'foo_bar method was transformed to foo-bar');
    is($client->session_id, '1234567890', 'session ID was set by mocked HTTP request');

    $rpc_response = '{ "tag": TAG, "result": "success", "arguments": { "version": 42 } }';
    is($client->version, 42, 'got mocked Transmission version');
}

{ # add
    my %args = (
        download_dir => 'some/dir',
        paused => 1,
        peer_limit => 42,
    );

    eval { $client->add };
    like($@, qr{Need either filename or metainfo argument}, 'add() require filename or metainfo');
    eval { $client->add(filename => 'foo', metainfo => 'bar') };
    like($@, qr{Filename and metainfo argument crash}, 'add() cannot handle both filename and metainfo');

    $rpc_response = '{ "tag": TAG, "result": "success", "arguments": 1 }';
    ok($client->add(filename => 'foo.torrent'), 'add() torrent by filename');
    request_has(
        arguments => {
            filename => "foo.torrent",
        },
        method => "torrent-add",

        'add() with filename');

    ok($client->add(metainfo => {}), 'add() torrent with metainfo');
    request_has(
        arguments => {
            metainfo => undef,
        },
        method => "torrent-add",

        'add() with metainfo');
}

{ # remove, move, start, stop, verify / _do_ids_action()
    eval { $client->remove };
    like($@, qr{ids is required as argument}, 'remove() require ids argument');
    ok(!$client->has_torrents, 'remove() does not clear "torrents" attribute on failure');

    ok($client->remove(ids => 'all'), 'remove() with ids = "all"');
    ok($rpc_request !~ /ids/, 'remove() did not pass on ids, when ids = "all"');
    request_has(method => "torrent-remove", 'remove() does rpc method torrent-remove');

    ok($client->remove(ids => 42), 'remove() can take a single id');
    ok($client->remove(ids => [24, 42]), 'remove() can take a list of ids');
    like($rpc_request, qr{[24,\s*42]}, 'remove() with list of ids');
    ok(!$client->has_torrents, 'remove() also cleared "torrents" attribute');

    eval { $client->move };
    like($@, qr{location argument is required}, 'move() require "location"');

    ok($client->move(location => '/some/path', ids => 42), 'move() with location and ids');
    request_has(
        method => "torrent-set-location",
        arguments => {
            location => '/some/path',
            ids => [42],
        },

        'move() does rpc method torrent-set-location');

    ok($client->start(ids => 42), 'start() with location and ids');
    request_has(
        method => "torrent-start",
        arguments => {
            ids => [42],
        },

        'start() does rpc method torrent-start');

    ok($client->stop(ids => 42), 'stop() with location and ids');
    request_has(
        method => "torrent-stop",
        arguments => {
            ids => [42],
        },

        'stop() does rpc method torrent-stop');

    ok($client->verify(ids => 42), 'verify() with location and ids');
    request_has(
        method => "torrent-verify",
        arguments => {
            ids => [42],
        },

        'verify() does rpc method torrent-verify');
}

{
    $rpc_response = '{ "tag": TAG, "result": "success", "arguments": { "torrents":[] } }';
    is(my @torrents = $client->torrent_list, 0, 'torrent_list() contains zero objects');
    is_deeply($client->torrents, \@torrents, 'torrent_list() returns a list, while "torrents" contains an array-ref');

    $rpc_response = '{ "tag": TAG, "result": "success", "arguments": { "torrents":[] } }';

    $client->read_torrents;
    request_has(
        method => 'torrent-get',
        arguments => {
            fields => [qw(
                creator uploadRatio leechers sizeWhenDone recheckProgress
                maxConnectedPeers activityDate id swarmSpeed peersConnected
                pieceCount torrentFile name isPrivate webseedsSendingToUs
                timesCompleted addedDate downloadedEver downloaders peersKnown
                seeders downloadDir startDate desiredAvailable status
                peersSendingToUs peersGettingFromUs rateDownload corruptEver
                leftUntilDone uploadedEver error rateUpload manualAnnounceTime
                doneDate totalSize dateCreated pieceSize percentDone errorString
                haveValid hashString eta haveUnchecked comment uploadLimit
                downloadLimit seedRatioMode bandwidthPriority downloadLimited
                seedRatioLimit uploadLimited honorsSessionLimits)]
        },

        'read_torrents() with all fields',
    );

    $client->read_torrents(fields => [qw(name eta)]);
    request_has(
        method => 'torrent-get',
        arguments => {
            fields => [qw(id name eta)],
        },

        'read_torrents() with only specific fields',
    );

    $client->read_torrents(lazy_read => 1);
    request_has(
        method => 'torrent-get',
        arguments => {
            fields => ["id"],
        },

        'read_torrents() with lazy_read',
    );

    $client->read_torrents(ids => 42);
    request_has(
        method => 'torrent-get',
        arguments => {
            ids => [42],
        },

        'read_torrents() with ids',
    );
}

{ # RT#67691
    $client->rpc(foo_bar => ids => [1,2,'foo']);
    like($rpc_request, qr{"ids":\[1,2,"foo"\]}, 'Fix RT#67691: id "foo" is still a string');
}

TODO: {
    local $TODO = 'require better testing';
    ok(!$client->has_session, 'client has no session');
    ok($client->read_all, 'read_all() information');
    ok($client->has_session, 'read_all() set session attribute');
}

sub request_has {
    my $description = pop;
    my %args = @_;
    my @failed;

    note $description;

    # $rpc_request is set to the latest post request the test would have done
    my $rpc_req = decode_json($rpc_request);

    # All requests must have a method parameter
    ok exists $rpc_req->{method}, 'Existance of methods key';

    for my $top (keys %args) {
        if (ref $args{$top}) {
            for my $key (keys %{$args{$top}}) {
                if (not defined $args{$top}->{$key}) {
                    ok exists $rpc_req->{$top}->{$key},
                        "Existance of $top\->{$key}";
                    next;
                }

                if (not ref $rpc_req->{$top}->{$key} and
                    not ref $args{$top}->{$key}) {
                    is $rpc_req->{$top}->{$key}, $args{$top}->{$key},
                        "Comparing value for $top\->{$key}";
                    next;
                }

                is ref $rpc_req->{$top}->{$key}, 'ARRAY',
                    "$top\->{$key} should be an array";

                SKIP: {
                    skip "See previous test failure",
                        @{$args{$top}->{$key}} + 1 unless
                        ref $rpc_req->{$top}->{$key} eq 'ARRAY';

                    # Make sure all expected values exist
                    my %seen;
                    for my $elm (@{$args{$top}->{$key}}) {
                        ok(
                            grep({$elm eq $_} @{$rpc_req->{$top}->{$key}}),
                            "$top\->{$key} should have expected values ($elm)");
                        $seen{$elm} = 1;
                    }

                    # Make sure no unexpected values exist
                    is_deeply [
                        grep {! exists $seen{$_}} @{$rpc_req->{$top}->{$key}},
                    ], [], "No unexpected elements found in $top\->{$key}";

                }
            }
        }
        else {
            is $rpc_req->{$top}, $args{$top}, "Comparing value for $top";
        }
   }
}

done_testing();
