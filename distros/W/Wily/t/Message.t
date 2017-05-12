# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Wily.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 9;
BEGIN { use_ok('Wily::Message') };

my @samples = ( [ [8, 1234, 0, 100, 1, '', 4321], 
		"\xfe\xed\x00\x08\x00\x00\x00\x17\x10\xe1\x04\xd2" .
		"\x00\x00\x00\x00\x00\x00\x00\x64\x00\x01\x00"
		], 
		[ [8, 1234, 0, 100, 1, 'with a string', 4321],
		"\xfe\xed\x00\x08\x00\x00\x00\x24\x10\xe1\x04\xd2" .
		"\x00\x00\x00\x00\x00\x00\x00\x64\x00\x01with a string\x00"
		], 
);

sub msg_compare {
	my $msg = shift;
	return $msg->{type} == $_[0] and
		$msg->{window_id} == $_[1] and
		$msg->{p0} == $_[2] and
		$msg->{p1} == $_[3] and
		$msg->{flag} == $_[4] and
		$msg->{s} eq $_[5] and 
		(not(defined $_[6]) or $msg->{message_id} == $_[6]);
}


my $msg;
my $s;
$msg = Wily::Message->new(Wily::Message::WEexec);
ok(msg_compare($msg, Wily::Message::WEexec, 0, 0, 0, 0, ''), 'new() with defaults');

$msg = Wily::Message->new(Wily::Message::WEgoto, 12, 23, 45, 1, ':,');
ok(msg_compare($msg, Wily::Message::WEgoto, 12, 23, 45, 1, ':,'), 'new() with args');

for $s (@samples) {
	$msg = Wily::Message->new(@{$s->[0]});
	$msg->{message_id} = $s->[0][6];
	ok($msg->size() == length($s->[1]), 'size()');
}

for $s (@samples) {
	$msg = Wily::Message->new(@{$s->[0]});
	$msg->{message_id} = $s->[0][6];
	ok($msg->flatten() eq $s->[1], 'flatten()');
}

for $s (@samples) {
	$msg = Wily::Message->new(0);
	$msg->from_string($s->[1]);
	ok(msg_compare($msg, @{$s->[0]}), 'from_string()');
}

