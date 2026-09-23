use strict;
use warnings;
use Test::More;
use lib 'lib';
use WebService::TypeSafe qw(choice noul score retry_policy);

is(choice(instructions => 'Pick', criteria => { a => undef, b => 'B' })->type, 'choice');
is(noul(instructions => 'True?')->type, 'noul');
is(score(instructions => 'Rate', criteria => [qw(low high)])->type, 'score');
is(retry_policy(max_retries => 0)->max_retries, 0);

eval { score(criteria => ['only one']) };
like "$@", qr/2 to 10 levels/, 'score validates level count';
eval { choice(criteria => {}) };
like "$@", qr/nonempty hash/, 'choice validates criteria';

done_testing;
