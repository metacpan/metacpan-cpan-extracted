#!perl

use strict;
use jQuery;

my $html = do { local $/; <DATA> };

jQuery->new($html);
jQuery("span")->wrapAll("<div><div><p><em><b></b></em></p></div></div>");

print jQuery->as_HTML;

__DATA__
<!DOCTYPE html>
<html>
<head>
  <style>

  div { border:2px blue solid; margin:2px; padding:2px; }
  p { background:yellow; margin:2px; padding:2px; }
  strong { color:red; }
  </style>

</head>
<body>
  <span>Span Text</span>
  <strong>What about me?</strong>
  <span>Another One</span>

</body>
</html>
