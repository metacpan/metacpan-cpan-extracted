use strict;
use XML::Rules;

my $xml = <<'*END*';
<doc>
	<set name="x"><plus><times>5 3</times> 9</plus></set>
	<print>The result is: <plus>1 -<var>x</var></plus>
</print>
	<print x="129">The result is: <plus>1 -<var>x</var></plus>
</print>
	<print>The other result is: <plus>1 2 3 4 5</plus></print>
</doc>
*END*
	use List::Util qw(reduce);
	my $parser = new XML::Rules (
		rules => [
			'times' => sub {reduce {$a * $b} split ' ', $_[1]->{_content}},
			'plus' => sub {reduce {$a + $b} split ' ', $_[1]->{_content}},
			'set' => sub {
				my ($tag_name, $tag_hash, $context, $parent_data) = @_;
				$parent_data->[-1]{$tag_hash->{name}} = $tag_hash->{_content};
#print "Defined variable $tag_hash->{name}= $tag_hash->{_content} in <$context->[-1]>\n";
				return;
			},
			'var' => sub {
				my ($tag_name, $tag_hash, $context, $parent_data) = @_;
				my $var_name = $tag_hash->{_content};
				s/^\s+//,s/\s+$// for ($var_name);

				for (my $i = $#{$parent_data}; $i>=0; $i--) {
#print "Looking for $var_name in <$context->[$i]>\n";
#print "  Found: $parent_data->[$i]{$var_name}\n" if exists($parent_data->[$i]{$var_name});
					return $parent_data->[$i]{$var_name} if exists($parent_data->[$i]{$var_name});
				}
				die "Variable $var_name not defined in current scope!\n";
			},
			'print' => sub {print $_[1]->{_content}; return;},
			'doc' => sub {},
		]
	);

my $result = $parser->parsestring($xml);
