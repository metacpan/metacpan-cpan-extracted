package WebTest;

use Yeb qw( Static );
load 'Static';

r "/" => sub {
	text "root";
};

pr "/post" => sub {
	st post => "test";
}, sub {
	text 'stash post "'.st("post").'"';
};

pr "/postparam" => "%testparam~" => sub {
	st posttestparam => shift;
}, sub {
	text 'paramstash post "'.st("posttestparam").'"';
};

r "/a/..." => sub {
	ex( [qw( x y )], 'export a' );
	st( [qw( y x )] => 'stash a' );
	st [qw( a )] => 'single b a';
	st c => 'single c a';
	chain 'Bla';
};

r "/b/..." => sub {
	ex [qw( x y )] => 'export b';
	st( [qw( y x )] => 'stash b' );
	st( [qw( a )] => 'single a b' );
	st 'c', 'single c b';
	chain 'Bla';
};

r "/other/..." => sub {
	ex other_app => 'other';
	chain '+OtherWebTest';
};

1;