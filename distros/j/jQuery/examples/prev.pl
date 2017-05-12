#!perl

use strict;
use jQuery;

my $html = do { local $/; <DATA> };

jQuery->new($html);

jQuery("p")->prev(".selected")->css("background", "yellow");
print jQuery->as_HTML;

__DATA__
<!DOCTYPE html>
<html>
<head>

</head>
<body>
  <div><span>Hello</span></div>

  <p class="selected">Hello Again</p>
  <p>And Again</p>
<script></script>

</body>
</html>
