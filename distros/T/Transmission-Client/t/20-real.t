#!perl
# ex:ts=4:sw=4:sts=4:et

use strict;
use warnings;
use lib qw(lib);
use Transmission::Client;
use Test::More;

plan skip_all => "REAL_TEST is not set" unless($ENV{'REAL_TEST'});
plan tests => 24;

my $obj = Transmission::Client->new(username => 'testman', password => 'test');
my $id = $ENV{'REAL_TEST'};

is($obj->url, 'http://localhost:9091/transmission/rpc', '->url');
is($obj->_url, 'http://testman:test@localhost:9091/transmission/rpc', '->_url');
isa_ok($obj->session, 'Transmission::Session', '->session');
isa_ok($obj->stats, 'Transmission::Stats', '->stats');
ok($obj->torrents, '->torrents');
like($obj->version || '__undef__', qr{^\d+.\d+}, '->version');

ok(!$obj->add, "Could not add") or diag($obj->error);
ok(!$obj->remove, "Could not remove") or diag($obj->error);
ok(!$obj->start, "Could not start") or diag($obj->error);
ok(!$obj->stop, "Could not stop") or diag($obj->error);
ok(!$obj->verify, "Could not verify") or diag($obj->error);

SKIP: {
    is(int(@_ = $obj->read_torrents(eager_read => $id)), 3, "->read_torrents eagerly");
    is(int(@_ = $obj->read_torrents(ids => $id)), 1, "->read_torrents with ids") or skip 'fail to read torrent', 11;

    my $torrent = $obj->torrents->[0];
    ok(@{ $torrent->files } > 0, 'torrent has files');

    my $file = $torrent->files->[0];
    like($file->name, qr{\w}, 'torrent has name');
    ok($file->length > 0, 'torrent has size');
    is($file->priority, 0, 'torrent has normal priority');

    $file->priority(1);
    $file->wanted(0);
    ok($torrent->write_priority, 'torrent priority has been written');
    ok($torrent->write_wanted, 'torrent wanted has been written');
    ok($obj->read_all, "data is refreshed");

    $file = $torrent->files->[0];

    is($file->priority, 1, 'file has high priority');
    is($file->wanted, 0, 'file is not wanted');

    $file->priority(0);
    $file->wanted(1);
    ok($torrent->write_priority, 'torrent priority has reset');
    ok($torrent->write_wanted, 'torrent wanted has reset');
}

#print $obj->dump;
