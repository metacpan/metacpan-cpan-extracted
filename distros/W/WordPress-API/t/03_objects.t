use Test::Simple 'no_plan';
use strict;
use lib './lib';
require './t/test.pl';
use WordPress::API::Post;

use Smart::Comments '###';

my $conf = skiptest();




my $w = WordPress::API::Post->new($conf);
### $w
ok($w,'object initiated');
$w->proxy or die('check your conf');
$w->password or die;
$w->username or die;



my $type = $w->object_type;
ok( 1," type $type");



$w->title('This is ok'.time());
$w->description('this is test content');

my $struct = $w->structure_data;
### $struct










