use strict;
use Test::More 0.98;

use_ok $_ for qw(
    UID2::Client
    UID2::Client::Encryption
    UID2::Client::Key
    UID2::Client::KeyContainer
    UID2::Client::DecryptionStatus
    UID2::Client::EncryptionStatus
    UID2::Client::IdentityScope
    UID2::Client::IdentityType
    UID2::Client::Timestamp
);

done_testing;
