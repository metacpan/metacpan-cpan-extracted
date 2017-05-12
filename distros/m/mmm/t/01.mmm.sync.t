#!perl

use strict;
use warnings;

use Test::More tests => 12;

use_ok('MMM::Sync');
use_ok('MMM::Sync::Dummy');
use_ok('MMM::Sync::Ftp');
use_ok('MMM::Sync::Rsync');

isa_ok(
    MMM::Sync->new('ftp://server/path', '/a/path'),
    'MMM::Sync::Ftp'
);
isa_ok(
    MMM::Sync->new('rsync://server/path', '/a/path'),
    'MMM::Sync::Rsync'
);
isa_ok(
    MMM::Sync->new('dummy://server/0/1/0', '/a/path'),
    'MMM::Sync::Dummy'
);

{
    my $sync = MMM::Sync->new('rsync://server/path', '/a/path');
    my @command = $sync->buildcmd();
    ok(scalar(@command), "We get an non empty command");
    is($command[-1], '/a/path/', "We get proper dest");
    is($command[-2], 'rsync://server/path/', "We get proper source");
}
{
    my $sync = MMM::Sync->new('dummy://server/1/0', '/a/path');
    is($sync->sync(), 1, "Can perform sync");
    is($sync->sync(), 0, "Can perform sync");
}
