use strict;
use warnings;
use Test::More;
use Text::KDL::XS qw(parse_kdl);

# KDL v2 syntax (default modern KDL). Booleans/null use the '#' prefix.
my $doc = parse_kdl(<<'KDL', version => '2');
nums 42 -7 3.14 (u32)9000 1e2
big 12345678901234567890123456789
flags #true #false #null
str "hi"
KDL

my @nodes = @{ $doc->nodes };

# nums
my @args = @{ $nodes[0]->args };
ok $args[0]->is_number,        'arg0 is number';
is $args[0]->kind,    'integer','arg0 kind';
is $args[0]->as_perl, 42,       'arg0 value';

is $args[1]->as_perl, -7, 'negative integer';
ok $args[2]->is_number && $args[2]->kind eq 'float', 'float kind';
cmp_ok abs($args[2]->as_perl - 3.14), '<', 1e-9, 'float value';

is $args[3]->type_annotation, 'u32', 'type annotation preserved';
is $args[3]->as_perl, 9000, 'annotated value';

ok $args[4]->is_number, 'arg4 is number';

# big - preserved as string-encoded
my $big = $nodes[1]->args->[0];
ok $big->is_number, 'big is number';
is $big->kind, 'string', 'arbitrary-precision kind';
is $big->as_string, '12345678901234567890123456789', 'big value preserved verbatim';

# flags
my @bools = @{ $nodes[2]->args };
ok $bools[0]->is_bool && $bools[0]->as_perl,  'true';
ok $bools[1]->is_bool && !$bools[1]->as_perl, 'false';
ok $bools[2]->is_null,                         'null';

# strings
is $nodes[3]->args->[0]->as_string, 'hi', 'normal string';

done_testing;
