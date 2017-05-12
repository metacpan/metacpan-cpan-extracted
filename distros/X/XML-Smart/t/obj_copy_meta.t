use strict                  ;
use warnings FATAL => 'all' ;

use Test                    ;

use ExtUtils::MakeMaker     ;

BEGIN { plan tests => 1 }   ;

use XML::Smart              ;


my $xml = new XML::Smart(q`
<foo>
TEXT1 & more
<if.1>
  aaa
</if.1>
<!-- CMT -->
<elsif.2>
  bbb
</elsif.2>
</foo>  
  `,'html') ;
  
$xml = $xml->copy() ;

my $data = $xml->data(noident=>1 , noheader => 1 , wild=>1) ;
  
ok($data,q`<foo>
TEXT1 &amp; more
<if.1>
  aaa
</if.1>
<!-- CMT -->
<elsif.2>
  bbb
</elsif.2></foo>

`) ;



1 ;
