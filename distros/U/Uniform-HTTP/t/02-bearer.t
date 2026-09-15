use strict;
use warnings;
use Test::More;
use lib 'lib';

use Uniform::HTTP::Auth;
use Uniform::HTTP::Auth::Bearer;

my $auth = Uniform::HTTP::Auth->new;
my $challenges = $auth->parse_challenges('Bearer realm="api", scope="read write"');

is scalar(@$challenges), 1, 'one Bearer challenge parsed';
is $challenges->[0]{scheme}, 'bearer', 'Bearer scheme normalized';
is $challenges->[0]{params}{scope}, 'read write', 'Bearer scope preserved';
ok !$challenges->[0]{malformed}, 'Bearer challenge is well formed';

is(Uniform::HTTP::Auth::Bearer->authorization(token => 'mF_9.B5f-4.1JqM'),
    'Bearer mF_9.B5f-4.1JqM', 'Bearer field constructed');

eval { Uniform::HTTP::Auth::Bearer->authorization(token => 'bad token') };
like $@, qr/malformed Bearer token/, 'invalid Bearer token croaks';

done_testing;
