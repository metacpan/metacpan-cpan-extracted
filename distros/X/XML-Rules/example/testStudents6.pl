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
<other><tags>with values</tags></other>
</school>
*END*

my $parser = new XML::Rules (
	start_rules => [
		_default => sub {
			if (! $_[4]->{pad}{in_interesting}) {
				if ($_[3]->[-1]) {
					print $_[3]->[-1]{_content};
					delete $_[3]->[-1]{_content};
				}
				$_[4]->{pad}{in_interesting} = 1 if ($_[0] eq 'classes');
			}
			if (! $_[4]->{pad}{in_interesting}) {
				print $_[4]->toXML($_[0], $_[1], "don't close");
			}
			return 1;
		}
	],
	rules => [
		_default => sub {
			if ($_[4]->{pad}{in_interesting}) {
				return [$_[0] => $_[1]]
			} else {
				print "$_[1]->{_content}</$_[0]>";
				return;
			}
		},
		classes => sub {
			my $add = $_[4]->{parameters}{$_[1]->{name}};

			if ($add) {
				if (ref($_[1]->{_content})) {
					push @{$_[1]->{_content}}, @$add
				} else {
					$_[1]->{_content} = [ $_[1]->{_content}, @$add];
						# there were no students in the class, the tag contained only the whitespace
				}
			}
			print $_[4]->toXML($_[0], $_[1]);
			$_[4]->{pad}{in_interesting}--;
			return;
		},
	]
);

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
