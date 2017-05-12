use Test::Simple 'no_plan';
use strict;
use lib './lib';
require './t/test.pl';
use WordPress::XMLRPC;
no strict 'refs';

ok(1,'starting test.');

assure_fulltesting();


my $w = WordPress::XMLRPC->new(_conf('./t/wppost'));

### $w

my $publish = $w->publish;
### $publish
#
my $_attempt_delete =1;



# we know this fails:
#my $np1 = $w->newPage;






### PAGE
my $_name = 'page '.time().int(rand(256));
my $newPage = $w->newPage({title => $_name,  description => 'bogus content' })
   or die($w->errstr);
### $newPage
ok($newPage, "new page returns id $newPage") or die;

my $editPage = $w->editPage($newPage, 
   { title => 'test_test_1', description => 'bogus content edited' });
### $editPage
ok( $editPage,'editPage() succeeds in context( page_id, content_href)');

my $editPage_2 = $w->editPage(
   { title => 'test_test_4', description => 'bogus content edited', page_id => $newPage });
### $editPage_2
ok( $editPage_2,'editPage() succeeds in context( content_href )');



my $getPage = $w->getPage($newPage) or die("error string: ".$w->errstr);

## $getPage;

ok( ref $getPage eq 'HASH', 'getPage returns hash ref');


my $getPages = $w->getPages;
ok( ref $getPages eq 'ARRAY', 'getPages returns array ref');
## $getPages


my $getPageList = $w->getPageList;
## $getPageList
ok( ref $getPageList eq 'ARRAY', 'getPageList returns array ref');


if ($_attempt_delete){
   my $deletePage = $w->deletePage($newPage);
   ok($deletePage, 'deletePage succeeds');
}






