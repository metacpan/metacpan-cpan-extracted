#!\perl

use strict;
use jQuery;
my $html = do { local $/; <DATA> };

jQuery->new($html);

jQuery("div")->find("p")->andSelf()->addClass("border");
jQuery("div")->find("p")->addClass("background");

print jQuery->as_HTML;


__DATA__
<!DOCTYPE html>
<html>
<head>
  <style>
  p, div { margin:5px; padding:5px; }
  .border { border: 2px solid red; }
  .background { background:yellow; }
  </style>
  
</head>
<body>
  <div>
    <p>First Paragraph</p>
    <p>Second Paragraph</p>
  </div>
<script>
    

</script>

</body>
</html>
