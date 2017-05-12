#!perl

use strict;
use jQuery;

my $html = do { local $/; <DATA> };

jQuery->new($html);

jQuery("#term-2")->nextUntil("dt")
  ->css("background-color", "red");

my $term3 = jQuery->document->getElementById("term-3");

jQuery("#term-1")->nextUntil($term3, "dd")
->css("color", "green");

print jQuery->as_HTML;

__DATA__
<!DOCTYPE html>
<html>
<head>

</head>
<body>
  <dl>
  <dt id="term-1">term 1</dt>
  <dd>definition 1-a</dd>
  <dd>definition 1-b</dd>
  <dd>definition 1-c</dd>
  <dd>definition 1-d</dd>

  <dt id="term-2">term 2</dt>
  <dd>definition 2-a</dd>
  <dd>definition 2-b</dd>
  <dd>definition 2-c</dd>

  <dt id="term-3">term 3</dt>
  <dd>definition 3-a</dd>
  <dd>definition 3-b</dd>
</dl>
<script>  


</script>

</body>
</html>
