$VERSION = '0.01';

use strict;

package Data::Trie;

#creates a new Trie node and initializes its value and daughters to zero
sub new {
	my $self = {};
	my $class = shift;
	#does this node terminate a word?
	$self->{value} = 0;
	#is this node terminate a prefix of further words?
	$self->{daughters} = {};
	bless $self, $class;
}

#returns all words in the trie
sub getAll {
	my $self = shift;
	#keeps track of the path in the trie up to this point
	my $path = "";
	#calls a recursive routine to check the path
	return $self->_getAllRecurse($path);
}

#recursive routine to collect all words, called by getAll()
#DON'T CALL THIS DIRECTLY; use getAll() instead
sub _getAllRecurse {
	my $self = shift;
	my $path = shift;
	my $daughters = $self->{daughters};
	#the set of words to return
	my @result = ();
	#return the current path if the current node terminates a word
	if ($self->{value}) {
		push @result, $path;
	}
	my @keys = keys %$daughters;
	#check all daughter nodes recursively adding their results to current ones
	foreach my $letter (@keys) {
		my $newpath = $path . $letter;
		my @letterresult = $daughters->{$letter}->_getAllRecurse($newpath);
		push @result, @letterresult;
	}
	return @result;
}

#adds a word to the tree by recursively checking each letter of the word and
#adding nodes as needed.
sub add {
	my $self = shift;
	my $str = shift;
	#data can be added or not
	my $data = shift;
	#separates first letter from the rest
	my $first = substr $str, 0, 1;
	my $rest = substr $str, 1;
	my $daughters = $self->{daughters};
	#checks if there is a node for the first letter
	if (not exists $daughters->{$first}) {
		#adds a node if necessary
		$daughters->{$first} = Data::Trie->new;
	}
	my $daughter = $daughters->{$first};
	#is the word only one letter long?
	if (length $rest > 0) {
		#recurse on the remaining letters
		$daughter->add($rest, $data);
	} else {
		#set the value to 1 and store the data
		$daughter->{value} = 1;
		$daughter->{data} = $data;
	}
	return 1;
}

#removes a word from the trie (does NOT prune nodes)
sub remove {
	my $self = shift;
	my $str = shift;
	#splits the word into first letter and rest
	my $first = substr $str, 0, 1;
	my $rest = substr $str, 1;
	my $daughters = $self->{daughters};
	if (exists $daughters->{$first}) {
		my $daughter = $daughters->{$first};
		if (length $rest == 0) {
			$daughter->{value} = 0;
		} else {
			$daughter->remove($rest);
		}
	}
	return $str;
}

#looks up a word in the trie
sub lookup {
	my $self = shift;
	my $str = shift;
	#splits the word into first letter and rest
	my $first = substr $str, 0, 1;
	my $rest = substr $str, 1;
	my $daughters = $self->{daughters};
	#checks if the first letter matches a daughter
	if (not exists $daughters->{$first}) {
		#if not, lookup fails
		return 0;
	#if it does match, recurse on remaining letters
	} elsif (length $rest == 0) {
		return ($daughters->{$first}->{value}, $daughters->{$first}->{data});
	}	else {
		return $daughters->{$first}->lookup($rest);
	}
}

1;

=head1 NAME

Data::Trie - An implementation of a letter trie

=head1 SYNOPSIS

	use Data::Trie;
	$t = Data::Trie->new;
	$t->add('orange', 'kind of fruit');
	($result, $data) = $t->lookup->('orange');
	$t->remove('orange');
	$t->getAll;

=head1 DESCRIPTION

This module implements a letter trie data structure. This is a linked set of
nodes representing a set of words. Starting from the root, each letter of an
included word is a daughter node of the trie. Hence, if a word is in the trie,
there will be a path from root to leaf for that word. If a word is not in the
trie, there will be no such path.

This structure allows for a relatively compact representation of a set of words.
This particular implementation allows each word to be stored alone or with some
associated data item.

Note that the C<remove()> method does I<not> prune nodes and thus a C<Trie> can
only grow in size.

=head1 COMPARE

This implementation differs from L<Tree::Trie> in that C<lookup()> checks for a
match, rather than checking for whether the current string is a prefix.

=head1 VERSION

0.01

=head1 AUTHOR

Michael Hammond, I<hammond@u.arizona.edu>

=cut

