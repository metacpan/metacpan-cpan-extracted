use Test::More tests=>6;
use Test::Exception;
use WWW::Mechanize::Pluggable;

my $foo = new WWW::Mechanize::Pluggable;

$foo->retry_if(sub{ 1 }, 0); #immediate success
$foo->get("http://www.yahoo.com");
ok $foo->success, "worked";
ok !$foo->retry_failed, "no retry failure";

sub counter_maker {
  my $count = shift;
  sub { !$count-- };
}

$foo->retry_if( counter_maker(2), 3);

$foo->get("http://www.yahoo.com");
ok $foo->success, "worked";
ok !$foo->retry_failed, "no retry failure";

$foo->retry_if( counter_maker(5), 3);

$foo->get("http://www.yahoo.com");
ok $foo->success, "worked";
ok $foo->retry_failed, "retry failure";
