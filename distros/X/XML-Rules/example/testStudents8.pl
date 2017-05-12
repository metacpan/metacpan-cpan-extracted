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
      my ($tag, $attrs, $context, $parents, $parser) = @_;
      my $add = $parser->{parameters}{$attrs->{name}};

      if ($add) {
        if (ref($attrs->{_content})) {
          push @{$attrs->{_content}}, @$add
        } else {
          $attrs->{_content} = [ $attrs->{_content}, @$add];
          # there were no students in the class, the tag contained only the whitespace
        }
      }
      return $tag => $attrs; # the module will print the branch
    },
  ],
  style => 'filter', # the default is : style => 'parser'
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