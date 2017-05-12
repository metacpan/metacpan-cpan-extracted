
use strict;

use Test::More;
use Data::Dumper;

use_ok('WebService::Yummly');

if (defined $ENV{APP_ID} and defined $ENV{APP_KEY}) {
  ok(my $y = WebService::Yummly->new($ENV{APP_ID},$ENV{APP_KEY}), "new yummly object");
  ok(my $recipes = $y->search("lamb shank"),"search") ;
  ok($recipes->{matches}->[0]->{id}, $recipes->{matches}->[0]->{id}) ;
  #warn Dumper($recipes->{matches}->[0]);

  my $r = WebService::Yummly->new( $ENV{APP_ID},$ENV{APP_KEY}, $recipes->{matches}->[0]->{id});
  ok($r,"new yummly");

  my $recipe = $r->get_recipe ;
  ok($recipe, "got recipe");
  is($recipe->{name},"Lamb Shanks and Potatoes","got name");
}

done_testing;


