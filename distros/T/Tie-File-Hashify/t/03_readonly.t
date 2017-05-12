#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 7;

use IO::File;
use Tie::File::Hashify;

$SIG{__DIE__} = sub{};
$SIG{__WARN__} = sub{};

my $rcpath = '/tmp/tie-file-hashify-test.rc';

my $io = new IO::File('>' . $rcpath);
ok($io, 'write test-file');

$io->print(<DATA>);
$io->close;

my %rc;
my $ok;

$ok = tie(%rc, 'Tie::File::Hashify', $rcpath, 
	parse => qr{^\s*(\S+)\s*=\s*(.*?)\s*$}, 
	ro => 1
);

eval { $rc{foo} = 'quux' }; chomp($@);
like($@, qr/^Can't store in read-only mode/, "store foo: $@");
eval { delete $rc{bar} }; chomp($@);
like($@, qr/^Can't delete in read-only mode/, "delete bar: $@");
eval { %rc = () }; chomp($@);
like($@, qr/^Can't clear in read-only mode/, "clear: $@");

ok($rc{foo} eq 'bar', 'fetch foo');
ok($rc{bar} eq 'baz', 'fetch bar');
ok($rc{baz} eq 'qux', 'fetch baz');


untie %rc;

unlink $rcpath;

__DATA__
foo = bar

 bar = baz 
	baz = qux

