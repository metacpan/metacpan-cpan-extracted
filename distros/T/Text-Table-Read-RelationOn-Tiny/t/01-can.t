use 5.010_001;
use strict;
use warnings;
use Test::More;

use Text::Table::Read::RelationOn::Tiny;


ok(defined($Text::Table::Read::RelationOn::Tiny::VERSION), '$VERSION is defined');

ok(Text::Table::Read::RelationOn::Tiny->can('new')        ,      'new() exists');
ok(Text::Table::Read::RelationOn::Tiny->can('get')        ,      'get() exists');
ok(Text::Table::Read::RelationOn::Tiny->can('inc')        ,      'inc() exists');
ok(Text::Table::Read::RelationOn::Tiny->can('noinc')      ,    'noinc() exists');
ok(Text::Table::Read::RelationOn::Tiny->can('matrix')     ,   'matrix() exists');
ok(Text::Table::Read::RelationOn::Tiny->can('elems')      ,    'elems() exists');
ok(Text::Table::Read::RelationOn::Tiny->can('elem_ids')   , 'elem_ids() exists');
ok(Text::Table::Read::RelationOn::Tiny->can('x_elem_ids') , 'x_elem_ids() exists');
ok(Text::Table::Read::RelationOn::Tiny->can('prespec')    ,  'prespec() exists');
ok(Text::Table::Read::RelationOn::Tiny->can('n_elems')    ,  'n_elems() exists');


#==================================================================================================
done_testing();


