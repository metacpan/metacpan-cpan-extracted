use Test::More;
use Modern::Perl;
use Util::Medley::Cache;
use Data::Printer alias => 'pdump';

$SIG{__WARN__} = sub { die @_ };

#
# constructor
#

my $cache = Util::Medley::Cache->new;
ok($cache);

#
# verify a normal set/get/delete
#

$cache->set(
	ns   => 'unittest',
	key  => 'a',
	data => { foo => 'bar' }
);

my $data = $cache->get(
	ns  => 'unittest',
	key => 'a'
);

ok($data);
ok( ref $data eq 'HASH' );

$cache->delete(
	ns  => 'unittest',
	key => 'a'
);

#
# verify expire_epoch
#

$cache->set(
	ns           => 'unittest',
	key          => 'a',
	data         => { foo => 'bar' },
	expire_epoch => time + 1
);

sleep 2;

$data = $cache->get(
	ns  => 'unittest',
	key => 'a'
);

ok( !defined $data );

done_testing();
