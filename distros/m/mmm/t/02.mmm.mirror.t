use strict;
use warnings;

use Test::More tests => 16;

use_ok('MMM::Mirror');

{
my $mi = MMM::Mirror->new(
    url => 'rsync://foo.com/share',
    source => 'source',
    level => 2,
    frequency => 10,
    latitude => 90,
    longitude => 90,
);
isa_ok($mi, 'MMM::Mirror');
is($mi->source, 'source', 'can get source info');
is($mi->level, 2, 'can get level info');
is($mi->url, 'rsync://foo.com/share', 'can get url info');
is($mi->frequency, 10, 'can get frequency info');
like($mi->revision, qr/^\d{14}$/, "can get revision");

ok($mi->set_source('anothersource'), 'can set another source');
is($mi->source, 'anothersource', 'can get source info after change');

my $mi2 = MMM::Mirror->new(
    url => 'rsync://foo.com/share',
    source => 'source',
    level => 1,
);
$mi2->sync_mirror($mi);
is($mi2->level, 1, 'merged infos return newer');
is($mi2->frequency, 10, 'merged infos the set one');
isa_ok($mi->hostinfo, 'MMM::Host');
ok(eq_array([ $mi->hostinfo->geo ], [ 90, 90 ]), 'Can properly get host info');
}

ok(! MMM::Mirror->new(), 'Deny to build invalid mirror entry');
ok(! MMM::Mirror->new(url => 'bad url'), 'Deny to build mirror with invalid url');
ok(MMM::Mirror->new(url => 'rsync://foo.com/share'), 'Minimum info is url');

