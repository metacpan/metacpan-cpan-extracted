$|=1;
use XML::Rules;

$xml = <<'*END*';
<school>

<some>tag</some>

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
	rules => [
		_default => 'raw',
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
			return $_[0] => $_[1]; # once in_interesting get's to zero, we can print the stuff
		},
	],
	style => 'filter', # the other is : style => 'parser'
);

open my $OUT, '>', 'filter.txt';
$parser->filterstring($xml => $OUT,
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
close $OUT;