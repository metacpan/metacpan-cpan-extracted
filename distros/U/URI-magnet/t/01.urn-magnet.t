use strict;
use warnings;
use Test::More;

use URI;

my $m = URI->new( 'magnet:?xt=urn:btih:aba75107e5e5c8347e9aef7fcbeec8fc31c1b84d&dn=OpenBSD+5.1+-+amd64&tr=udp%3A%2F%2Ftracker.openbittorrent.com%3A80&tr=udp%3A%2F%2Ftracker.publicbt.com%3A80&tr=udp%3A%2F%2Ftracker.istole.it%3A6969&tr=udp%3A%2F%2Ftracker.ccc.de%3A80&kt=perl+rocks' );

is $m->dn, 'OpenBSD 5.1 - amd64', 'got the URI-escaped dn';
is $m->display_name, $m->dn, 'dn and display_name are synonyms';

is $m->kt, 'perl rocks', 'kt is ok';
is $m->kt, $m->keyword_topic, 'keywork_topic and kt are synonyms';

ok my $topic = $m->xt, 'got the exact topic';
isa_ok $topic, 'URI::urn', 'topic is an URI::urn object';
is $topic, $m->exact_topic, 'xt and exact_topic are synonyms';
is $topic->nid, 'btih', 'nid is "btih"';
is $topic->nss, 'aba75107e5e5c8347e9aef7fcbeec8fc31c1b84d', 'got hash value';

ok my $tracker = $m->tr, 'got the address tracker';
isa_ok $tracker, 'URI', 'address tracker is an URI object';
is scalar $m->tr, scalar $m->address_tracker, 'tr and address_tracker are synonyms';
is
  "$tracker",
  'udp://tracker.openbittorrent.com:80',
  'stringification ok'
;

ok my @trackers = $m->tr, 'got the tracker array';
is scalar @trackers, 4, 'found 4 address trackers';
my @hashes = qw(
  udp://tracker.openbittorrent.com:80
  udp://tracker.publicbt.com:80
  udp://tracker.istole.it:6969
  udp://tracker.ccc.de:80
);
foreach my $i ( 0 .. $#trackers) {
  is "$trackers[$i]", $hashes[$i], "tracker $i is ok";
}

done_testing;
