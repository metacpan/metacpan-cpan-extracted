#!perl


#example source - http://api.jquery.com/closest/
#Example: toggles a yellow background for closest parent element of each b element

use strict;

use jQuery;

my $html = do { local $/; <DATA> };


jQuery->new($html);
my $listElements = jQuery("li")->css("color", "blue");

jQuery( 'b' )->each( sub {
    jQuery(this)->closest($listElements)->toggleClass("hilight");
});

print jQuery->as_HTML;

__DATA__
<!DOCTYPE html>
<html>
<head>
  <style>
  li { margin: 3px; padding: 3px; background: #EEEEEE; }
  li.hilight { background: yellow; }
  </style>

</head>
<body>
  <ul>
    <li><b>Click me!</b></li>
    <li>You can also <b>Click me!</b></li>
  </ul>
<script>
  
</script>

</body>
</html>
