use Test::More tests => 4;

BEGIN {
	use_ok ('WWW::GoodData::Agent');
	use_ok ('WWW::GoodData');
}

require_ok ('WWW::GoodData');
require_ok ('WWW::GoodData::Agent');
