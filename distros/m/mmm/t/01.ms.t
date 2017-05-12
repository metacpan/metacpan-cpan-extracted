use strict;
use warnings;

use Test::More tests => 3;

use_ok('MMM::Sync');
use_ok('MMM::Sync::Rsync');

like(
    ref MMM::Sync->new(url => 'rsync://host/share'),
    '/MMM::Sync/',
    'can get a MMM::Sync object'
);
