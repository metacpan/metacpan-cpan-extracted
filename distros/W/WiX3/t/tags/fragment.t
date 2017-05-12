#! perl

BEGIN {
	use English qw(-no_match_vars);
	use warnings;
	use strict;
	use Test::More;
	$OUTPUT_AUTOFLUSH = 1;
}

plan tests => 3;

require WiX3::Traceable;
WiX3::Traceable->new(tracelevel => 0, testing => 1);

require WiX3::XML::CreateFolder;
require WiX3::XML::Fragment;

my $frag = WiX3::XML::Fragment->new(id => 'TestID');

ok( $frag, 'Fragment->new returns true' );

my $test2_string = <<'EOF';
<?xml version='1.0' encoding='windows-1252'?>
<Wix xmlns='http://schemas.microsoft.com/wix/2006/wi'>
  <Fragment Id='Fr_TestID'>

  </Fragment>
</Wix>
EOF

is( $frag->as_string(), $test2_string, 'Empty Fragment stringifies correctly.' );

$frag->add_child_tag(WiX3::XML::CreateFolder->new());

my $test3_string = <<'EOF';
<?xml version='1.0' encoding='windows-1252'?>
<Wix xmlns='http://schemas.microsoft.com/wix/2006/wi'>
  <Fragment Id='Fr_TestID'>
    <CreateFolder />
  </Fragment>
</Wix>
EOF

is( $frag->as_string(), $test3_string, 'Fragment stringifies correctly.' );
