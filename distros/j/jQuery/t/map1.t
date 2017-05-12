#!perl
use jQuery;

use Test::More 'no_plan';

my $html = do { local $/; <DATA> };

jQuery->new($html);

my $count = 0;

my $values = jQuery("#container")->find('div')->map(sub {
    my $i = shift;
    my $node = shift;
    ok(this->hasClass('test' . $i));
    is(this->tagName,'div');
    
    if ($i == 3){
        is($node->text(),'Hi there');
    }
    
    $count++;
    return this->attr('class');
    
})->get()->join(',');

is($count,4);
is($values,'test0,test1,test2,test3');


__DATA__
<!DOCTYPE html>
<html>
<head>
</head>
<body>

<div id="container">
<div class='test0'></div>
<div class='test1'></div>
<div class='test2'></div>
<div class='test3'>Hi there</div>
</div>

</body>
</html>
