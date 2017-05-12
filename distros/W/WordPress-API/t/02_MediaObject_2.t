use Test::Simple 'no_plan';
use lib './lib';
require './t/test.pl';
use strict;
use WordPress::API::MediaObject;




my $c = skiptest();








ok(1,"\n\nMETHOD2\n\n");


$c->{abs_path} = './t/image2.jpg';
my $w2 = WordPress::API::MediaObject->new($c);
my $url2 = $w2->url;

ok($url2, "url2 $url2");



my $a = $w2->abs_path;
ok($a, "abs path $a");

my $type = $w2->type;
ok($type,"type $type");


