use Test::More tests=>8;
use Test::Exception;
use WWW::Mechanize::Pluggable;

my $foo = new WWW::Mechanize::Pluggable;
can_ok $foo,qw(retry retry_if _retry_check_sub _delays _delay_index retry_failed);

is $foo->retry_failed(), undef, "no default failure state";

is $foo->retry_if(), undef, "no sub by default";
lives_ok { $foo->retry_if(sub{}) } "no times supplied";

lives_ok { $foo->retry_if( sub {}, 0) } "good call";

is $foo->retry_failed(), 0, "default failure state";

$foo->retry_failed(1);
is $foo->retry_failed, 1, "retry_wait set/get";

$foo->retry_failed(0);
is $foo->retry_failed, 0, "retry_wait set/get";
