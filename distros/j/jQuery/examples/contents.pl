#!perl

use strict;
use jQuery;
my $html = do { local $/; <DATA> };

jQuery->new($html);

jQuery("div")->css("border", "2px solid red")
    ->add("p")->add('p')
    ->css("background", "yellow");
    
print jQuery->as_HTML;


__DATA__
<!DOCTYPE html>
<html>
<head>
  <style>
 div { width:60px; height:60px; margin:10px; float:left; }
 p { clear:left; font-weight:bold; font-size:16px; 
     color:blue; margin:0 10px; padding:2px; }
 </style>
  
</head>
<body>
  <div></div>

  <div></div>
  <div></div>
  <div></div>
  <div></div>
  <div></div>

  <p>Added this... (notice no border)</p>
<script>


</script>

</body>
</html>
