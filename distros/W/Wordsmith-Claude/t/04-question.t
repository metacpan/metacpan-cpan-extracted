#!perl
use 5.020;
use strict;
use warnings;
use Test::More;

use Wordsmith::Claude;

# Test that question is exported
can_ok('Wordsmith::Claude', 'question');

# Test import
use Wordsmith::Claude qw(question);
ok(defined &question, 'question can be imported');

# Test that question requires the question argument (async, so need ->get)
eval { Wordsmith::Claude::question()->get };
like($@, qr/requires 'question' argument/, 'dies without question');

done_testing();
