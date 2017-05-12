#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('WWW::Authy');

my $authy = WWW::Authy->new('123456');

isa_ok($authy,'WWW::Authy','authy object');

my $request_nu = $authy->new_user_request('em@il','123','12');

isa_ok($request_nu,'HTTP::Request','request new user');
is($request_nu->uri->as_string,'https://api.authy.com/protected/json/users/new?api_key=123456','Checking new user request uri');
is($request_nu->method,'POST','Checking new user request method');
is($request_nu->content,'user%5Bemail%5D=em%40il&user%5Bcellphone%5D=123&user%5Bcountry_code%5D=12','Checking new user request content');

my $request_v = $authy->verify_request(1,123456);

isa_ok($request_v,'HTTP::Request','request verify');
is($request_v->uri->as_string,'https://api.authy.com/protected/json/verify/123456/1?api_key=123456','Checking verify request uri');
is($request_v->method,'GET','Checking verify request method');
is($request_v->content,'','Checking verify request content');

my $request_sms = $authy->sms_request('123');

isa_ok($request_sms,'HTTP::Request','request new user');
is($request_sms->uri->as_string,'https://api.authy.com/protected/json/sms/123?api_key=123456','Checking sms request uri');
is($request_sms->method,'GET','Checking sms request method');
is($request_sms->content,'','Checking sms request content');

my $sandbox_authy = WWW::Authy->new('123456', sandbox => 1);

isa_ok($sandbox_authy,'WWW::Authy','sandbox authy object');

my $sandbox_request_nu = $sandbox_authy->new_user_request('em@il','123','12');

isa_ok($sandbox_request_nu,'HTTP::Request','sandbox request new user');
is($sandbox_request_nu->uri->as_string,'http://sandbox-api.authy.com/protected/json/users/new?api_key=123456','Checking sandbox new user request uri');
is($sandbox_request_nu->method,'POST','Checking sandbox new user request method');
is($sandbox_request_nu->content,'user%5Bemail%5D=em%40il&user%5Bcellphone%5D=123&user%5Bcountry_code%5D=12','Checking sandbox new user request content');

my $sandbox_request_v = $sandbox_authy->verify_request(1,123456);

isa_ok($sandbox_request_v,'HTTP::Request','sandbox request verify');
is($sandbox_request_v->uri->as_string,'http://sandbox-api.authy.com/protected/json/verify/123456/1?api_key=123456','Checking sandbox verify request uri');
is($sandbox_request_v->method,'GET','Checking sandbox verify request method');
is($sandbox_request_v->content,'','Checking sandbox verify request content');

my $sandbox_request_sms = $sandbox_authy->sms_request('123');

isa_ok($sandbox_request_sms,'HTTP::Request','request new user');
is($sandbox_request_sms->uri->as_string,'http://sandbox-api.authy.com/protected/json/sms/123?api_key=123456','Checking sms request uri');
is($sandbox_request_sms->method,'GET','Checking sms request method');
is($sandbox_request_sms->content,'','Checking sms request content');

done_testing;