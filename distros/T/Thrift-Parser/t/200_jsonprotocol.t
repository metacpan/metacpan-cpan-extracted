use strict;
use warnings;
use Test::More tests => 1;
use Test::Exception;
use Test::Deep;
use FindBin;

use Thrift::IDL;
use Thrift::Parser;

use Thrift;
use Thrift::MemoryBuffer;
use Thrift::BinaryProtocol;
use Thrift::JSONProtocol;

my $idl = Thrift::IDL->parse_thrift(<<ENDTHRIFT);
namespace perl ServiceTest

service Calculator {
	i32 add (
		1:i32 num1,
		2:i32 num2
	),
}
ENDTHRIFT

my $parser = Thrift::Parser->new(
	idl     => $idl,
	service => 'Calculator',
);

# Compose a method call, explicitly

my $request = ServiceTest::Calculator::add->compose_message_call(
	num1 => 15,
	num2 => 32,
);
$request->seqid(1);

my $buffer = Thrift::MemoryBuffer->new();
my $protocol = Thrift::JSONProtocol->new($buffer);

$request->write($protocol);

is $protocol->getTransport->getBuffer, '[1,"add",1,1,{"1":{"i32":15},"2":{"i32":32}}]', "JSONProtocol generated the expected output";

1;
