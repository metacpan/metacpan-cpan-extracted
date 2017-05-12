#!perl

#   Example: Adds more elements, created on the fly, to the set of matched elements.
# example page http://api.jquery.com/add/

use strict;
use jQuery;

my $html = do { local $/; <DATA> };

jQuery->new($html);
#jQuery->document->body
jQuery("p")->clone()->add("<span>Again</span>")
->appendTo(jQuery->document->body)
->css('color','red');

print jQuery->as_HTML;


__DATA__
<!DOCTYPE html>
<html>
<head>
  
</head>
<body>
  <p>Hello</p>
<script></script>

</body>
</html>

</body>
</html>
