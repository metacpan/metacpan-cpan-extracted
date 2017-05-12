#! perl

BEGIN {
	use English qw(-no_match_vars);
	use warnings;
	use strict;
	use Test::More;
	$OUTPUT_AUTOFLUSH = 1;
}

plan tests => 16;

require WiX3::Traceable;
WiX3::Traceable->new(tracelevel => 0, testing => 1);

require WiX3::XML::GeneratesGUID::Object;
WiX3::XML::GeneratesGUID::Object->new(sitename => 'www.testing.invalid');

require WiX3::XML::Component;

my $c_1;
eval { $c_1 = WiX3::XML::Component->new(); };
my $empty_exception = $EVAL_ERROR;

ok( ! $c_1, 'CreateFolder->new returns false when empty' );
like( 
	$empty_exception, 
	qr{\sParameter\s}, 
	'CreateFolder->new returns exception that stringifies'
);
isa_ok( $empty_exception, 'WiX3::Exception::Parameter', 'Error' );
isa_ok( $empty_exception, 'WiX3::Exception', 'Error' );

my $c_2 = WiX3::XML::Component->new(id => 'TestID');

ok( $c_2, 'Component->new returns true with id' );
isa_ok( $c_2, 'WiX3::XML::Component' );

my $test7_output = $c_2->as_string();
my $test7_string = "<Component Id='C_TestID' Guid='94029F5F-EFBF-39A5-AA11-DC6570C7FF48' />\n";

is( $test7_output, $test7_string, 'Empty Component stringifies correctly.' );

require WiX3::XML::CreateFolder;

my $cf_1 = WiX3::XML::CreateFolder->new();
$c_2->add_child_tag($cf_1);

my $test8_output = $c_2->as_string();
my $test8_string = <<'EOF';
<Component Id='C_TestID' Guid='94029F5F-EFBF-39A5-AA11-DC6570C7FF48'>
  <CreateFolder />
</Component>
EOF

is( $test8_output, $test8_string, 'Non-empty Component stringifies correctly.' );

require WiX3::XML::ComponentRef;

my $cr_1 = WiX3::XML::ComponentRef->new($c_2);

ok( $cr_1, 'ComponentRef->new returns true with Component' );

my $test10_output = $cr_1->as_string();
my $test10_string = <<'EOF';
<ComponentRef Id='C_TestID' />
EOF

is( $test10_output, $test10_string, 'Component ComponentRef stringifies correctly.' );

my $cr_2 = WiX3::XML::ComponentRef->new(id => $c_2->get_id(), primary => 'yes');

ok( $cr_2, 'ComponentRef->new returns true with regular parameters' );

my $test12_output = $cr_2->as_string();
my $test12_string = <<'EOF';
<ComponentRef Id='C_TestID' Primary='yes' />
EOF

is( $test12_output, $test12_string, 'Hash ComponentRef stringifies correctly.' );

my $cr_3 = WiX3::XML::ComponentRef->new({id => $c_2->get_id(), primary => 'yes'});

ok( $cr_3, 'ComponentRef->new returns true with hashref parameters' );

my $test14_output = $cr_3->as_string();
my $test14_string = $test12_string;

is( $test14_output, $test14_string, 'Hashref ComponentRef stringifies correctly.' );

my $cr_4 = WiX3::XML::ComponentRef->new($c_2->get_id());

ok( $cr_4, 'ComponentRef->new returns true with string id parameter' );

my $test16_output = $cr_4->as_string();
my $test16_string = $test10_string;

is( $test16_output, $test16_string, 'String-id ComponentRef stringifies correctly.' );
