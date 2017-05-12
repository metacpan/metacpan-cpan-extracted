#! perl

BEGIN {
	use English qw(-no_match_vars);
	use warnings;
	use strict;
	use Test::More;
	$OUTPUT_AUTOFLUSH = 1;
}

plan tests => 5;

require WiX3::Traceable;
WiX3::Traceable->new(tracelevel => 0, testing => 1);

require WiX3::XML::RegistryKey;

my $rk_1 = WiX3::XML::RegistryKey->new(id => 'Test', root => 'HKCU', key => 'SOFTWARE', action => 'none');
ok( $rk_1, 'RegistryKey->new returns true' );

my $test2_output = $rk_1->as_string();
my $test2_string = "<RegistryKey Id='RK_Test' Root='HKCU' Key='SOFTWARE' Action='none'>\n\n</RegistryKey>\n";

is( $test2_output, $test2_string, 'RegistryKey stringifies correctly.' );

require WiX3::XML::RegistryValue;

my $rv_1 = WiX3::XML::RegistryValue->new(id => 'Test', key => 'TestKey', action => 'write', type => 'integer', value => 1,);
ok( $rv_1, 'RegistryValue->new returns true' );

my $test4_output = $rv_1->as_string();
my $test4_string = "<RegistryValue Id='RV_Test' Key='TestKey' Action='write' Type='integer' Value='1' />\n";

is( $test4_output, $test4_string, 'RegistryValue stringifies correctly.' );

$rk_1->add_child_tag($rv_1);

my $test5_output = $rk_1->as_string();
is( $test5_output, <<'TEST5_STRING', 'RegistryKey stringifies correctly when it has a child.' );
<RegistryKey Id='RK_Test' Root='HKCU' Key='SOFTWARE' Action='none'>
    <RegistryValue Id='RV_Test' Key='TestKey' Action='write' Type='integer' Value='1' />
</RegistryKey>
TEST5_STRING
