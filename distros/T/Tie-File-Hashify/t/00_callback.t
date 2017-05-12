#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 20;

use IO::File;
use Tie::File::Hashify;

my $rcpath = '/tmp/tie-file-hashify-test.rc';

my $io = new IO::File('>' . $rcpath);
ok($io, 'write test-file');

$io->print(<DATA>);
$io->close;

my %rc;
my $ok = tie(
	%rc,
	'Tie::File::Hashify',
	$rcpath,
	parse => sub { $_[0] =~ /^\s*(\S+)\s*=\s*(.*?)\s*$/ },
	format => sub { "$_[0] = $_[1]" }
);

ok($ok, 'tie hash');
ok($rc{foo} eq 'bar', 'fetch foo');
ok($rc{bar} eq 'baz', 'fetch bar');
ok($rc{baz} eq 'qux', 'fetch baz');

ok(($rc{foo} = '123') eq '123', 'store foo');
ok(($rc{new} = 'foo') eq 'foo', 'store new');

ok($rc{foo} eq '123', 'stored foo');
ok($rc{new} eq 'foo', 'stored new');

untie %rc;

$ok = tie(
	%rc,
	'Tie::File::Hashify',
	$rcpath,
	parse => sub { $_[0] =~ /^\s*(\S+)\s*=\s*(.*?)\s*$/ },
);

ok($ok, 'reopen file');

ok($rc{foo} eq '123', 'foo persistent');

ok(exists $rc{new}, 'new exists');
ok($rc{new} eq 'foo', 'new persistent');

my @keys = keys %rc;
ok(@keys == 4, 'keys exist');

while(my ($key, $value) = each %rc) {
	ok($rc{$key} eq $value, "each($key) works");
}

ok(delete($rc{foo}) eq '123', 'delete returns correct value');
ok(!exists($rc{foo}), 'delete removes entry');

untie %rc;

unlink $rcpath;

__DATA__
foo = bar

 bar = baz 
	baz = qux

