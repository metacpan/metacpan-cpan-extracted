#! perl

use strict;
use warnings;

use File::Temp qw(tempfile);
use lib 'lib';

use Test::More;
use Test::FitNesse::Slim::Server;

my $server = Test::FitNesse::Slim::Server->new;

sub read_framed_file {
  my ($wire) = @_;
  my ($fh) = tempfile();
  binmode $fh;
  print {$fh} $wire or die "write temporary frame: $!";
  seek $fh, 0, 0 or die "rewind temporary frame: $!";
  my $message = $server->_read_message($fh);
  close $fh;
  return $message;
}

is(read_framed_file('000006:hello!'), 'hello!', 'reads a standard six-digit frame');

my $long_payload = 'x' x 1_000_000;
my $long_message = read_framed_file('1000000:' . $long_payload);
is(length($long_message), 1_000_000, 'reads a frame with a seven-digit byte length');
is(substr($long_message, 0, 1), 'x', 'long frame begins with its payload');
is(substr($long_message, -1), 'x', 'long frame contains the complete payload');

my $short = eval { read_framed_file('00001:x'); 1 };
ok(!$short && $@ =~ /invalid message length prefix/,
  'rejects a frame header shorter than six digits');

my $expanded = read_framed_file('0000006:hello!');
is($expanded, 'hello!', 'accepts leading zeroes in an expanded length field');

for my $invalid (
  ['abcdef:', qr/invalid message length prefix/, 'rejects nonnumeric lengths'],
  ['-00001:', qr/invalid message length prefix/, 'rejects negative lengths'],
  ['000001x', qr/invalid message length prefix/, 'rejects a missing colon'],
  ['123', qr/truncated message length/, 'rejects an incomplete prefix'],
  ['999999999999999999999999999999999:', qr/invalid message length prefix/,
    'rejects an excessive prefix without numeric overflow'],
  ['2147483648:', qr/configured maximum/, 'rejects a frame declaration above the limit'],
  ['000020:short', qr/truncated message payload/, 'reports a truncated payload'],
) {
  my($wire,$error,$name) = @$invalid;
  my $ok = eval { read_framed_file($wire); 1 };
  ok(!$ok && $@ =~ $error,$name);
}

is(read_framed_file('000000:'),'','accepts a syntactically valid zero-byte frame');

done_testing;

