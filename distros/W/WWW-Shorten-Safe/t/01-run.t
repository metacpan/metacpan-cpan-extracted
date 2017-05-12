use Data::Dumper;

use Test::More;
use lib '../lib/';

use WWW::Shorten 'Safe';


my $long = "http://www.google.com/";

my $short = makeashorterlink($long);
is($short, 'http://safe.mn/9', "Short link 1");

my $long_url  = makealongerlink($short);
is($long_url, $long, "Expanded link");



my $safe = WWW::Shorten::Safe->new();
my $short_safe = $safe->shorten(URL => $long);
is($short_safe, 'http://safe.mn/9', "Short link 2");
is($safe->{safeurl}, 'http://safe.mn/9', "Short link 3");


$short_safe = $safe->shorten(URL => $long, DOMAIN => "clic.gs");
is($short_safe, 'http://clic.gs/9', "Short link 4");




my $clic = WWW::Shorten::Safe->new(domain => 'clic.gs');
$short_safe = $clic->shorten(URL => $long);
is($short_safe , 'http://clic.gs/9', "Short link 5");
is($clic->{safeurl}, 'http://clic.gs/9', "Short link 6");


$long_url = $safe->expand(URL => $short);
is($long_url, $long, "Expanded link");

$long_url = $clic->expand(URL => $short);
is($long_url, $long, "Expanded link");


my $info = $safe->info(URL => "http://safe.mn/25");
ok( exists $info->{clicks}, 				"Number of clicks is present");
ok( $info->{clicks} > 1, "More than 1 click");

$info = $safe->info(URL => "http://safe.mn/1");
ok( exists $info->{referers}, 				"List of referers is present");

$info = $safe->info(URL => "http://safe.mn/2");
ok( exists $info->{countries}, 				"List of countries is present");

$info = $safe->info(URL => "http://safe.mn/3");
ok( exists $info->{filetype}, 				"File type is present");


done_testing;