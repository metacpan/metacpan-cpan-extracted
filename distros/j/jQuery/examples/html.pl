#!perl
use warnings;
use strict;
use jQuery;

my $html = do { local $/; <DATA> };

jQuery->new($html);

jQuery("div")->html('<b>Wow!</b> Such excitement...');

jQuery("div b")
->append(jQuery->document->createTextNode("!!!"))
->css("color", "red");

print jQuery->as_HTML;

__DATA__
<!DOCTYPE html>
<html>
<head>
  <style>
  div { color:blue; font-size:18px; }
  </style>
  
</head>
<body>
  <div></div>
  <div>ss</div>
  <div></div>
<script>

    

</script>

</body>
</html>
