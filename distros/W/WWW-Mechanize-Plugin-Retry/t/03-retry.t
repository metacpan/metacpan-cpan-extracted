use Test::More tests=>2;
use Test::Exception;
use WWW::Mechanize::Pluggable;

my $foo = new WWW::Mechanize::Pluggable;

$foo->retry(1); #immediate success
$foo->get("http://www.yahoo.com");
ok $foo->success, "worked";
ok !$foo->retry_failed, "no retry failure";
