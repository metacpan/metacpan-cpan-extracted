use Test::Simple 'no_plan';
use strict;
use lib './lib';
require './t/test.pl';
use WordPress::XMLRPC;
no strict 'refs';
use Smart::Comments '###';

ok(1,'starting test.');

my $r;


print STDERR " # WordPress has a bug - i think.. it doesn't register new categories properly via rpc\n\n";


assure_fulltesting();




my $w = WordPress::XMLRPC->new(_conf('./t/wppost'));
$WordPress::XMLRPC::DEBUG = 1;

for my $method (qw/newCategory deleteCategory suggestCategories getCategory/){
   ok( $w->can($method), "can $method()");
}


warn"\n\n-\n\n";



my $new_category_name ='category' .( int rand 1000 );
print STDERR " -- new category name will be : \n\t'$new_category_name'\n\n";

my $new_category_id;
ok( $new_category_id = $w->newCategory({ name => $new_category_name} ));
print STDERR " # newCategory( '$new_category_name' ) gets id :  $new_category_id\n\n";

ok( have_catname($new_category_name), "new cat $new_category_name is now present");






$new_category_name.=" appended";
my $new_category_id2;
ok( $new_category_id2 = $w->newCategory({ name => $new_category_name}) ) 
   or die("failed newCategory( '$new_category_name' ) ".$w->errstr );
print STDERR " # newCategory( '$new_category_name' ) gets id :  $new_category_id2\n\n";

ok($new_category_id != $new_category_id2,
   "new cat 1 id ($new_category_id)  is not same as new cat 2 id ($new_category_id2)");


ok( have_catname($new_category_name), "new cat $new_category_name is now present");




my @catnames = map { $_->{categoryName} } @{$w->getCategories};
print STDERR " # categories are '@catnames'\n";

warn("\n\n# ---------------\n#will remove those categories..\n\n");

for my $cat ($new_category_id, $new_category_id2){

   ok( $w->getCategory($cat),'have category' );

   my $r;
   ok( $r = $w->deleteCategory($cat), "deleteCategory() '$cat'");
   ### $r
   ok( ! $w->getCategory($cat),'no longer have category' );

   warn "\n\n";
}



warn "\n\n--------------------\n# suggest categories..\n\n";

ok( $r = $w->suggestCategories );
### $r

my $partial_word = 'draw';
ok( $r = $w->suggestCategories($partial_word),"suggestCategories() partial word: '$partial_word'");
### $r


#
#my $cats = $w->getCategories;

## $cats

sub have_catname {
   my $_catname = shift;
   
   for ( @{$w->getCategories} ){
      my $catname = $_->{categoryName};
      return 1 if $catname eq $_catname;
   }
   return 0;
}
