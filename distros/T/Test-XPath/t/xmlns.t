#!/usr/bin/perl -w

use strict;
use Test::More tests => 4;

BEGIN { use_ok 'Test::XPath' or die; }

# Borrowed from http://www.w3schools.com/XML/xml_namespaces.asp
my $xml = <<'XML';
<?xml version="1.0" encoding="UTF-8"?>
<root>
  <table xmlns="http://www.w3.org/TR/html4/">
    <name>Fruit</name>
    <tr>
      <td>Apples</td>
      <td>Bananas</td>
    </tr>
  </table>
  <table xmlns="http://www.w3schools.com/furniture">
    <name>African Coffee Table</name>
    <width>80</width>
    <length>120</length>
  </table>
</root>
XML

ok my $xp = Test::XPath->new(
    xml => $xml,
    xmlns => {
        x => 'http://www.w3.org/TR/html4/',
        f => 'http://www.w3schools.com/furniture',
    },
), 'Create object with two namespaces';

$xp->is('/root/x:table/x:name', 'Fruit', 'Should get HTML table');
$xp->is('/root/f:table/f:name', 'African Coffee Table', 'Should furniture table');
