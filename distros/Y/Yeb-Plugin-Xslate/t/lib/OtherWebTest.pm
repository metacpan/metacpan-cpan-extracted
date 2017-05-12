package OtherWebTest;

use Yeb;

r "/" => sub {
	text "other root";
};

r "/a" => sub {
	text "other a";
};

r "/other" => sub {
	text "other and ".ex('other_app');
};

1;