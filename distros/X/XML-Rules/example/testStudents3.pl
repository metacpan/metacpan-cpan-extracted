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
	_default => 'raw',
	classes => sub {
		if ($_[1]->{name} eq 'SomeClass') {
			if (ref($_[1]->{_content})) {
				push @{$_[1]->{_content}}, $_[4]->{parameters}
			} else {
				$_[1]->{_content} = [ $_[1]->{_content}, $_[4]->{parameters}];
					# there were no students in the class, the tag contained only the whitespace
			}
		}
		return [$_[0] => $_[1]]
	},
]);

my $result = $parser->parsestring($xml, [student => {name => 'Johny', age => {_content => 25}}]);
print $parser->toXML(@$result);