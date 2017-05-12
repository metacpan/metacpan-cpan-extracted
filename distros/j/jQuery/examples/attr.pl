#!perl

use strict;
use jQuery;

my $html = do { local $/; <DATA> };

jQuery->new($html);

jQuery("div")->attr("id", sub {
    my $arr = shift;
    return "div-id" . $arr;
})->each( sub {
    jQuery("span", this)->html("(ID = '<b>" . this->id . "</b>')");
});

    
print jQuery->as_HTML;


__DATA__
<!DOCTYPE html>
<html>
<head>
  <style>
  div { color:blue; }
  span { color:red; }
  b { font-weight:bolder; }
        </style>
 
</head>
<body>
  
  <div>Zero-th <span></span></div>
  <div>First <span></span></div>
  <div>Second <span></span></div>



</body>
</html>
