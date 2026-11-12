#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;

use Web::VWF::Utils qw(redact_config);

my $config = bless {
	root_dir => '/srv/site',
	security => { csrf => { secret => 'abc' } },
	recaptcha => { site_key => 'pub', secret_key => 'priv' },
	DKIMKey => '/home/site/dkim.private',
	Password => 'x',
	list => [ { api_token => 't', name => 'n' } ],
}, 'Some::Class';

my $copy = redact_config($config);

is(ref($copy), 'HASH', 'the copy is not blessed');
is($copy->{'root_dir'}, '/srv/site', 'ordinary values are kept');
is($copy->{'security'}{'csrf'}{'secret'}, '[REDACTED]', 'a nested secret is redacted');
is($copy->{'recaptcha'}{'secret_key'}, '[REDACTED]', 'secret_key is redacted');
is($copy->{'recaptcha'}{'site_key'}, '[REDACTED]', 'anything with key in its name is redacted');
is($copy->{'DKIMKey'}, '[REDACTED]', 'DKIMKey is redacted');
is($copy->{'Password'}, '[REDACTED]', 'the match ignores case');
is($copy->{'list'}[0]{'api_token'}, '[REDACTED]', 'secrets inside arrays are redacted');
is($copy->{'list'}[0]{'name'}, 'n', 'and the rest of that element is kept');
is($config->{'security'}{'csrf'}{'secret'}, 'abc', 'the original is untouched');
is(ref($config), 'Some::Class', 'and is still blessed');

is(redact_config(undef), undef, 'undef passes through');
is(redact_config('text'), 'text', 'a string passes through');

my $loop = {};
$loop->{'self'} = $loop;
lives_ok { redact_config($loop) } 'a self-referencing configuration does not loop';

done_testing();
