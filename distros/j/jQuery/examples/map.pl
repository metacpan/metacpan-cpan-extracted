#!perl

#   Example: A contrived example to show some complex functionality of map method. 
#   You can check the same example at with javascript jQuery at
#   http://api.jquery.com/map/

use strict;
use jQuery;

my $html = do { local $/; <DATA> };

jQuery->new($html);

    my $mappedItems = jQuery("li")->map(sub {
        
        my $index = shift;
        
        my $replacement = jQuery("<li>")->text( jQuery(this)->text() )->get(0);
      
        if ( $index == 0 ) {
            jQuery($replacement)->text(uc $replacement->text());
          
        } elsif ( $index == 1 || $index == 3) {
            ##/* delete the second and fourth items */
            $replacement = '';
        } elsif ($index == 2) {
            #/* make two of the third item and add some text */
            $replacement = [$replacement,jQuery("<li>")->get(0)];
            jQuery($replacement->[0])->append("<b> - A</b>");
            jQuery($replacement->[1])->append("Extra <b> - B</b>");
        }
        
        #/* replacement will be a dom element, null, 
        #   or an array of dom elements */
        return $replacement;
    });
    
    
    jQuery("#results")->append($mappedItems);
    
    #print $mappedItems->text();
    
    print jQuery->as_HTML;


__DATA__
<!DOCTYPE html>
<html>
<head>
  <style>
  body { font-size:16px; }
  ul { float:left; margin:0 30px; color:blue; }
  #results { color:red; }
  </style>
</head>
<body>
  <ul>
    <li>First</li>
    <li>Second</li>
    <li>Third</li>

    <li>Fourth</li>
    <li>Fifth</li>
  </ul>
  <ul id="results">

  </ul>
<script>


</script>

</body>
</html>
