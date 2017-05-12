use strict;
use warnings;
use XML::Rules;

open my $XML, '>', 'temp.xml';
print $XML <<XML;
<root>
    <elt attr="wibble" />
    <other>tag</other>
    <elt attr="wobble">content</elt>
</root>
XML
close $XML;

my $parser = XML::Rules->new (
	style => 'filter',
    rules => {
		_default => 'raw',
		elt => sub {$_[1]->{attr} = 'updated'; return $_[0] => $_[1]}
		}
    );

#$parser->filterfile('temp.xml', 'temp-new.xml');
open my $OUT, '>', 'temp-new.xml' or die;
$parser->filterfile('temp.xml', $OUT);
close $OUT;

open my $IN, '<', 'temp-new.xml' or die;
print "::$_" while <$IN>;

