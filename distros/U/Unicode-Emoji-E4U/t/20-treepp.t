use strict;
use warnings;
use Test::More;

plan tests => 8;

use Unicode::Emoji::E4U;

my $e4u = Unicode::Emoji::E4U->new;

ok( ref $e4u, 'e4u' );
isnt( $e4u->datadir, '', 'datadir' );
ok( ref $e4u->treepp, 'treepp' );

my $ua = 'Mozilla/4.0 (compatible; ...)';
$e4u->treepp->set(user_agent => $ua);
my $ub = $e4u->treepp->get('user_agent');

is( $ub, $ua, 'set/get user_agent' );

# check copied
is( $e4u->docomo->treepp->get('user_agent'), $ua, 'docomo' );
is( $e4u->kddi->treepp->get('user_agent'), $ua, 'kddi' );
is( $e4u->softbank->treepp->get('user_agent'), $ua, 'softbank' );
is( $e4u->google->treepp->get('user_agent'), $ua, 'google' );
