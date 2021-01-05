package ScopedStrict::NonStrictMocker;

use strict;
use warnings;

use Test::MockModule;

Test::MockModule->new('ScopedStrict::Mockee2')->mock(
    also_gonna_mock_this => sub { "another mocked sub" }
);

1;
