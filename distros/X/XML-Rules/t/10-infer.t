#!perl -T

use strict;
use warnings;
use Test::More tests => 1;

use XML::Rules;

my $XML = <<'*END*';
<root>
	<sub>
		<contentOnly>blah</contentOnly>
		<contentAndAttr>blah</contentAndAttr>
		<contentArr>blah</contentArr>
		<attrArr x="11"/>
		<cAttrArr x="11">blah</cAttrArr>
	</sub>
	<sub>
		<contentAndAttr x="45">blih</contentAndAttr>
		<contentArr>blah</contentArr>
		<contentArr>blah</contentArr>
		<attrArr x="11"/>
		<attrArr x="11"/>
		<cAttrArr x="11">blah</cAttrArr>
		<cAttrArr x="11">blah</cAttrArr>
	</sub>
	<otherSub>
		<contentOnly>blah</contentOnly>
		<contentAndAttr>blah</contentAndAttr>
		<contentArr>blah</contentArr>
		<attrArr x="11"/>
		<cAttrArr x="11">blah</cAttrArr>
	</otherSub>
	<mixed>
		blah<inMixContent>blah</inMixContent> sdgf fdg
		blah<inMixAttr x="7">blah</inMixAttr> sdgf fdg
		blah<inMixContentArr>blah</inMixContentArr> sdgf fdg
		blah<inMixContentArr>blah</inMixContentArr> sdgf fdg
		blah<inMixAttrArr x="7">blah</inMixAttrArr> sdgf fdg
		blah<inMixAttrArr x="7">blah</inMixAttrArr> sdgf fdg
	</mixed>
</root>
*END*

my $good = {
	'contentOnly' => 'content',
	'inMixAttrArr,inMixContentArr' => 'raw extended array',
	'attrArr,sub' => 'as array no content',
	'contentArr' => 'content array',
	'cAttrArr' => 'as array',
	'contentAndAttr,mixed' => 'as is',
	'otherSub,root' => 'no content',
	'inMixAttr,inMixContent' => 'raw extended'
};

my $got = XML::Rules::inferRulesFromExample( $XML);

use Data::Dumper;
print Dumper($got);

is_deeply( $got, $good, "Rules as expected");


