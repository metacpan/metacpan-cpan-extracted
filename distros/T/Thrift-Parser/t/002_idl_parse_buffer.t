use strict;
use warnings;
use Test::More tests => 17;
use Test::Deep;
use FindBin;

BEGIN {
    use_ok('Thrift::IDL');
};

## Parse a buffer

my $idl = Thrift::IDL->parse_thrift(<<ENDTHRIFT);
service Calculator {
	i32 add (
		1:i32 num1,
		2:i32 num2
	),
}
ENDTHRIFT
isa_ok $idl, 'Thrift::IDL::Document';

## Services

my $Calculator = $idl->service_named('Calculator');
isa_ok $Calculator, 'Thrift::IDL::Service';

is $Calculator->name, 'Calculator', 'Service name';
is $Calculator->extends, undef, 'No extend of service';

## Methods

my $method = $Calculator->method_named('add');
isa_ok $method, 'Thrift::IDL::Method';

is $method->name, 'add', 'Method name';
is $method->returns . '', 'i32', 'Method returns';
cmp_deeply $method->throws, [], 'Method throws';
is $method->service . '', $Calculator . '', 'Method service';

## Arguments

my @arguments = @{ $method->arguments };
is int @arguments, 2, "Method argument count";

my $argument = $method->argument_named('num1');
isa_ok $argument, 'Thrift::IDL::Field';
is $method->argument_id(1) . '', $argument . '', 'Method argument_id';

is $argument->optional, undef, 'Field optional';
is $argument->id, 1, 'Field id';
is $argument->name, 'num1', 'Field name';
is $argument->type . '', 'i32', 'Field type (stringified)';
