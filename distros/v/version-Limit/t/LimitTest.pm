package LimitTest;

use version::Limit;
use version;
use vars qw/$VERSION/;

$VERSION = qv("3.2.5");

version::Limit::Scope(
	"[0.0.0,1.0.0)" => "constructor syntax has changed",
	"[2.2.4,2.3.1)" => "frobniz method croaks without second argument",
);

1;
