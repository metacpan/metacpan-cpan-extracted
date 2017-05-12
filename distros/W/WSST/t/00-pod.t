use strict;
use Test::More;

my $FILES = [qw(
lib/WSST.pm
lib/WSST/Schema.pm
lib/WSST/Schema/Base.pm
lib/WSST/Schema/Data.pm
lib/WSST/Schema/Method.pm
lib/WSST/Schema/Param.pm
lib/WSST/Schema/Node.pm
lib/WSST/Schema/Return.pm
lib/WSST/Schema/Error.pm
lib/WSST/Schema/Test.pm
lib/WSST/SchemaParser.pm
lib/WSST/SchemaParser/YAML.pm
lib/WSST/SchemaParserManager.pm
lib/WSST/Generator.pm
lib/WSST/CodeTemplate.pm
)];
local $@;
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
all_pod_files_ok( @$FILES );
;1;
