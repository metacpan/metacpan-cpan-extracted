use warnings;
use strict;

use lib 't/lib';
use Test::More tests => 6;

{   package ExceptWithArray;
    use ExporterTest qw( foo bar qux );
    use namespace::clean -except => [qw( foo bar )];
}
ok( ExceptWithArray->can('foo'),    'first of except list still there');
ok( ExceptWithArray->can('bar'),    'second of except list still there');
ok(!ExceptWithArray->can('qux'),    'item not in except list was removed');

{   package ExceptWithSingle;
    use ExporterTest qw( foo bar qux );
    use namespace::clean -except => 'qux';
}
ok(!ExceptWithSingle->can('foo'),   'first item not in except still there');
ok(!ExceptWithSingle->can('bar'),   'second item not in except still there');
ok( ExceptWithSingle->can('qux'),   'except item was removed');


