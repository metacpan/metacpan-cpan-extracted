#!perl

#example source - http://api.jquery.com/parents/
#Example: Example: Find all parent elements of each b.
use strict;
use jQuery;

my $html = do { local $/; <DATA> };

jQuery->new($html);

jQuery("li.item-a")->parentsUntil(".level-1")
->css("background-color", "red");

jQuery("li.item-2")->parentsUntil( jQuery("ul.level-1"), ".yes" )
  ->css("border", "3px solid green");

print jQuery->as_HTML;

__DATA__
<!DOCTYPE html>
<html>
<head>
 
</head>
<body>
  
<ul class="level-1 yes">
  <li class="item-i">I</li>
  <li class="item-ii">II
    <ul class="level-2 yes">
      <li class="item-a">A</li>
      <li class="item-b">B
        <ul class="level-3">
          <li class="item-1">1</li>
          <li class="item-2">2</li>
          <li class="item-3">3</li>
        </ul>
      </li>
      <li class="item-c">C</li>
    </ul>
  </li>
  <li class="item-iii">III</li>
</ul>
<script>

    
</script>

</body>
</html>
