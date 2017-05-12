#! perl

BEGIN {
	use English qw(-no_match_vars);
	use warnings;
	use strict;
	use Test::More;
	$OUTPUT_AUTOFLUSH = 1;
}

plan tests => 2;

require WiX3::Traceable;
WiX3::Traceable->new(tracelevel => 0, testing => 1);

require WiX3::XML::CreateFolder;

my $cf_1 = WiX3::XML::CreateFolder->new();
ok( $cf_1, 'CreateFolder->new returns true' );

my $test2_output = $cf_1->as_string();
my $test2_string = "<CreateFolder />\n";

is( $test2_output, $test2_string, 'Empty CreateFolder stringifies correctly.' );
