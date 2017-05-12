#!perl -T

use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
    use_ok 'WebService::XING';
}

my $xing;
my @ARGS = (key => 'TEST-KEY', secret => 'S3CR3T');

dies_ok { $xing = WebService::XING->new } 'missing required attributes';

$xing = WebService::XING->new(@ARGS);

isa_ok $xing, 'WebService::XING';
is $xing->base_url, 'https://api.xing.com', 'default base_url';
is $xing->request_token_resource, '/v1/request_token',
   'default request_token_resource';
is $xing->authorize_resource, '/v1/authorize',
   'default authorize_resource';
is $xing->access_token_resource, '/v1/access_token',
   'default access_token_resource';
is $xing->user_agent, "WebService::XING/$WebService::XING::VERSION (Perl)",
   'user agent id';
is $xing->key, 'TEST-KEY', 'consumer key';
is $xing->secret, 'S3CR3T', 'consumer secret';

ok !defined $xing->access_token, 'has no access token';
ok !defined $xing->access_secret, 'has no access secret';
ok !defined $xing->user_id, 'has no user_id';

is_deeply [$xing->access_credentials], [undef, undef, undef], 'no access credentials';

$xing->access_credentials('A-Side', 'B-side', 45);

is $xing->access_token, 'A-Side', 'has an access token';
is $xing->access_secret, 'B-side', 'has an access secret';
is $xing->user_id, 45, 'has a user_id';

is_deeply [$xing->access_credentials], ['A-Side', 'B-side', 45], 'has access credentials';

is(WebService::XING->new(@ARGS, warn => sub { shift() x 2 })->warn->('Bunga'),
   'BungaBunga', 'custom warn method');

test_functions_array(WebService::XING::functions());
test_functions_array(WebService::XING->functions());
test_functions_array($xing->functions());

my $f = WebService::XING::function('create_activity_like');
isa_ok $f, 'WebService::XING::Function', 'WebService::XING::function("create_activity_like")';
$f = WebService::XING->function('create_bookmark');
isa_ok $f, 'WebService::XING::Function', 'WebService::XING->function("create_bookmark")';
$f = $xing->function('get_network_feed');
isa_ok $f, 'WebService::XING::Function', '$xing->function("get_network_feed")';

my $fp = $f->params;

isa_ok $fp, 'ARRAY', 'function parameter list';

for (@$fp) {
    isa_ok $_, 'WebService::XING::Function::Parameter', "function parameter $_";
}

is_deeply $fp, [qw(user_id aggregate since until user_fields)],
    'parameter list elements stringify';

is $fp->[0]->name, 'user_id', 'name of param user_id';
ok $fp->[0]->is_required, 'param user_id is required';
ok $fp->[0]->is_placeholder, 'param user_id is placeholder';
ok !$fp->[0]->is_boolean, 'param user_id is not a boolean';
ok !$fp->[0]->is_list, 'param user_id is not a list';
ok !defined $fp->[0]->default, 'param user_id has no default';

is $fp->[1]->name, 'aggregate', 'name of param aggregate';
ok !$fp->[1]->is_required, 'param aggregate is not required';
ok !$fp->[1]->is_placeholder, 'param aggregate is not a placeholder';
ok $fp->[1]->is_boolean, 'param aggregate is a boolean';
ok !$fp->[1]->is_list, 'param aggregate is not a list';
is $fp->[1]->default, 1, 'param aggregate default == 1';

is $fp->[2]->name, 'since', 'name of param since';
ok !$fp->[2]->is_required, 'param since is not required';
ok !$fp->[2]->is_placeholder, 'param since is not a placeholder';
ok !$fp->[2]->is_boolean, 'param since is not a boolean';
ok !$fp->[2]->is_list, 'param since is not a list';
ok !defined $fp->[2]->default, 'param since has no default';

is $fp->[3]->name, 'until', 'name of param until';
ok !$fp->[3]->is_required, 'param until is not required';
ok !$fp->[3]->is_placeholder, 'param until is not a placeholder';
ok !$fp->[3]->is_boolean, 'param until is not a boolean';
ok !$fp->[3]->is_list, 'param until is not a list';
ok !defined $fp->[3]->default, 'param until has no default';

is $fp->[4]->name, 'user_fields', 'name of param user_fields';
ok !$fp->[4]->is_required, 'param user_fields is not required';
ok !$fp->[4]->is_placeholder, 'param user_fields is not a placeholder';
ok !$fp->[4]->is_boolean, 'param user_fields is not a boolean';
ok $fp->[4]->is_list, 'param user_fields is a list';
ok !defined $fp->[4]->default, 'param user_fields has no default';

isa_ok $f->code, 'CODE', 'function code';
my $code;

ok $code = $xing->can('login'), 'xing can login';
isa_ok $code, 'CODE', 'can("login")';

ok !($code = $xing->can('get_a_life')), 'xing can not get_a_life';

ok $code = $xing->can('get_user_details'), 'xing can get_user_details';

isa_ok $code, 'CODE', 'can("get_user_details")';

my $nonce1 = WebService::XING::nonce;
my $nonce2 = $xing->nonce;
my $nonce3 = $xing->nonce;
like $nonce1, qr/^[\d[A-Za-z\/\+]{27}$/, 'a nonce';
like $nonce2, qr/^[\d[A-Za-z\/\+]{27}$/, 'another nonce';
like $nonce3, qr/^[\d[A-Za-z\/\+]{27}$/, 'yet another nonce';
isnt $nonce1, $nonce2, '1st and 2nd nonce are not equal';
isnt $nonce1, $nonce3, '1st and 3rd nonce are not equal';
isnt $nonce2, $nonce3, '2nd and 3rd nonce are not equal';

done_testing;


sub test_functions_array {
    my $functions = shift;

    isa_ok $functions, 'ARRAY', '$functions';
    ok @$functions > 30, 'functions list has more than 30 elements';
    ok((grep { $_ eq 'list_incoming_contact_requests' } @$functions),
       'functions list contains list_incoming_contact_requests');
}

