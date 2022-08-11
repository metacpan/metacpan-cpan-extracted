use Test::Most;
use Test::Lib;
use Example::HTML;

my $registry = Example::HTML->new;
is $registry->create(Page => +{name=>'John'})->render, '<html><p><p>111</p><p>222</p></p><head><title>Layout1</title></head><body><p>Hello John</p><p id="1">Truth! Justice!</p></body></html>';

done_testing;
