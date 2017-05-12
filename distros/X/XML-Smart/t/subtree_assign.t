use strict                  ;
use warnings FATAL => 'all' ;

use Test::More              ;

use ExtUtils::MakeMaker     ;

use XML::Smart              ;



my $xml_base = new XML::Smart(q`
<root>
TEXT1 &amp; more
<level1>
  aaa
</level1>
<level1-2>
  bbb
</level1-2>
</root>  
  `
) ;
  

my $xml_to_add = new XML::Smart(q`
<root>
TEXT1 &amp; more
<level1>
  aaa
</level1>
<level12>
  <level3>
  bbb
  </level3>
</level12>
</root>  
  `
) ;
  


$xml_base->{ root }{ level1 } = $xml_to_add->{ root }{ level12 } ;

cmp_ok( $xml_base->data( noheader=> 1 ), 'eq', 
q`<root>
TEXT1 &amp; more
<level1>
    <level3>
  bbb
  </level3>
  </level1>
  <level1-2>
  bbb
</level1-2></root>

` );


done_testing() ;
