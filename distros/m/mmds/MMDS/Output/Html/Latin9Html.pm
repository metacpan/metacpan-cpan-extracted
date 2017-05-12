package MMDS::Output::Html::Latin9Html;

# RCS Id: $Id: Latin9Html.pm,v 1.1 2002-12-30 19:22:39+01 jv Exp $

# Map iso-8859-15 to HTML encoding.

require MMDS::Output::Html::Latin1Html;

$::iso2html{"\244"} = 'euro';
$::iso2html{"\246"} = 'Scaron';
$::iso2html{"\250"} = 'scaron';
$::iso2html{"\264"} = 'Zcaron';
$::iso2html{"\270"} = 'zcaron';
$::iso2html{"\274"} = 'OE';
$::iso2html{"\275"} = 'oe';
$::iso2html{"\276"} = 'Yuml';

1;
