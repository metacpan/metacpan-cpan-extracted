#!perl

use strict;
use warnings;

use Test::More;
use Test::Deep;

use lib 't/lib';

use Web::Util::ExtPaging;

use TestApp::Schema;
my $schema = TestApp::Schema->connect( 'dbi:SQLite::memory:' );
$schema->deploy;
$schema->populate(Stations => [
   [qw{id bill    ted       }],
   [qw{1  awesome bitchin   }],
   [qw{2  cool    bad       }],
   [qw{3  tubular righeous  }],
   [qw{4  rad     totalAmountly   }],
   [qw{5  sweet   beesknees }],
   [qw{6  gnarly  killer    }],
   [qw{7  hot     legit     }],
   [qw{8  groovy  station   }],
   [qw{9  wicked  out       }],
]);

my $rs = $schema->resultset('Stations')->search(undef, {
   order_by => 'id',
   rows => 3,
   page => 1,
});
{
   my $data = ext_paginate(
      $rs,
      { total_property => 'totalAmount', }
   );

   cmp_deeply $data, {
       totalAmount => 9,
       data=> set({
          id => 1,
          bill => 'awesome'
       },{
          id => 2,
          bill => 'cool'
       },{
          id => 3,
          bill => 'tubular'
       })
   }, 'ext_paginate correctly builds structure';
}

{
   my $data = ext_paginate(
      $rs,
      sub { { id => $_[0]->id } },
      { total_property => 'totalAmount', }
   );

   cmp_deeply $data, {
       totalAmount => 9,
       data=> set({
          id => 1,
       },{
          id => 2,
       },{
          id => 3,
       })
   }, 'ext_paginate with coderef correctly builds structure';
}

{
   my $rs = $schema->resultset('Stations')->search(undef, {
      columns => ['id'],
      order_by => 'id',
      rows => 3,
      page => 1,
      result_class => 'DBIx::Class::ResultClass::HashRefInflator',
   });
   my $data = ext_paginate($rs);

   cmp_deeply $data, {
       total => 9,
       data=> set({
          id => 1,
       },{
          id => 2,
       },{
          id => 3,
       })
   }, 'ext_paginate passes through HRI resultset';
}

{
   my $data = ext_parcel(
      [ map +{ id => $_->id }, $rs->all ],
      { total_property => 'totalAmount' },
   );

   cmp_deeply $data, {
       totalAmount => 3,
       data=> set({
          id => 1,
       },{
          id => 2,
       },{
          id => 3,
       })
   }, 'ext_parcel correctly builds structure with default totalAmount';
}

{
   my $data = ext_parcel(
      [ map +{ id => $_->id }, $rs->all ],
      1_000_000,
      { total_property => 'totalAmount' },
   );
   cmp_deeply $data, {
       totalAmount => 1_000_000,
       data=> set({
          id => 1,
       },{
          id => 2,
       },{
          id => 3,
       })
   }, 'ext_parcel correctly builds structure';
}

{
   my $rs = $schema->resultset('Stations')->search(undef, {
      columns => ['id'],
      order_by => 'id',
      rows => 3,
      page => 1,
      result_class => 'DBIx::Class::ResultClass::HashRefInflator',
   });

   my $data = ext_paginate($rs, sub { +{ id => $_[0]{id} + 1 } } );

   cmp_deeply $data, {
       total => 9,
       data=> set({
          id => 2,
       },{
          id => 3,
       },{
          id => 4,
       })
   }, 'ext_paginate w/ HRI works with coderef';
}

done_testing;
