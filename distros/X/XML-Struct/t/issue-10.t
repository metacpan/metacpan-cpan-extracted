use strict;
use Test::More;
use XML::Struct qw(readXML);

my $xml = <<XML;
<journal-meta>
    <journal type="nlm-ta">BMC Womens Health 1</journal>
    <journal type="iso-abbrev">BMC Womens Health 2</journal>
  </journal-meta>
XML

my $simple = readXML($xml, simple => 1);
is_deeply $simple, { journal => [
             { type => 'nlm-ta',     content => 'BMC Womens Health 1' },
             { type => 'iso-abbrev', content => 'BMC Womens Health 2' }
      ] }, 'include content for simple XML';

$simple = readXML($xml, simple => 1, content => 'name' );
is_deeply $simple, { journal => [
             { type => 'nlm-ta',     name => 'BMC Womens Health 1' },
             { type => 'iso-abbrev', name => 'BMC Womens Health 2' }
      ] }, 'include content for simple XML';

done_testing;
