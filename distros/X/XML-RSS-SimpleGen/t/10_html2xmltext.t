
require 5;
use strict;
use Test;
BEGIN { plan tests => 32 }

print "# Starting ", __FILE__ , " ...\n";
ok 1;

#sub XML::RSS::SimpleGen::DEBUG () {20}

use XML::RSS::SimpleGen;
print "# XML::RSS::SimpleGen version $XML::RSS::SimpleGen::VERSION\n";
sub z ($) { return XML::RSS::SimpleGen->html2text( $_[0] ) }

ok z ''      , ''  , 'nullstring';
ok z '1'     , '1' , 'digit 1';
ok z ' 1 '   , '1' , 'digit 1 with spaces';
ok z '    1 ', '1' , 'digit 1 with spaces';

ok z "vis-à-vis Beyoncé's naïve papier-mâché résumé",
     "vis-&#224;-vis Beyonc&#233;'s na&#239;ve papier-m&#226;ch&#233; r&#233;sum&#233;";

ok z "vis-&#224;-vis Beyonc&#233;'s na&#239;ve papier-m&#226;ch&#233; r&#233;sum&#233;",
     "vis-&#224;-vis Beyonc&#233;'s na&#239;ve papier-m&#226;ch&#233; r&#233;sum&#233;";

ok z "&#19978;&#24503;&#19981;&#24503;&#65292;",
     "&#19978;&#24503;&#19981;&#24503;&#65292;";

ok z "&#19978;&#24503;&#19981; &#24503; &#65292;",
     "&#19978;&#24503;&#19981; &#24503; &#65292;";

ok z "&#19978;&#194561;&#65292;",
     "&#19978;&#194561;&#65292;";

ok z "&#x4e0a;&#x2f801;&#xff0c;",
     "&#x4e0a;&#x2f801;&#xff0c;";

ok z "&#x4E0a;<!-- yorp -->&#x2f801;&#xFF0c;",
     "&#x4E0a;&#x2f801;&#xFF0c;";


print "# De-Winification test:\n";
ok z "€20 ‘could’ be “fun” - No-body",
     '&#8364;20 &#8216;could&#8217; be &#8220;fun&#8221; - No-body';
ok z "p&#146;yogo!",   "p&#8217;yogo!";
ok z "p&#0146;yogo!",  "p&#8217;yogo!";
ok z "p&#x92;yogo!",   "p&#8217;yogo!";
ok z "p&#x092;yogo!",  "p&#8217;yogo!";



print "# Tag tests...\n";

ok z "N < 17 => true", 
     "N &lt; 17 =&gt; true";

ok z "Realtime", 
     "Realtime";
ok z "Real<p>time", 
     "Real time";
ok z "Real</p>time", 
     "Real time";
ok z "Real<br>time", 
     "Real time";
ok z "Real<hr>time", 
     "Real time";
ok z "Real<p class='bazouki' thing=\"lalala\">time", 
     "Real time";
ok z "Real<b>time", 
     "Realtime";
ok z "Real<!-- yow -->time",
     "Realtime";
ok z "Real<squim class='bazouki' thing=\"lalala\">time", 
     "Realtime";
ok z "Real<squim class='bazouki' thing=\"lalala\" />time", 
     "Realtime";
ok z "Real<squim class='bazouki' thing=\"lalala\" />time", 
     "Realtime";
ok z "Real\n\n\n\n\n        \t\t time", 
     "Real time";
ok z "Real<span\n\n\n\n\n        \t\t >time", 
     "Realtime";

print "# Quitting...\n";
ok 1;

