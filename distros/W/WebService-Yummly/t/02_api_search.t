
use strict;

use Test::More;
use Data::Dumper;
use_ok('WebService::Yummly');


if (defined $ENV{APP_ID} and defined $ENV{APP_KEY}) {

  ok(my $y = WebService::Yummly->new($ENV{APP_ID},$ENV{APP_KEY}), "new yummly object");
  ok(my $recipes = $y->search("lamb shank"),"search") ;

  foreach my $r ( @{ $recipes->{matches} } ) {
    ok($r->{recipeName}, $r->{recipeName}) ;
  }
}

done_testing;

