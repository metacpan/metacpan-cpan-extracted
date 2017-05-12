use Test::Simple 'no_plan';
use strict;
use lib './lib';
require './t/test.pl';
use WordPress::API::Page;

#use Smart::Comments '###';

my $conf = skiptest();

### $conf


my $w = WordPress::API::Page->new($conf);

### $w

ok($w,'object initiated');

ok( $w->proxy, 'proxy method returns') or die('check your conf');
ok( $w->password, 'password method returns') or die;
ok( $w->username, 'username method returns') or die;

$w->title('This is ok'.time());
$w->description('this is test content');

ok($w->save, 'saved') or die;

ok($w->id,'got id()'.$w->id);

my $struct = $w->structure_data;
ok($struct, "got structure_data");
### $struct;

my ($id,$description,$title) = ($w->id, $w->description, $w->title);

ok($id, 'id()');
ok($description,'description()');
ok($title,'title()');

### $id
### $description
### $title

sleep 1;





ok( $w->load, 'loaded after saving.. hmmm');

$struct = $w->structure_data;
### $struct

my $cat = $w->categories;

### $cat






ok( $w->delete,'deleted' ) or die;







