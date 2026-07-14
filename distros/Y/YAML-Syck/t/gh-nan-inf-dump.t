use strict;
use warnings;
use Test::More;
use YAML::Syck;

plan tests => 12;

local $YAML::Syck::ImplicitTyping = 1;

my $nan  = YAML::Syck::Load("--- .nan\n");
my $inf  = YAML::Syck::Load("--- .inf\n");
my $ninf = YAML::Syck::Load("--- -.inf\n");

ok($nan != $nan,      'loaded .nan is NaN');
ok($inf == 9**9**9,   'loaded .inf is Inf');
ok($ninf == -(9**9**9), 'loaded -.inf is -Inf');

my $nan_dump  = YAML::Syck::Dump($nan);
my $inf_dump  = YAML::Syck::Dump($inf);
my $ninf_dump = YAML::Syck::Dump($ninf);

like($nan_dump,  qr/^--- \.nan\s*$/m,  'Dump NaN produces .nan');
like($inf_dump,  qr/^--- \.inf\s*$/m,  'Dump Inf produces .inf');
like($ninf_dump, qr/^--- -\.inf\s*$/m, 'Dump -Inf produces -.inf');

my $nan2  = YAML::Syck::Load($nan_dump);
my $inf2  = YAML::Syck::Load($inf_dump);
my $ninf2 = YAML::Syck::Load($ninf_dump);

ok($nan2 != $nan2,        'NaN roundtrips through Dump/Load');
ok($inf2 == 9**9**9,      'Inf roundtrips through Dump/Load');
ok($ninf2 == -(9**9**9),  '-Inf roundtrips through Dump/Load');

my $list = YAML::Syck::Load("---\n- .nan\n- .inf\n- -.inf\n");
my $list_dump = YAML::Syck::Dump($list);

like($list_dump, qr/- \.nan/,  'NaN in list uses .nan');
like($list_dump, qr/- \.inf/,  'Inf in list uses .inf');
like($list_dump, qr/- -\.inf/, '-Inf in list uses -.inf');
