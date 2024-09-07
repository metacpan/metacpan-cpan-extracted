use Test::More;
use Zleep qw/zleep/;

my $thing = 'abc';

zleep(sub {
	print "me after $thing\n";
}, 500);

print "me first\n";

ok(1);

done_testing();

1;
