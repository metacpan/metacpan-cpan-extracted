#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use WWW::OpenBao;

my $bao = WWW::OpenBao->new(
  endpoint => 'http://vault:8200',
  token    => 'test-token',
);

ok  $bao,                                 'constructor';
is  $bao->endpoint, 'http://vault:8200',  'endpoint';
is  $bao->token,    'test-token',         'token';
is  $bao->kv_mount, 'secret',             'default kv_mount';

is $bao->_kv_path('foo/bar'),
   'v1/secret/data/foo/bar',              'kv data path';
is $bao->_kv_metadata_path('foo/bar'),
   'v1/secret/metadata/foo/bar',          'kv metadata path';

$bao->token('new-token');
is $bao->token, 'new-token',              'token is writable (login flows)';

my $bao2 = WWW::OpenBao->new(
  endpoint => 'http://vault:8200',
  kv_mount => 'goldmine',
);
is $bao2->_kv_path('a/b'),
   'v1/goldmine/data/a/b',                'custom kv_mount honoured';

done_testing;
