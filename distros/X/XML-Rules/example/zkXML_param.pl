use strict;
use warnings;

use XML::Simple;

my $xml = <<XML;
<config>
<param name="SequenceNumber">66</param>
<param name="T1">6</param>
<param name="T3">6</param>
<param name="T4">540</param>
<param name="DownloadDate">11-28-07</param>
</config>
XML

my $tree = XMLin($xml);

use Data::Dumper;
print Dumper($tree);