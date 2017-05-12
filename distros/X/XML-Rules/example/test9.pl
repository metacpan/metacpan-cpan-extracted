use XML::Rules;

	my $parser = new XML::Rules (
		rules => [
			_default => 'content',
			employee => sub {print "$_[1]->{name} is $_[1]->{age} years old and works in the $_[1]->{department} section\n"},
		]
	);

%attrs = (
	foo => 5,
	bar => "Pepa&syn",
	_content => 'ahoj',
	baz => {a => 12345, b => 999, _content => 'tohle je baz'},
);

print $parser->toXML( 'tag', \%attrs);