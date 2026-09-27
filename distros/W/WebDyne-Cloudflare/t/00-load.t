use 5.020;
use strict;
use warnings;
use Test::More;

use_ok('WebDyne::Cloudflare');
use_ok('WebDyne::Cloudflare::D1');
use_ok('WebDyne::Cloudflare::D1::Statement');
use_ok('WebDyne::Cloudflare::D1::Blob');
use_ok('WebDyne::Cloudflare::D1::Error');
use_ok('WebDyne::Cloudflare::SecretsStore');
use_ok('WebDyne::Cloudflare::SecretsStore::Error');
use_ok('WebDyne::Cloudflare::KV');
use_ok('WebDyne::Cloudflare::KV::Blob');
use_ok('WebDyne::Cloudflare::KV::Error');
use_ok('WebDyne::Cloudflare::R2');
use_ok('WebDyne::Cloudflare::R2::Blob');
use_ok('WebDyne::Cloudflare::R2::Error');
use_ok('WebDyne::Cloudflare::R2::Object');

done_testing();
