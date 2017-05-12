use strict;
use warnings;
use Test::More tests => 6;
use Test::Exception;
use Test::Deep;
use Thrift::IDL;
use FindBin;
use Thrift;

{
	package Thrift::Protocol::Mock;

	use strict;
	use warnings;

	sub new {
		my ($class, %self) = @_;
		return bless \%self, $class;
	}

	sub readMessageBegin {
		my ($self, $method, $type, $seqid) = @_;
		$$method = $self->{method};
		$$type   = $self->{type};
		$$seqid  = $self->{seqid};
	}
	sub readMessageEnd { }

	sub readStructBegin { }
	sub readStructEnd   { }

	sub readFieldBegin {
		my ($self, $name, $type, $id) = @_;
		my $field = shift @{ $self->{fields} };
		$$name = $field->{name};
		$$type = $field->{type};
		$$id   = $field->{id};
	}
	sub readFieldEnd { }

	sub readI32 {
		my ($self, $value) = @_;
		$$value = shift @{ $self->{readI32} };
	}
}

BEGIN {
    use_ok('Thrift::Parser');
};

my $idl = Thrift::IDL->parse_thrift(<<ENDTHRIFT);
namespace perl ServiceTest

service Calculator {
	i32 add (
		1:i32 num1,
		2:i32 num2
	),
}
ENDTHRIFT

# Test some errors

throws_ok {
	Thrift::Parser->new(
		idl     => $idl,
		service => 'MadeUpService',
	)
} qr/not implemented/, "Throw if non-existant service name";

# Create a parser

my $parser = Thrift::Parser->new(
	idl     => $idl,
	service => 'Calculator',
);
isa_ok $parser, 'Thrift::Parser', "Created Calculator parser object";

# Compose a method call, explicitly

my $request = ServiceTest::Calculator::add->compose_message_call(
	num1 => 15,
	num2 => 32,
);
isa_ok $request, 'Thrift::Parser::Message', "Composed message explicitly";

# Compose a reply

my $response = $request->compose_reply(47);
isa_ok $response, 'Thrift::Parser::Message', "Composed method reply";

# Parse a Thrift::Protocol object

my $protocol = Thrift::Protocol::Mock->new(
	method => 'add',
	type   => TMessageType::CALL,
	seqid  => 1,
	fields => [
		{
			id => 1, # num1
			type => TType::I32,
		},
		{
			id => 2, # num2
			type => TType::I32,
		},
		{
			type => TType::STOP,
		}
	],
	readI32 => [ 15, 32 ],
);

my $parsed = $parser->parse_message($protocol);
isa_ok $parsed, 'Thrift::Parser::Message', "Parsed Thrift::Protocol object";

