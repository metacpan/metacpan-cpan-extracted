$|=1;
use XML::Rules;

open my $OUT, '>:utf8', 'test18.txt';

my $parser = new XML::Rules (
	rules => [
		'^bogus' => undef, # means "ignore". The subtags ARE NOT processed.
		'^person' => sub {
			return $_[1]->{active};
		},
#		fname => sub {print $OUT "fname: $_[1]->{_content}\n"; $_[0] => $_[1]},
		email => sub {$_[1]->{_content} = lc($_[1]->{_content}); return $_[0] => $_[1]}
	],
	style => 'filter',
#	encode => 'iso-8859-1',
	# other options
);

#$parser->filterfile( 'test18.xml', $OUT);

open my $IN, '<', 'test18.xml';
binmode $IN;
$parser->filter( $IN, $OUT);
close $IN;
