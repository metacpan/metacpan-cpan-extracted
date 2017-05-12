use Test::Simple 'no_plan';
use strict;
use lib './lib';
require './t/test.pl';
use WordPress::XMLRPC;
no strict 'refs';
use Smart::Comments '###';

ok(1,'starting test.');
my $r;


assure_fulltesting();

my $w = WordPress::XMLRPC->new(_conf('./t/wppost'));
$WordPress::XMLRPC::DEBUG = 1;

for my $method (qw/getComment getComments deleteComment editComment newComment getCommentStatusList/){
   ok( $w->can($method), "can $method()");

}

warn"\n\n";


ok( $r = $w->getCommentStatusList, 'getCommentStatusList()');
### $r






# create a comment..
ok( $r = $w->newComment( 372, {
   status => 'approve',
   content => (sprintf "%s %s",time(),'this is content here'),
}), 
   'newComment()');

### $r
my $cid = $r;


ok( $r = $w->getComment($cid),'getComment()');
### $r

sleep 1;

ok( $r = $w->deleteComment($cid), 'deleteComment()' );
### $r 







