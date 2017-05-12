#!/usr/bin/perl

use strict; use warnings;
use WebService::Wikimapia;
use Test::More tests => 10;

eval { WebService::Wikimapia->new(); };
like($@, qr/Missing required arguments: api_key/);

eval { WebService::Wikimapia->new({ api_key => 'aabbccd-aabbccdd' }); };
like($@, qr/isa check for "api_key" failed/);

eval
{
    WebService::Wikimapia->new({
        api_key => 'aabbccdd-aabbccdd-aabbccdd-aabbccdd-aabbccdd-aabbccdd-aabbccdd-aabbccdd',
        format  => 'jsson'
    });
};
like($@, qr/isa check for "format" failed/);

eval
{
    WebService::Wikimapia->new(
        api_key => 'aabbccdd-aabbccdd-aabbccdd-aabbccdd-aabbccdd-aabbccdd-aabbccdd-aabbccdd',
        page    => 'a',
    );
};
like($@, qr/isa check for "page" failed/);

eval
{
    WebService::Wikimapia->new(
        api_key => 'aabbccdd-aabbccdd-aabbccdd-aabbccdd-aabbccdd-aabbccdd-aabbccdd-aabbccdd',
        count   => 'a',
    );
};
like($@, qr/isa check for "count" failed/);

eval
{
    WebService::Wikimapia->new(
        api_key => 'aabbccdd-aabbccdd-aabbccdd-aabbccdd-aabbccdd-aabbccdd-aabbccdd-aabbccdd',
        page    => -1,
    );
};
like($@, qr/isa check for "page" failed/);

eval
{
    WebService::Wikimapia->new(
        api_key => 'aabbccdd-aabbccdd-aabbccdd-aabbccdd-aabbccdd-aabbccdd-aabbccdd-aabbccdd',
        count   => -1,
    );
};
like($@, qr/isa check for "count" failed/);

eval
{
    WebService::Wikimapia->new(
        api_key  => 'aabbccdd-aabbccdd-aabbccdd-aabbccdd-aabbccdd-aabbccdd-aabbccdd-aabbccdd',
        language => 'enn',
    );
};
like($@, qr/isa check for "language" failed/);

eval
{
    WebService::Wikimapia->new(
        api_key => 'aabbccdd-aabbccdd-aabbccdd-aabbccdd-aabbccdd-aabbccdd-aabbccdd-aabbccdd',
        pack    => 'noone',
    );
};
like($@, qr/isa check for "pack" failed/);

eval
{
    WebService::Wikimapia->new(
        api_key => 'aabbccdd-aabbccdd-aabbccdd-aabbccdd-aabbccdd-aabbccdd-aabbccdd-aabbccdd',
        disable => 'pollygon',
    );
};
like($@, qr/isa check for "disable" failed/);
