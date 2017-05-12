use strict;
use warnings;

use Test::More tests => 10;

use Text::Trac2GFM qw( gfmtitle );

cmp_ok(gfmtitle('Foo'),                'eq', 'foo');
cmp_ok(gfmtitle('Foo/Bar'),            'eq', 'foo-bar');
cmp_ok(gfmtitle('Foo & Bar'),          'eq', 'foo-and-bar');
cmp_ok(gfmtitle('Multiple    Spaces'), 'eq', 'multiple-spaces');
cmp_ok(gfmtitle('[Invalid)^Chars!'),   'eq', 'invalid-chars');

cmp_ok(gfmtitle('Foo',     { downcase => 0 }), 'eq', 'Foo');
cmp_ok(gfmtitle('Foo/Bar', { unslash  => 0 }), 'eq', 'foo/bar');

cmp_ok(gfmtitle('JS & Java', { terms => { 'js' => 'javascript' } }), 'eq', 'javascript-and-java');

cmp_ok(gfmtitle('Partial/CamelCasing'), 'eq', 'partial-camel-casing');

cmp_ok(gfmtitle('NTT/DoCoMo'), 'eq', 'ntt-do-co-mo', 'avoid kebab-casing acronyms');
