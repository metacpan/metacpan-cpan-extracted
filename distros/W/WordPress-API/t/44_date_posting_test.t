use Test::Simple 'no_plan';
use strict;
use lib './lib';
require './t/test.pl';
use WordPress::API::Post;
use Smart::Comments '###';

my $conf = skiptest();



my $w = WordPress::API::Post->new($conf);
ok($w,'object initiated');

$w->proxy or die('check your conf');
$w->password or die;
$w->username or die;

$w->title('This is ok'.time());
$w->description('this is test content');


ok(1,'setting date.. ');
my $d = $w->dateCreated('20080731');
ok( $d, "dateCreated() returns");
### $d
### saving.....
ok($w->save, 'posted') or die;


ok($w->id,'got id()'.$w->id);


ok( $w->load, 'loaded after saving.. hmmm');

my $datefromserver = $w->dateCreated;
### $datefromserver

my $struct = $w->structure_data;
### $struct



sleep 1;

ok( $w->delete,'deleted' ) or die;


