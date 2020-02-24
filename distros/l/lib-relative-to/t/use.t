use strict;
use warnings;

use Test::More;
use Test::Exception;

use lib 'lib';

# just to make sure they don't whinge when 'use'd
use_ok('lib::relative::to::HgRepository');
use_ok('lib::relative::to::GitRepository');
use_ok('lib::relative::to::ParentContaining');
use_ok('lib::relative::to');

# and now try to use something ridiculous
throws_ok {
    lib::relative::to->import('ZZZ::NonExistentPlugin');
} qr/Can't locate/, "non-existent plugins can't be loaded";

done_testing();
