use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok('UID2::Client::XS');
    use_ok('UID2::Client::XS::DecryptionStatus');
    use_ok('UID2::Client::XS::EncryptionStatus');
    use_ok('UID2::Client::XS::IdentityScope');
    use_ok('UID2::Client::XS::IdentityType');
    use_ok('UID2::Client::XS::Timestamp');
};

done_testing;
