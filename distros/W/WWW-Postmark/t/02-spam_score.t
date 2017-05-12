#!perl -T

use strict;
use warnings;
use Test::More tests => 5;
use WWW::Postmark;

# generate a new object
my $api = WWW::Postmark->new;

ok($api, 'Got a proper WWW::Postmark object');

# start with a test with the 'long' option that should succeed
my $res;
eval {
	$res = $api->spam_score(
		'
MIME-Version: 1.0
Received: by 10.42.4.135 with HTTP; Wed, 14 Sep 2011 13:31:39 -0700 (PDT)
Date: Wed, 14 Sep 2011 23:31:39 +0300
Delivered-To: me@you.com
Message-ID: <BLABLABLABLABLABLABLABLABLABLABLABLA@mail.gmail.com>
Subject: BundleHunt
From: Me And You
To: you@you.com
Content-Type: multipart/alternative; boundary=485b397dcfb5b7a77704aceca5cd

--485b397dcfb5b7a77704aceca5cd
Content-Type: text/plain; charset=UTF-8

http://bundlehunt.com/

--485b397dcfb5b7a77704aceca5cd
Content-Type: text/html; charset=UTF-8

<div dir="ltr"><a href="http://bundlehunt.com/">http://bundlehunt.com/</a><br></div>

--485b397dcfb5b7a77704aceca5cd--'
	)
};

ok($res, 'Request #1 was successful');
ok(ref $res eq 'HASH', 'Received a hash-ref');

# now do the same, but with the 'short' option
undef $res;
eval {
	$res = $api->spam_score(
		'
MIME-Version: 1.0
Received: by 10.42.4.135 with HTTP; Wed, 14 Sep 2011 13:31:39 -0700 (PDT)
Date: Wed, 14 Sep 2011 23:31:39 +0300
Delivered-To: me@you.com
Message-ID: <BLABLABLABLABLABLABLABLABLABLABLABLA@mail.gmail.com>
Subject: BundleHunt
From: Me And You
To: you@you.com
Content-Type: multipart/alternative; boundary=485b397dcfb5b7a77704aceca5cd

--485b397dcfb5b7a77704aceca5cd
Content-Type: text/plain; charset=UTF-8

http://bundlehunt.com/

--485b397dcfb5b7a77704aceca5cd
Content-Type: text/html; charset=UTF-8

<div dir="ltr"><a href="http://bundlehunt.com/">http://bundlehunt.com/</a><br></div>

--485b397dcfb5b7a77704aceca5cd--',
		'short'
	)
};
ok($res, 'Request #2 was successful');
ok(!ref $res, 'Received just the spam score');

done_testing();
