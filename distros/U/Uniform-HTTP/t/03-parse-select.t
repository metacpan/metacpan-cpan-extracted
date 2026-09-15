use strict;
use warnings;
use Test::More;
use lib 'lib';

use Uniform::HTTP::Auth;

my $auth = Uniform::HTTP::Auth->new(
    schemes => [qw(digest bearer basic)],
);

my $parsed = $auth->parse_challenges(
    'Digest realm="Members", qop="auth,auth-int", algorithm=SHA-256, nonce="abc", Basic realm="Members"',
    'Widget abc.def==',
);

is scalar(@$parsed), 3, 'multiple challenges parsed in wire order';
is_deeply [ map { $_->{scheme} } @$parsed ],
    [qw(digest basic widget)], 'challenge schemes discovered';
is $parsed->[0]{params}{qop}, 'auth,auth-int', 'comma inside quoted parameter preserved';
is $parsed->[2]{token68}, 'abc.def==', 'unknown token68 scheme preserved';
ok !$parsed->[2]{malformed}, 'unknown scheme is not malformed';

my $selected = $auth->select($parsed);
is $selected->{scheme}, 'digest', 'preferred supported scheme selected';

my $dupe = $auth->parse_challenges('Digest realm="a", realm="b", nonce="n", qop="auth"');
ok $dupe->[0]{malformed}, 'duplicate auth parameter is malformed';
like $dupe->[0]{error}, qr/duplicate/, 'duplicate error retained';

my $garbage = $auth->parse_challenges('@@@');
ok $garbage->[0]{malformed}, 'garbage represented as malformed data';

done_testing;
