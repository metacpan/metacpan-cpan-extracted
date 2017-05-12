use strict;
use XML::Rules;

my $rules = XML::Rules->new(
	stripspaces => 7,
	rules => {
		_default => 'content',
		person => sub {
			# push the string we build to the array referenced by the {person} key in the paren tag's hash
			return '@person' => "$_[1]->{firstname} $_[1]->{lastname} ($_[1]->{age})"
		},
		list => sub {
			# only interested in the person "attribute"
			# due to the previous rule it's an arary ref
			return $_[1]->{person};
			# and this is wha the $rules->parse() will return
		}
	}
);

my $people = $rules->parse(\*DATA);

use Data::Dumper;
print Dumper($people);

__DATA__
<?xml version='1.0' encoding='UTF-8'?>
<list name="name list">
        <person>
                <firstname>Paul</firstname>
                <lastname>Rutter</lastname>
                <age>24</age>
        </person>
        <person>
                        <firstname>Ruth</firstname>
                        <lastname>Brewster</lastname>
                        <age>22</age>
        </person>
        <person>
                        <firstname>Cas</firstname>
                        <lastname>Creer</lastname>
                        <age>23</age>
        </person>
</list>
