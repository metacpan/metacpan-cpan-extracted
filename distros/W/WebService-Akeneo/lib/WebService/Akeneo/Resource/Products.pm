package WebService::Akeneo::Resource::Products;
$WebService::Akeneo::Resource::Products::VERSION = '0.001';
use v5.38;
use Object::Pad;

class WebService::Akeneo::Resource::Products 0.001;

field $t :param;
field $paginator;

BUILD { $paginator = WebService::Akeneo::Paginator->new( transport => $t ) }

method get ($code)                { $t->request('GET',   "/products/$code") }
method upsert ($code, $payload)   { $t->request('PATCH', "/products/$code", json   => $payload) }
method upsert_ndjson ($records)   { $t->request('PATCH', "/products",       ndjson => $records) }
method list (%params)             { $paginator->collect('/products', %params) }

1;
