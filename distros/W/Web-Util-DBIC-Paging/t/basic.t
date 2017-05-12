#!perl

use strict;
use warnings;

use Test::More;
use Test::Deep;
use lib 't/lib';
use Web::Util::DBIC::Paging;
use TestApp::Schema;
my $schema = TestApp::Schema->connect( 'dbi:SQLite::memory:' );
$schema->deploy();
$schema->populate(Stations => [
   [qw{id bill    ted       }],
   [qw{1  awesome bitchin   }],
   [qw{2  cool    bad       }],
   [qw{3  tubular righeous  }],
   [qw{4  rad     totally   }],
   [qw{5  sweet   beesknees }],
   [qw{6  gnarly  killer    }],
   [qw{7  hot     legit     }],
   [qw{8  groovy  station   }],
   [qw{9  wicked  out       }],
]);

$schema->populate(MultiPk => [
   [qw{id bill    ted       }],
   [qw{1  awesome bitchin   }],
   [qw{2  cool    bad       }],
   [qw{3  tubular righeous  }],
   [qw{4  rad     totally   }],
   [qw{5  sweet   beesknees }],
   [qw{6  gnarly  killer    }],
   [qw{7  hot     legit     }],
   [qw{8  groovy  station   }],
   [qw{9  wicked  out       }],
]);

my $rs = $schema->resultset('Stations');

PAGE_AND_SORT: {
   my $data = [page_and_sort(raw => {
      dir => 'asc',
      sort => 'bill',
      limit => 3
   }, $rs)->all];
   cmp_ok scalar @{$data}, '<=', 3, 'page_and_sort correctly pages';
   cmp_deeply [map $_->bill, @{$data}],
              [sort map $_->bill, @{$data}],
         'page_and_sort correctly sorts';
}

PAGINATE: {
   my $data = [paginate(raw => { limit => 3 }, $rs)->all];
   cmp_ok scalar @{$data}, '<=', 3,
      'paginate gave the correct amount of results';

   my $data2 = [paginate(raw => { limit => 3, start => 3 }, $rs)->all];
   my %hash;
   @hash{map $_->id, @{$data}} = ();
   ok !grep({ exists $hash{$_} } map $_->id, @{$data2} ),
      'pages do not intersect';
}

SEARCH: {
   my $data = [search(raw => {}, $rs)->all];
   cmp_deeply [map $_->id, @{$data}], [3], q{controller_search get's called by search};
}

SORT: {
   my $data = [sort_rs(raw => {}, $rs)->all];
   cmp_deeply [map $_->bill, @{$data}], [sort map $_->bill, @{$data}], q{controller_sort get's called by sort};
}

SIMPLE_SEARCH: {
   my $data = [simple_search(raw => { bill => 'oo' }, $rs)->all];
   isnt scalar(@{$data}),0, "simple search found the right results (count > 0)";
   is scalar(grep { $_->bill =~ m/oo/ } @{$data}),
      scalar(@{$data}), 'simple search found the right results (single)';

   $data = [simple_search(raw => { bill => ['oo', 'ubu'] }, $rs)->all];
   isnt scalar(@{$data}),0, "simple search found the right results (count > 0)";
   is scalar(grep { $_->bill =~ m/oo|ubu/ } @{$data}),
      scalar(@{$data}), 'simple search found the right results (a OR b)';

   $data = [simple_search(raw => { id => 2 }, $rs)->all];
   is scalar @$data, 1, 'simple search on id';
   is scalar(grep { $_->id == 2 } @{$data}),
      scalar(@{$data}), 'simple search found the right results (id)';
}

SIMPLE_SORT: {
   my $data = [simple_sort(raw => {}, $rs)->all];
   cmp_deeply [map $_->id, @{$data}], [1..9], 'default sort is id';

   $data = [simple_sort(raw => { sort => 'bill', dir => 'asc' }, $rs)->all];
   cmp_deeply [map $_->bill, @{$data}],
              [sort map $_->bill, @{$data}], 'alternate sort works';

   $data = [simple_sort(raw => { sort => 'bill', dir => 'desc' }, $rs)->all];
   cmp_deeply [map $_->bill, @{$data}],
              [reverse sort map $_->bill, @{$data}],
         'alternate sort works';
}

SIMPLE_DELETION: {
   cmp_bag [map $_->id, $rs->all] => [1..9], 'values are not deleted';
   my $data = simple_deletion(raw => { to_delete => [1,2,3] }, $rs);
   cmp_bag $data => [1,2,3], 'values appear to be deleted';
   cmp_bag [map $_->id, $rs->all] => [4..9], 'values are deleted';
}

MULTIPK_DELETION: {
   cmp_bag [map $_->id, $schema->resultset('MultiPk')->all] => [1..9], 'values are not deleted';
   my $data = simple_deletion(raw => { to_delete => [
      'awesome,bitchin',
      'cool,bad',
      'tubular,righeous'
   ] }, $schema->resultset('MultiPk'));
   cmp_bag $data => [ 'awesome,bitchin','cool,bad','tubular,righeous' ], 'values appear to be deleted';
   cmp_bag [map $_->id, $schema->resultset('MultiPk')->all] => [4..9], 'values are deleted';
}

done_testing;

