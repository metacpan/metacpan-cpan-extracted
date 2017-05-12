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
		if (not exists($_[3]->[-1]{':printed'})) {
			print $_[4]->parentsToXML();
			$_[3]->[-1]{':printed'} = 1;
		}

		my $add = $_[4]->{parameters}{$_[1]->{name}};

		if ($add) {
			if (ref($_[1]->{_content})) {
				push @{$_[1]->{_content}}, @$add
			} else {
				$_[1]->{_content} = [ $_[1]->{_content}, @$add];
					# there were no students in the class, the tag contained only the whitespace
			}
		}
		print $_[4]->toXML($_[0], $_[1]), "\n";
		return;
	},
	school => sub {print "</school>"},
]);

my $result = $parser->parsestring($xml,
	{
		SomeClass => [
			[student => {name => 'Johny', age => {_content => 31}}], "\n",
		],
		Nursery => [
			[student => {name => 'Paul', age => {_content => 36}}], "\n",
			[student => {name => 'Martin', age => {_content => 33}}], "\n",
		],
	}
);
