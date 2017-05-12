#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 7;

use IO::File;
use Tie::File::Hashify;

my $rcpath = '/tmp/tie-file-hashify-test.rc';

my $io = new IO::File('>' . $rcpath);
ok($io, 'write test-file');

$io->print(<DATA>);
$io->close;

my %rc;
my $ok;

$ok = tie(%rc, 'Tie::File::Hashify', $rcpath, parse => qr{^\s*(\S+)\s*=\s*(.*?)\s*$});

ok($rc{foo} eq 'bar', 'fetch foo');
ok($rc{bar} eq 'baz', 'fetch bar');
ok($rc{baz} eq 'qux', 'fetch baz');

untie %rc;


$ok = tie(%rc, 'Tie::File::Hashify', $rcpath, parse => '^\s*(\S+)\s*=\s*(.*?)\s*$');

ok($rc{foo} eq 'bar', 'fetch foo');
ok($rc{bar} eq 'baz', 'fetch bar');
ok($rc{baz} eq 'qux', 'fetch baz');

untie %rc;

unlink $rcpath;

__DATA__
foo = bar

 bar = baz 
	baz = qux

