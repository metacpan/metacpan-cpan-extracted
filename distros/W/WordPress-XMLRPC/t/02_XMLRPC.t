use Test::Simple 'no_plan';
use strict;
use lib './lib';
require './t/test.pl';
use WordPress::XMLRPC;
no strict 'refs';

ok(1,'starting test.');

assure_fulltesting();





my $w = WordPress::XMLRPC->new(_conf('./t/wppost'));

my $_attempt_delete = 0;






my $getAuthors = $w->getAuthors;
## getAuthors
ok($getAuthors,'getAuthors()');

my $getCategories = $w->getCategories;
ok(ref $getCategories eq 'ARRAY' ,'getCategories');
## $getCategories



my $ncn = ( int rand 10000 ).'testc';

print STDERR "\n\n=======\nnewCategory.. \n";
my $newCategory = $w->newCategory({ name => $ncn }) 
   or warn("newCategory no return, " . $w->errstr );

### $newCategory
=pod
unless( ok( $newCategory->{categoryName} eq $ncn ) ){
   my @k = keys %$newCategory;
   print STDERR "keys: ".scalar @k."\n";
   for my $k  (@k){
      my $v = $newCategory->{$k};
      print STDERR" k:$k, v:$v\n";
   }

 die;
}

=cut

for my $m (qw(getRecentPosts getUsersBlogs)){
   my $r = $w->$m;
   ok($r, "m $m");
   ### $m
   ### $r
}

#getTemplate
#setTemplate
#uploadFile



my $suggestCategories = $w->suggestCategories;
ok($suggestCategories, "suggestCategories()");
### $suggestCategories
