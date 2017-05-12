
require 5;
use strict;
use Test;
BEGIN { plan tests => 16 }

print "# Starting ", __FILE__ , " ...\n";
ok 1;

#sub XML::RSS::SimpleGen::DEBUG () {20}

use XML::RSS::SimpleGen ();

sub r ($$) {
  my($m,$v) = @_;
  my $r = XML::RSS::SimpleGen->new('http://test.int/','blorg');
  $r->$m($v);
  $r->as_string;
}

ok r('ttl', '30'), '/<ttl>30</ttl>/';

ok r('skipHours', 1), '/<skipHours>\s*<hour>1</hour>\s*</skipHours>/';
ok r('skipDays' , 1), '/<skipDays>\s*<day>Monday</day>\s*</skipDays>/';
ok r('skipDays' , 'Monday'), '/<skipDays>\s*<day>Monday</day>\s*</skipDays>/';
ok r('skipDays' , 'Monday'), '/<skipDays>\s*<day>Monday</day>\s*</skipDays>/';
ok r('language' , 'sgn-us'), '/<language>sgn-us</language>/';
ok r('css', './foo.css'), '/foo\.css/';
ok r('xsl', './foo.xsl'), '/foo\.xsl/';
ok r('webMaster', 'jojo@mojo.int'), '/<webMaster>jojo@mojo.int</webMaster>/';
ok r('docs', 'http://whatever.int'), '/<docs>http://whatever\.int</docs>/';
ok r('url', 'http://whatever.int'), '/<link>http://whatever.int</link>/';
ok r('title', 'jojo@mojo.int'), '/<title>jojo@mojo.int</title>/';
ok r('description', 'jojo@mojo.int'), '/<description>jojo@mojo.int</description>/';
ok r('item', 'http://whatever.int'), '/<link>http://whatever.int</link>/';

print "# Done at ", scalar(localtime), ".\n";
ok 1;

