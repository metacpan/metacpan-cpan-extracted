package ScopedStrict::StrictMocker;

use strict;
use warnings;

use Test::MockModule qw(strict);

Test::MockModule->new('ScopedStrict::Mockee1')->redefine(
    gonna_mock_this => sub { "mocked sub" }
);

1;
