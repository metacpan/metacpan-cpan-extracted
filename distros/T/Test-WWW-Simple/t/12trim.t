use Test::More tests=>3;
use Test::WWW::Simple;

is(Test::WWW::Simple::_trimmed_url("http://this/is/an/insanely/long/url/which/really/should/be/trimmed.txt"), "http://this/is/an/insanely/long/url/whic...");
is(Test::WWW::Simple::_trimmed_url(""),"");
is(Test::WWW::Simple::_trimmed_url("test"),"test");
