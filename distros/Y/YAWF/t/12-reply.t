#!/usr/bin/perl

use 5.006;
use strict;
use warnings;
use Test::More tests => 23;

use_ok( 'YAWF::Reply' );

my $reply = YAWF::Reply->new(yawf => 'foo');

ok(defined($reply),'Create reply object');
is($reply->yawf,'foo','Check YAWF reference');

# Check some default structures
is(ref($reply->headers),'HASH','Header structure');
is(ref($reply->data),'HASH','Data structure');

# Check header defaults
is($reply->headers->{Status},200,'Header: default status code');
is($reply->headers->{'Content-type'},'text/html','Header: default content type');

# Check data defaults
is($reply->data->{yawf},'foo','Data: YAWF reference');

# Add header
ok($reply->header('foo','bar'),'Add one header');
is($reply->headers->{foo},'bar','Check header');
ok($reply->header('multifoo','bar1'),'Add second header');
ok($reply->header('multifoo','bar2'),'Add second line to header');
ok($reply->header('multifoo','bar3'),'Add third line to header');
is(ref($reply->headers->{multifoo}),'ARRAY','Check second header type');
is($reply->headers->{multifoo}->[0],'bar1','Check second header value 1');
is($reply->headers->{multifoo}->[1],'bar2','Check second header value 2');
is($reply->headers->{multifoo}->[2],'bar3','Check second header value 3');
is($#{$reply->headers->{multifoo}},2,'Check second header value count');

# Cookies
ok($reply->cookie(                -name    => 'foocookie',
                -value   => 'chocolate',
                -expires => '+365d',
                -path    => '/'),'Create cookie 1'
);
like($reply->headers->{'Set-Cookie'},qr/foocookie\=chocolate/,'Check cookie 1');
ok($reply->cookie(                -name    => 'foocookie',
                -value   => 'nuts',
                -expires => '+365d',
                -path    => '/'),'Create cookie 2'
);
like($reply->headers->{'Set-Cookie'}->[0],qr/foocookie\=chocolate/,'Check cookie 1');
like($reply->headers->{'Set-Cookie'}->[1],qr/foocookie\=nuts/,'Check cookie 2');
