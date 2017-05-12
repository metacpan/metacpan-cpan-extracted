#!perl

#example source - http://api.jquery.com/children/
#Example: Find all children of each div. 

use strict;
use jQuery;

my $html = do { local $/; <DATA> };

jQuery->new($html);

jQuery("div")->children()->css("border-bottom", "3px double red");

print jQuery->as_HTML;


__DATA__
<!DOCTYPE html>
<html>
<head>
  <style>
  body { font-size:16px; font-weight:bolder; }
  span { color:blue; }
  p { margin:5px 0; }
  </style>
 
</head>
<body>
  <p>Hello (this is a paragraph)</p>

  <div><span>Hello Again (this span is a child of the a div)</span></div>
  <p>And <span>Again</span> (in another paragraph)</p>

  <div>And One Last <span>Time</span> (most text directly in a div)</div>
<script></script>

</body>
</html>
