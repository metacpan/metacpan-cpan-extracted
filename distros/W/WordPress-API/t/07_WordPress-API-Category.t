use Test::Simple 'no_plan';
use lib './lib';
require './t/test.pl';
use strict;
use WordPress::API::Category;
#use Smart::Comments '###';



use warnings;

my $config = skiptest();

my %c = %{$config};

$WordPress::API::Category::DEBUG = 1;

#ok(1,"$0: this test is skipped until WordPress::XMLRPC::newCategory() is working.") and exit;

### I KNOW THIS IS BUGGY


#
### %c
#

my $api = new  WordPress::API::Category({%c});
ok($api,'instanced' )or die($api->errstr);

ok_cat_empty($api);

my $newCategoryName = 'MiscCat' .  int(rand 1000);
my $newCategoryDesc = "this is a great description here..";

ok( $api->categoryName($newCategoryName), "set name to $newCategoryName" );
ok( $api->description( $newCategoryDesc ),'set a desc');

printf STDERR " desc is  '%s'\n", $api->description;




my $nid;
ok( $nid = $api->save, "saved")
   or die("could not save.. ".$api->errstr );

ok( $nid,"new cat id $nid");





ok( $api->categoryName, 'cat name');
ok( $api->description, 'cat desc');
ok( $api->categoryName eq $newCategoryName )  or _dumpdata($api) and die(
   $api->categoryName ."is not $newCategoryName"
);
# this fails, wordpress bug .. see WordPress::XMLRPC
#ok( $api->description eq $newCategoryDesc  ) or _dumpdata($api) and die(
#   $api->description ." is not $newCategoryDesc"
#);




# ok... now we want to make a sub category

sub _dumpdata {
   my $object = shift;
   my $data = $object->structure_data;
   ### $data
   return 1;
}




print STDERR "\n\n\n=====\nPART HERE ... \nok, now create a sub category for $nid\n\n";


# ok, now create a sub cat
### %c

my $subcat = new WordPress::API::Category({%c});
ok($subcat,'instanced' )or die($subcat->errstr);
ok_cat_empty($subcat);


my $newcatname = 'Subcat of '.$newCategoryName;
print STDERR "new subcat name will be [$newcatname]\n";

ok $subcat->parentId($nid),"set parent id to $nid";
ok $subcat->parentId == $nid, "parent id $nid still present";

ok $subcat->categoryName($newcatname), 'catname setting';
ok $subcat->categoryName eq $newcatname;
ok $subcat->description('desc of subcat'), 'desc setting';

#ok ( $subcat->parentId($nid), "setting parent id ");

print STDERR " .. \n";

ok( $subcat->save, "saving.. ")  or die('cant save');

ok $subcat->parentId == $nid, "$nid still there";

my $url = $subcat->htmlUrl;
ok ($url, "got url '$url'");
my $subcatid = $subcat->id;
ok $subcatid;

print STDERR " new cat object holds.. \n";
_dumpdata($subcat);




print STDERR " Now we re instance and load.. new cat created $subcatid.. \n";
# new instance, and attempt to load
my $scat = new WordPress::API::Category({%c});
ok $scat->id($subcatid);
$scat->load;
_dumpdata($scat);


print STDERR "\n\n\n\n";






# hack
my $cats = $api->getCategories;
ok( $cats ,'getCategories returns');
ok( ref $cats eq 'ARRAY' ,'getCategories returns array ref');

ok( scalar @$cats ,'cats has count.');


for my $ch ( @$cats ){
   no warnings;
   print STDERR "\n\n == Cat.. \n\n";
   my $id = $ch->{categoryId};
   my $cn = $ch->{categoryName};
   my $pi = $ch->{parentId};
   print STDERR "id $id, name $cn, parent $pi\n";

   my $o = new WordPress::API::Category({%c});
   ok($o, 'instanced');
   ok $o->id($id);
   ok $o->load;
   ok $o->categoryName;



   my $url1 = $o->rssUrl;
   my $url2 = $o->htmlUrl;
   my $desc = $o->description;
   my $pid = $o->parentId;

   ok( $pid == $pi, "parent id $pid == $pi");

   my $_cn = $o->categoryName;
   ok( $_cn eq $cn , "categoryName() = $_cn, and cats category name is $cn");


   #ok( $o->categoryName eq $cn );
}


sub ok_cat_empty {
   my $catg = shift;

   for my $m (qw(categoryName id description parentId)){
      ok( ! $catg->$m, "method $m has nothing") or
         printf STDERR " oops, had: %s\n",$catg->$m;
   }
   return;
}




