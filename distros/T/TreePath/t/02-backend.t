use utf8;
use strict;

use open qw(:std :utf8);
use Test::More 'no_plan';
use lib 't/lib';

use TreePath;


my @confs = (
              't/conf/treefromdbix.yml',
              't/conf/treefromfile.yml',
            );


foreach my $conf ( @confs ){

    ok( my $tp = TreePath->new(  conf  => $conf, debug => 0  ),
      "New TreePath ( conf => $conf)");
    $tp->load;

    is ( $tp->count, 21, 'tree has 21 nodes');
    ok( $tp->del( $tp->search({name => '♥', source => 'Page'})), 'delete ♥ Page and children');

    is ( $tp->count, 13, 'now the tree has 13 nodes');

    ok( my $A = $tp->search( { name => 'A', source => 'Page' } ), 'Page A founded');
    ok( my $E = $tp->search( { name => 'E', source => 'Page' } ), 'Page E founded');
    is( $E->{parent}->{name}, 'C', 'E has C as parent');

    ok($tp->update($E, { parent => $A, source => 'Page'}), 'update E parent => A');

    is( $E->{parent}->{name}, 'A', 'E has A as parent');


}
