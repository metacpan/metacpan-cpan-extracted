use Test::Simple 'no_plan';
use lib './lib';
require './t/test.pl';
use strict;
use WordPress::API::MediaObject;


unlink './t/saved.yml';


my $c = skiptest();



my $w = WordPress::API::MediaObject->new($c);
ok($w, 'instanced') or die;


ok( $w->load_file('./t/image.jpg'),'load_file()');


ok( $w->upload ,'upload()')
   or die($w->errstr);


my $a = $w->abs_path;
ok($a," abs path $a");

my $url = $w->url;

ok($url,"got url '$url'");

my $t = $w->type;
ok($t,"type $t");




$w->save_file('./t/saved.yml');

ok( -f './t/saved.yml', 'saved');




__END__

ok(1,"\n\nMETHOD2\n\n");


$c->{abs_path} = './t/image2.jpg';
my $w2 = WordPress::API::MediaObject->new($c);



my $a = $w2->abs_path;
ok($a, "abs path $a");

my $type = $w2->type;
ok($type,"type $type");

my $url2 = $w2->url;

ok($url2, "url2 $url2");

