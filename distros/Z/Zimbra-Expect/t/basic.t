use FindBin;

use lib $FindBin::Bin.'/../lib';

use Test::More;

use_ok('Zimbra::Expect::ZmProv');
use_ok('Zimbra::Expect::ZmMailbox');

done_testing();
