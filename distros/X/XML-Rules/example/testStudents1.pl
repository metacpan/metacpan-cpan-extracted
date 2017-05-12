$|=1;
use XML::Rules;

$xml = <<'*END*';
<school>

<classes name="Primary">
<student name="Junkman">
<Age>12</Age>
</student>

<student name="Lotman">
<Age>14</Age>
</student>
</classes>

<classes name="Nursery">
<student name="Testman">
<Age>34</Age>
</student>
</classes>

<classes name="SomeClass">
</classes>
</school>
*END*

my $parser = new XML::Rules (
	rules => [
	_default => '',
	'^classes' => sub {return ($_[1]->{name} eq "Primary")}, # skip all classes whose names are not Primary
	student => sub {print $_[1]->{name}."\n";}
]);

$parser->parsestring($xml);
