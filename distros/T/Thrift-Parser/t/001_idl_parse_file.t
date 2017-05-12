use strict;
use warnings;
use Test::More tests => 29;
use Test::Deep;
use FindBin;

BEGIN {
    use_ok('Thrift::IDL');
};

## Parse files from the file system

my $idl = Thrift::IDL->parse_thrift_file($FindBin::Bin . '/thrift/tutorial.thrift');
isa_ok $idl, 'Thrift::IDL::Document';

## Services

my @services = @{ $idl->services };
is int @services, 2, "Found two services";

my $Calculator = $idl->service_named('Calculator');
isa_ok $Calculator, 'Thrift::IDL::Service';

is $Calculator->name, 'Calculator', 'Service name';
is $Calculator->extends, 'shared.SharedService', 'Service extends';

## Methods

my @methods = @{ $Calculator->methods };
is int @methods, 5, "Found 5 calculator methods"; # 'testVars', 'ping', 'add', 'calculate', 'zip'

my $testVars = $Calculator->method_named('testVars');
isa_ok $testVars, 'Thrift::IDL::Method';

is $testVars->name, 'testVars', 'Method name';
is $testVars->oneway, undef, 'Method oneway';
is $testVars->returns . '', 'void', 'Method returns';
cmp_deeply $testVars->throws, [], 'Method throws';
is $testVars->service . '', $Calculator . '', 'Method service';

## Arguments

my @arguments = @{ $testVars->arguments };
is int @arguments, 5, "Method arguments are five";

my $stringList = $testVars->argument_named('stringList');
isa_ok $stringList, 'Thrift::IDL::Field';
is $testVars->argument_id(1) . '', $stringList . '', 'Method argument_id';

is $stringList->optional, undef, 'Field optional';
is $stringList->id, 1, 'Field id';
is $stringList->name, 'stringList', 'Field name';
is $stringList->type . '', 'list (string)', 'Field type (stringified)';

## Types

my $type = $stringList->type;
isa_ok $type, 'Thrift::IDL::Type::List';

is $type->val_type . '', 'string', 'Type val_type (stringified)';
isa_ok $type->val_type, 'Thrift::IDL::Type';

my $workList = $testVars->argument_named('workList');
isa_ok $workList, 'Thrift::IDL::Field';

$type = $workList->type;
isa_ok $type, 'Thrift::IDL::Type::Custom';

## Comments

my $zip = $Calculator->method_named('zip');
isa_ok $zip, 'Thrift::IDL::Method';

my @comments = @{ $zip->comments };
is int @comments, 1, "Found one comment";

my $comment = $comments[0];
isa_ok $comment, 'Thrift::IDL::Comment';

is $comment->escaped_value, "*
    * This method has a oneway modifier. That means the client only makes
    * a request and does not listen for any response at all. Oneway methods
    * must be void.", 'Comment multi-line value';
