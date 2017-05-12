#!perl -T

use Test::More;
eval "use Test::Pod::Coverage 1.04";
if ($@) {
	plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage";
} else {
	plan tests => 1;
}
pod_coverage_ok( 
	"Win32::GUIRobot", 
	{ also_private => [qr/^Send.Button(Down|Up)$/] } 
);
