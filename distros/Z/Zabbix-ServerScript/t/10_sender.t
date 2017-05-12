use strict;
use warnings;

use Test::More tests => 4;
use Test::Fatal;
use Test::MockModule;
use Data::Dumper;
use JSON;

my $opt = {
	log_filename => q(/tmp/zabbix_server_script_test.log),
	debug => 1,
};

my $socket = Test::MockModule->new(q(IO::Socket::INET));
use Zabbix::ServerScript;
Zabbix::ServerScript::init($opt);

sub test_open_socket {
	my ($host, $port) = @_;
	my %args;
	$socket->mock(
		new => sub {
			my $self = shift;
			%args = @_;
			return;
		},
	);
	my $data = {};
	eval {
		Zabbix::ServerScript::send($data, $host, $port);
	};
	return \%args;
}

subtest q(Test socket opening) => sub {
	my $new_args;
	$new_args = test_open_socket();
	is($new_args->{PeerAddr}, q(localhost), q(Default host is localhost));
	is($new_args->{PeerPort}, 10051, q(Default port is 10051));
	$new_args = test_open_socket(q(127.0.1.1));
	is($new_args->{PeerAddr}, q(127.0.1.1), q(2nd argument sets PeerAddr));
	$new_args = test_open_socket(q(127.0.1.1), 10050);
	is($new_args->{PeerPort}, 10050, q(3rd argument sets PeerPort));
	like( exception { Zabbix::ServerScript::send() }, qr(Cannot open socket), q(Throws an exception if cannot open socket));
};

sub test_valid_json {
	my ($data, $expected_json, $message) = @_;
	my $expected_hashref = decode_json($expected_json);

	my @args;
	$socket->mock(
		write => sub {
			my $self = shift;
			@args = @_;
			return;
		},
	);

	like( exception { Zabbix::ServerScript::send($data) }, qr(Cannot write to socket), q(Throws an exception if cannot write to socket));

	my $got_json = $args[0];
	my $got_hashref;
	ok($got_hashref = decode_json($got_json), q(Writes valid JSON to socket));
	is_deeply($got_hashref, $expected_hashref, $message);
	is($args[1], length($expected_json), q(Writes proper JSON length to socket));
}

subtest q(Test sending data) => sub {
	$socket->mock(
		new => sub {
			return bless {}, q(IO::Socket::INET)
		}
	);
	my $data = {
		host => q(TestHost),
		key => q(test_item),
		value => 1,
	};
	test_valid_json($data, q({"request":"sender data","data":[{"value":1,"key":"test_item","host":"TestHost"}]}), q(Writes proper single item JSON to socket));

	$data = [
		{
			host => q(TestHost),
			key => q(test_item),
			value => 1,
		},
		{
			host => q(TestHost),
			key => q(test_item),
			value => 1,
		},
	];
	test_valid_json($data, q({"request":"sender data","data":[{"value":1,"key":"test_item","host":"TestHost"},{"value":1,"key":"test_item","host":"TestHost"}]}), q(Writes proper multiple items JSON to socket));

	$data = q(Test);
	like( exception { Zabbix::ServerScript::send($data) }, qr(Request is neither arrayref nor hashref), q(Throws an exception if passed data is neither arrayref nor hashref));

	$data = {
		host => q(TestHost),
		key => q(test_item),
		value => \[1],
	};
	ok( exception { Zabbix::ServerScript::send($data) }, q(Throws an exception if cannot encode JSON));
};

subtest q(Test receiving response) => sub {
	$socket->mock(write => 1);
	$socket->mock(close => 1);
	my $read_return_code;
	my $read_return_string;
	$socket->mock(
		read => sub {
			$_[1] = $read_return_string;
			return $read_return_code;
		},
	);

	like( exception { Zabbix::ServerScript::send({}) }, qr(Cannot read from socket), q(Throws an exception if cannot read from socket));

	$read_return_code = 1;
	$read_return_string = q(ZBXDZ{);
	ok( exception { Zabbix::ServerScript::send({}) }, q(Throws an exception if cannot decode JSON));
	$read_return_string = q(ZBXDZ{"response":"success","info":"processed: 1; failed: 0; total: 1; seconds spent: 0.000150"});
	my $expected_result = {
		response => q(success),
		info => q(processed: 1; failed: 0; total: 1; seconds spent: 0.000150),
	};
	is_deeply(Zabbix::ServerScript::send({}), $expected_result, q(Returns proper hashref on success));
};

subtest q(Test receiving response) => sub {
	$socket->mock(read => 1);
	$socket->mock(close => 0);

	like( exception { Zabbix::ServerScript::send({}) }, qr(Cannot close socket), q(Throws an exception if cannot close socket));
};

unlink(q(/tmp/zabbix_server_script_test.log));
done_testing;
