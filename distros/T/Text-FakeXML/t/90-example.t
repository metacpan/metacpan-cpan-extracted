#! perl

use strict;
use warnings;
use Test::More tests => 1;
use Text::FakeXML;

open(my $fd, ">", \my $data);

my $cfg = Text::FakeXML->new(version => "1.0", fh => $fd);

$cfg->xml_elt_open("gconf");
$cfg->xml_elt_open("entry", name => "geometry_collection",
		   mtime => "1164190071", type => "string");
$cfg->xml_elt("stringvalue", "440x350+1063+144" );
$cfg->xml_elt_close("entry");
$cfg->xml_elt_close("gconf");

is($data, <<EOD, "compare");
<?xml version='1.0'?>
<gconf>
  <entry name="geometry_collection" mtime="1164190071" type="string">
    <stringvalue>440x350+1063+144</stringvalue>
  </entry>
</gconf>
EOD
