package WebTest::Bla;

use WebTest;

r "/bla" => sub {
	text ex([qw( x y )])." ".st([qw( y x )])." ".st([qw( a )])." ".st("c")." bla";
};

1;