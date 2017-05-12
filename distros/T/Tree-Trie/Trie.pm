# Tree::Trie, a module implementing a trie data structure.
# A formal description of tries can be found at:
# http://www.cs.queensu.ca/home/daver/235/Notes/Tries.pdf

package Tree::Trie;

use strict;
use warnings;

our $VERSION = "1.9";

# A handful of helpful constants
use constant DEFAULT_END_MARKER => '';

use constant BOOLEAN => 0;
use constant CHOOSE  => 1;
use constant COUNT   => 2;
use constant PREFIX  => 3;
use constant EXACT   => 4;

##   Public methods begin here

# The constructor method.  It's very simple.
sub new {
	my($proto) = shift;
	my($options) = shift;
	my($class) = ref($proto) || $proto;
	my($self) = {};
	bless($self, $class);
	$self->{_MAINHASHREF} = {};
	# These are default values
	$self->{_END} = &DEFAULT_END_MARKER;
	$self->{_DEEPSEARCH} = CHOOSE;
	$self->{_FREEZE_END} = 0;
	unless ( defined($options) && (ref($options) eq "HASH") ) {
		$options = {};
	}
	$self->deepsearch($options->{'deepsearch'});
	if (exists $options->{end_marker}) {
		$self->end_marker($options->{end_marker});
	}
	if (exists $options->{freeze_end_marker}) {
		$self->freeze_end_marker($options->{freeze_end_marker});
	}
	return($self);
}

# Sets the value of the end marker, for those people who think they know
# better than Tree::Trie.  Note it does not allow the setting of single
# character end markers.
sub end_marker {
	my $self = shift;
	if ($_[0] && length $_[0] > 1) {
		# If they decide to set a new end marker, we have to be sure to
		# go through and update all existing markers.
		my $newend = shift;
		my @refs = ($self->{_MAINHASHREF});
		while (@refs) {
			my $ref = shift @refs;
			for my $key (keys %{$ref}) {
				if ($key eq $self->{_END}) {
					$ref->{$newend} = $ref->{$key};
					delete $ref->{$key};
				}
				else {
					push(@refs, $ref->{$key});
				}
			}
		}
		$self->{_END} = $newend;
	}
	return $self->{_END};
}

# Sets the option to not attempt to update the end marker based on added
# letters.
# The above is the most awkward sentence I have ever written.
sub freeze_end_marker {
	my $self = shift;
	if (scalar @_) {
		if (shift) {
			$self->{_FREEZE_END} = 1;
		}
		else {
			$self->{_FREEZE_END} = 0;
		}
	}
	return $self->{_FREEZE_END};
}

# Sets the value of the deepsearch parameter.  Can be passed either words
# describing the parameter, or their numerical equivalents.  Legal values
# are:
# boolean => 0
# choose => 1
# count => 2
# prefix => 3
# exact => 4
# See the POD for the 'lookup' method for details on this option.
sub deepsearch {
	my($self) = shift;
	my($option) = shift;
	if(defined($option)) {
		if ($option eq BOOLEAN || $option eq 'boolean') {
			$self->{_DEEPSEARCH} = BOOLEAN;
		}
		elsif ($option eq CHOOSE || $option eq 'choose') {
			$self->{_DEEPSEARCH} = CHOOSE;
		}
		elsif ($option eq COUNT || $option eq 'count') {
			$self->{_DEEPSEARCH} = COUNT;
		}
		elsif ($option eq PREFIX || $option eq 'prefix') {
			$self->{_DEEPSEARCH} = PREFIX;
		}
		elsif ($option eq EXACT || $option eq 'exact') {
			$self->{_DEEPSEARCH} = EXACT;
		}
	}
	return $self->{_DEEPSEARCH};
}

# The add() method takes a list of words as arguments and attempts to add
# them to the trie. In list context, returns a list of words successfully
# added.  In scalar context, returns a count of these words.  As of this
# version, the only reason a word can fail to be added is if it is already
# in the trie.  Or, I suppose, if there was a bug. :)
sub add {
	my($self) = shift;
	my(@words) = @_;

	my @retarray;
	my $retnum = 0;

	# Process each word...
	for my $word (@words) {
		# And just call the internal thingy for it.
		if ($self->_add_internal($word, undef)) {
			# Updating return values as needed
			if (wantarray) {
				push(@retarray,$word);
			}
			else {
				$retnum++;
			}
		}
	}
	# When done, return results.
	return (wantarray ? @retarray : $retnum);
}

# add_data() takes a hash of word => data pairs, adds the words to the trie and
# associates the data to those words.
sub add_data {
	my($self) = shift;
	my($retnum, @retarray);
	my $word = "";
	# Making sure that we've gotten data in pairs.  Can't just turn @_
	# into %data, because that would stringify arrayrefs
	while(defined($word = shift) && @_) {
		# This also just uses the internal add method.
		if ($self->_add_internal($word, shift())) {
			if (wantarray) {
				push(@retarray, $word);
			}
			else {
				$retnum++;
			}
		}
	}
	return @retarray if wantarray;
	return $retnum;
}

# add_all() takes one or more other tries and adds all of their entries
# to the trie.  If both tries have data stored for the same key, the data
# from the trie on which this method was invoked will be overwritten.  I can't
# think of anything useful to return from this method, so it has no return
# value.  If you can think of anything that would make sense, please let me
# know.
# This idea and most of its implementation come from Aaron Stone.
# Thanks!
sub add_all {
	my $self = shift;
	for my $trie (@_) {
		my $ignore_end = (
			 $self->{_FREEZE_END} ||
			($self->{_END} eq $trie->{_END})
		);
		my @nodepairs = ({
			from => $trie->{_MAINHASHREF},
			to   => $self->{_MAINHASHREF},
		});
		while (scalar @nodepairs) {
			my $np = pop @nodepairs;
			for my $letter (keys %{$np->{from}}) {
				unless ($ignore_end) {
					if ($letter eq $self->{_END}) {
						$self->end_marker($self->_gen_new_marker(
							bad => [$letter],
						));
					}
				}
				if ($letter eq $trie->{_END}) {
					$np->{to}{$self->{_END}} = $np->{from}{$trie->{_END}};
				}
				else {
					unless (exists $np->{to}{$letter}) {
						$np->{to}{$letter} = {};
					}
					push @nodepairs, {
						from => $np->{from}{$letter},
						to   => $np->{to}->{$letter},
					};
				}
			}
		}
	}
}

# delete_data() takes a list of words in the trie and deletes the associated
# data from the internal data store.  In list context, returns a list of words
# whose associated data have been removed -- in scalar context, returns a count
# thereof.
sub delete_data {
	my($self, @words) = @_;
	my($retnum, @retarray) = 0;
	my @letters;
	# Process each word...
	for my $word (@words) {
		if (ref($word) eq 'ARRAY') {
			@letters = (@{$word});
		}
		else {
			@letters = split(//, $word);
		}
		my $ref = $self->{_MAINHASHREF};
		# Walk down the tree...
		for my $letter (@letters) {
			if ($ref->{$letter}) {
				$ref = $ref->{$letter};
			}
			else {
				# This will cause the test right after this loop to fail and
				# skip the the next word -- we want that because if we're here
				# it means the word isn't in the trie.
				$ref = {};
				last;
			}
		}
		next unless (exists $ref->{$self->{_END}});
		# This is all we need to do to clear out the data
		$ref->{$self->{_END}} = undef;
		if (wantarray) {
			push(@retarray, $word);
		}
		else {
			$retnum++;
		}
	}
	if (wantarray) {
		return @retarray;
	}
	else {
		return $retnum;
	}
}

# The lookup() method searches for words (or beginnings of words) in the trie.
# It takes a single word as an argument and, in list context, returns a list
# of all the words in the trie which begin with the given word.  In scalar
# context, the return value depends on the value of the deepsearch parameter.
# An optional second argument is available:  This should be a numerical
# argument, and specifies 2 things: first, that you want only word suffixes
# to be returned, and second, the maximum length of those suffices.  All
# other configurations still apply. See the POD on this method for more
# details.
sub lookup {
	my($self) = shift;
	my($word) = shift;
	# This is the argument for doing suffix lookup.
	my($suff_length) = shift;

	# Abstraction is kind of cool
	return $self->_lookup_internal(
		word     => $word,
		suff_len => $suff_length,
		want_arr => wantarray(),
		data     => 0,
	);
}

# lookup_data() works basically the same as lookup, with the following
# exceptions -- in list context, returns a hash of ward => data pairings,
# and in scalar context, wherever it would return a word, it will instead
# return the datum associated with that word.  Note that, depending on
# the deepsearch setting, lookup_data and lookup may return exactly the
# same scalar context.
sub lookup_data {
	my($self, $word) = @_;

	return $self->_lookup_internal(
		word     => $word,
		want_arr => wantarray(),
		data     => 1,
	);
}

# The remove() method takes a list of words and, surprisingly, removes them
# from the trie.  It returns, in scalar context, the number of words removed.
# In list context, returns a list of the words removed.  As of now, the only
# reason a word would fail to be removed is if it's not in the trie in the
# first place.  Or, again, if there's a bug...  :)
sub remove {
	my($self) = shift;
	my(@words) = @_;

	my($letter,$ref) = ("","","");
	my(@letters,@ldn,@retarray);
	my($retnum) = 0;
	# The basic strategy here is as follows:
	##
	# We walk down the trie one node at a time.  If at any point, we see that a
	# node can be deleted (that is, its only child is the one which continues the
	# word we're deleting) then we mark it as the 'last deleteable'.  If at any
	# point we find a node which *cannot* be deleted (it has more children other
	# than the one for the word we're working on), then we unmark our 'last
	# deleteable' from before.  Once done, delete from the last deleteable node
	# down.

	for my $word (@words) {
		if (ref($word) eq 'ARRAY') {
			@letters = (@{$word});
		}
		else {
			@letters = split('',$word);
		}
		# For each word, we need to put the leaf node entry at the end of the list
		# of letters.  We then reset the starting ref, and @ldn, which stands for
		# 'last deleteable node'.  It contains the ref of the hash and the key to
		# be deleted.  It does not seem possible to store a value passable to
		# the 'delete' builtin in a scalar, so we're forced to do this.
		push(@letters,$self->{_END});
		$ref = $self->{_MAINHASHREF};
		@ldn = ();
		
		# This is a special case, if the first letter of the word is the only 
		# key of the main hash.  I might not really need it, but this works as
		# it is.
		if (((scalar keys(%{ $ref })) == 1) && (exists $ref->{$letters[0]})) {
			@ldn = ($ref);
		}
		# And now we go down the trie, as described above.
		while (defined($letter = shift(@letters))) {
			# We break out if we're at the end, or if we're run out of trie before
			# finding the end of the word -- that is, if the word isn't in the
			# trie.
			last if ($letter eq $self->{_END});
			last unless exists($ref->{$letter});
			if (
				scalar keys(%{ $ref->{$letter} }) == 1 &&
				exists $ref->{$letter}{$letters[0]}
			) {
				unless (scalar @ldn) {
					@ldn = ($ref,$letter);
				}
			}
			else {
				@ldn = ();
			}
			$ref = $ref->{$letter};
		}
		# If we broke out and there were still letters left in @letters, then the
		# word must not be in the trie.  Furthermore, if we got all the way to
		# the end, but there's no leaf node, the word must not be in the trie.
		next if (scalar @letters);
		next unless (exists($ref->{$self->{_END}}));
		# If @ldn is empty, then the only deleteable node is the leaf node, so
		# we set this up.
		if (scalar @ldn == 0) {
			@ldn = ($ref,$self->{_END});
		}
		# If there's only one entry in @ldn, then it's the ref of the top of our
		# Trie.  If that's marked as deleteable, then we can just nuke the entire
		# hash.
		if (scalar @ldn == 1) {
			%{ $ldn[0] } = ();
		}
		# Otherwise, we just delete the key we want to.
		else {
			delete($ldn[0]->{$ldn[1]});
		}
		# And then just return stuff.
		if (wantarray) {
			push (@retarray,$word);
		}
		else {
			$retnum++;
		}
	}
	if (wantarray) {
		return @retarray;
	}
	return $retnum;
}

## These are PRIVATE METHODS.  Don't call them directly unless you really
 # know what you're doing, or you enjoy things working funny.

# The _walktree() sub takes a word beginning and a hashref (hopefully to a trie)
# and walks down the trie, gathering all of the word endings and retuning them
# appended to the word beginning.
sub _walktree {
	my($self, %args) = @_;
	my $word = $args{word};
	my $ref = $args{ref};
	# These 2 arguments are used to control how far down the tree this
	# path will go.
	# This first argument is passed in by external subs
	my $suffix_length = $args{suf_len} || 0;
	# And this one is used only by the recursive calls.
	my $walked_suffix_length = $args{walked} || 0;

	my $wantref = ref($word) eq 'ARRAY';

	my($key) = "";
	my(@retarray) = ();
	my($ret) = 0;

	# For some reason, I used to think this was complicated and had a lot of 
	# stupid, useless code here.  It's a lot simpler now.  If the key we find 
	# is our magic reference, then we just give back the word.  Otherwise, we 
	# walk down the new subtree we've discovered.
	foreach $key (keys %{ $ref }) {
		if ($key eq $self->{_END}) {
			if (wantarray) {
				push(@retarray,$word);
				if ($args{data}) {
					push(@retarray, $ref->{$key});
				}
			}
			else {
				$ret++;
			}
			next;
		}
		my $nextval = $wantref ? [(@{$word}), $key] : $word . $key;
		# If we've reached the max depth we need to travel for the suffix (if
		# specified), then stop and collect everything up.
		if ($suffix_length > 0 && ($suffix_length - $walked_suffix_length == 1)) {
			if (wantarray) {
				push(@retarray, $nextval);
			}
			else {
				$ret++;
			}
		}
		else {
			# Look, recursion!
			my %arguments = (
				word    => $nextval,
				'ref'   => $ref->{$key},
				suf_len => $suffix_length,
				walked  => $walked_suffix_length + 1,
				data    => $args{data},
			);
			if (wantarray) {
				push(@retarray, $self->_walktree(%arguments));
			}
			else {
				$ret += scalar $self->_walktree(%arguments);
			}
		}
	}
	if (wantarray) {
		return @retarray;
	}
	else {
		return $ret;
	}
}

# This code used to use some fairly hoary recursive code which caused it to
# run fairly slowly, mainly due to the relatively slow way that perl handles
# OO method invocation.  This was pointed out to me by Justin Hicks, and he
# helped me fix it up, to be quite a bit more reasonable now.
sub _lookup_internal {
	my $self = shift;
	my %args = @_;
	my($ref) = $self->{_MAINHASHREF};

	my($letter, $nextletter) = ("", "");
	my(@letters) = ();
	my(@retarray) = ();
	my($wantref) = 0;

	my $word = $args{word};

	# Here we split the word up into letters in the appropriate way.
	if (ref($word) eq 'ARRAY') {
		@letters = (@{$word});
		# Keeping track of what kind of word it was.
		$wantref = 1;
	}
	else {
		@letters = split('',$word);
	}

	# These three are to keep hold of possibly returned values.
	my $lastword = $wantref ? [] : "";
	my $lastwordref = undef;
	my $pref = $wantref ? [] : "";

	# Like everything else, we step across each letter.
	while(defined($letter = shift(@letters))) {
		# This is to keep track of stuff for the "prefix" version of deepsearch.
		if ($self->{_DEEPSEARCH} == PREFIX && !$args{want_arr}) {
			if (exists $ref->{$self->{_END}}) {
				# The "data" argument tells us if we want to return the word
				# or the data associated with it.
				if ($args{data}) {
					$lastwordref = $ref;
				}
				elsif ($wantref) {
					push(@{$lastword}, @{$pref});
				}
				else {
					$lastword .= $pref;
				}
				$pref = $wantref ? [] : "";
			}
			unless ($args{data}) {
				if ($wantref) {
					push(@{$pref}, $letter);
				}
				else {
					$pref .= $letter;
				}
			}
		}
		# If, at any point, we find that we've run out of tree before we've run out
		# of word, then there is nothing in the trie that begins with the input 
		# word, so we return appropriately.
		unless (exists $ref->{$letter}) {
			# Array case.
			if ($args{want_arr}) {
				return ();
			}
			# "count" case.
			elsif ($self->{_DEEPSEARCH} == COUNT) {
				return 0;
			}
			# "prefix" case.
			elsif ($self->{_DEEPSEARCH} == PREFIX) {
				if ($args{data} && $lastwordref) {
					return $lastwordref->{$self->{_END}};
				}
				if (($wantref && scalar @{$lastword}) || length $lastword) {
					return $lastword;
				}
				return undef;
			}
			# All other deepsearch cases are the same.
			else {
				return undef;
			}
		}
		# If the letter is there, we just walk one step down the trie.
		$ref = $ref->{$letter};
	}
	# Once we've walked all the way down the tree to the end of the word we were
	# given, there are a few things that can be done, depending on the context
	# that the method was called in.
	if ($args{want_arr}) {
		# If they want an array, then we use the walktree subroutine to collect all
		# of the words beneath our current location in the trie, and return them.
		@retarray = $self->_walktree(
			# When fetching suffixes, we don't want to give the word begnning.
			word    => $args{suff_len} ? "" : $word,
			'ref'   => $ref,
			suf_len => $args{suff_len},
			data    => $args{data},
		);
		return @retarray;
	}
	else {
		if ($self->{_DEEPSEARCH} == BOOLEAN) {
			# Here, the user only wants to know if any words in the trie begin 
			# with their word, so that's what we give them.
			return 1;
		}
		elsif ($self->{_DEEPSEARCH} == EXACT) {
			# In this case, the user wants us to return something only if the
			# exact word exists in the trie, and undef otherwise.
			# This option only really makes sense with when looking up data,
			# as otherwise it's essentially the same as BOOLEAN, above, but it
			# doesn't hurt to allow it to work with normal lookup, either.
			# I'd initially left this out because I didn't see a use for it, but
			# thanks to Otmal Lendl for pointing out to me a situation in which
			# it would be helpful to have.
			if (exists $ref->{$self->{_END}}) {
				if ($args{data}) {
					return $ref->{$self->{_END}};
				}
				return $word;
			}
			return undef;
		}
		elsif ($self->{_DEEPSEARCH} == CHOOSE) {
			# If they want this, then we continue to walk down the trie, collecting
			# letters, until we find a leaf node, at which point we stop.  Note that
			# this works properly if the exact word is in the trie.  Yay.
			# Of course, making it work that way means that we tend to get shorter
			# words in choose...  is this a bad thing?  I dunno.
			my($stub) = $wantref ? [] : "";
			while (scalar keys %{$ref} && !exists $ref->{$self->{_END}}) {
				$nextletter = each(%{ $ref });
				# I need to call this to clear the each() call.  Wish I didn't...
				keys(%{ $ref });
				if ($wantref) {
					push(@{$stub}, $nextletter);
				}
				else {
					$stub .= $nextletter;
				}
				$ref = $ref->{$nextletter};
				# If we're doing suffixes, bail out early once it's the right length.
				if ($args{suff_len}) {
					my $cmpr = $wantref ? scalar @{$stub} : length $stub;
					last if $cmpr == $args{suff_len};
				}
			}
			if ($args{data}) {
				return $ref->{$self->{_END}};
			}
			# If they've specified a suffix length, then they don't want the
			# beginning part of the word.
			if ($args{suff_len}) {
				return $stub;
			}
			# Otherwise, they do.
			else {
				return $wantref ? [@{$word}, @{$stub}] : $word . $stub;
			}
		}
		elsif ($self->{_DEEPSEARCH} == COUNT) {
			# Here, the user simply wants a count of words in the trie that begin
			# with their word, so we get that by calling our walktree method in 
			# scalar context.
			return scalar $self->_walktree(
				# When fetching suffixes, we don't want to give the word begnning.
				word    => $args{suff_len} ? "" : $word,
				'ref'   => $ref,
				suf_len => $args{suff_len},
			);
		}
		elsif ($self->{_DEEPSEARCH} == PREFIX) {
			# This is the "longest prefix found" case.
			if (exists $ref->{$self->{_END}}) {
				if ($args{data}) {
					return $ref->{$self->{_END}};
				}
				if ($wantref) {
					return [@{$lastword}, @{$pref}];
				}
				else {
					return $lastword . $pref;
				}
			}
			if ($args{data}) {
				return $lastwordref->{$self->{_END}};
			}
			return $lastword;
		}
	}
}

# This is the method which does all of the heavy lifting for add and
# add_data.  Given a word and a datum, it walks down the trie until
# it finds a branch that hasn't been created yet.  It then makes the rest
# of the branch, and slaps an end marker and the datum inside of it.
sub _add_internal {
	my $self = shift;
	my $word = shift;
	my $datum = shift;
	my @letters;
	# We don't NEED to split a string into letters; Any array of tokens
	# will do.
	if (ref($word) eq 'ARRAY') {
		# Note: this is a copy
		@letters = (@{$word});
		# Because in this case, a "letter" can be more than on character
		# long, we have to make sure we don't collide with whatever we're
		# using as an end marker.
		# However, if the user is feeling all fanciful and told us not to
		# bother, we won't.
		unless ($self->{_FREEZE_END}) {
			for my $letter (@letters) {
				if ($letter eq $self->{_END}) {
					# If we had a collision, then make a new end marker.
					$self->end_marker($self->_gen_new_marker(
						bad => \@letters,
					));
					last;
				}
			}
		}
	}
	else {
		@letters = split('',$word);
	}
	# Start at the top of the Trie...
	my $ref = $self->{_MAINHASHREF};
	# This will walk down the trie as far as it can, until it either runs
	# out of word or out of trie.
	while (
		(scalar @letters) &&
		exists($ref->{$letters[0]})
	) {
		$ref = $ref->{shift(@letters)};
	}
	# If it ran out of trie before it ran out of word then this will create
	# the rest of the trie structure.
	for my $letter (@letters) {
		$ref = $ref->{$letter} = {};
	}
	# In either case, this will make the new end marker for the end of the
	# word (assuming it wasn't already there) and set the return value
	# appropriately.
	my $ret = 1;
	if (exists $ref->{$self->{_END}}) {
		$ret = 0;
	}
	else {
		$ref->{$self->{_END}} = undef;
	}
	# This will set the data if it was provided.
	if (defined $datum) {
		$ref->{$self->{_END}} = $datum;
	}
	return $ret;
}

# This uses a heuristic (that is, a crappy method) to generate a new
# end marker for the trie.  In addition to being sure that whatever is
# generated is not in use as a letter in the trie, it also makes a bold
# yet mostly vain attempt to try to make something that might not be
# used in the future.
# In general, I do not try to make this functionality good or fast or
# perfect -- if it's being called often, the module is being mis-used.
# If a user is using multi-character letters, then they ought to find
# a string that will be safe and set it themselves.
sub _gen_new_marker {
	my $self = shift;
	my %args = @_;
	# This will keep track of all of the letters used in the trie already
	my %used = ();
	# This will keep track of what lengths they are
	my %sizes = ();
	# First we process the letters of the word which sparked this
	# re-evaluation.
	for my $letter (@{$args{bad}}) {
		my $len = length($letter);
		if ($len != 1) {
			$used{$letter}++;
			$sizes{$len}++;
		}
	}
	# Then we walk the tree and get the info on all the other letters.
	my @refs = ($self->{_MAINHASHREF});
	while (@refs) {
		my $ref = shift @refs;
		for my $key (keys %{$ref}) {
			# Note we don't even care about length 1 letters.
			if (
				(length($key) != 1) &&
				($key ne $self->{_END})
			) {
				$used{$key}++;
				$sizes{length($key)}++;
				push(@refs, $ref->{$key});
			}
		}
	}
	# The idea here is that we want to make the end marker as small as possible,
	# as it's stuck all over the place.  However, we don't want to spend forever
	# trying to find one that isn't in use.
	# So, we find the smallest length such that there are fewer than 1/4 of
	# the total number of possible letters in use of that length, and we make
	# a key of that length.
	my $newlen = 2;
	for my $len (sort keys %sizes) {
		# Yes, I know there are well more than 26 available compositors, but
		# this will only mean I'm being too careful.
		if ($sizes{$len} < ((26 ** $len) / 4)) {
			$newlen = $len;
			last;
		}
		else {
			# This makes it so that if all existing lengths are too full ( !! )
			# then we will just use a key that's one longer than the longest
			# one already there.
			$newlen = $len + 1;
		}
	}
	# Now we just generate end markers until we find one that isn't in use.
	my $newend;
	do {
		$newend = join '', map { chr(int(rand(128))) } (('') x $newlen);
	} while (exists($used{$newend}));
	# And return it.
	return $newend;
}

# Strewth!
1;

__END__

=head1 NAME


Tree::Trie - A data structure optimized for prefix lookup.

=head1 SYNOPSIS

 use Tree::Trie;
 use strict;

 my($trie) = new Tree::Trie;
 $trie->add(qw[aeode calliope clio erato euterpe melete melpomene mneme 
   polymnia terpsichore thalia urania]);
 my(@all) = $trie->lookup("");
 my(@ms)  = $trie->lookup("m");
 $" = "--";
 print "All muses: @all\nMuses beginning with 'm': @ms\n";
 my(@deleted) = $trie->remove(qw[calliope thalia doc]);
 print "Deleted muses: @deleted\n";
 

=head1 DESCRIPTION

This module implements a trie data structure.  The term "trie" comes from the
word reB<trie>val, but is generally pronounced like "try".  A trie is a tree
structure (or directed acyclic graph), the nodes of which represent letters 
in a word.  For example, the final lookup for the word 'bob' would look 
something like C<$ref-E<gt>{'b'}{'o'}{'b'}{'00'}> (the 00 being an
end marker).  Only nodes which would represent words in the trie exist, making
the structure slightly smaller than a hash of the same data set.

The advantages of the trie over other data storage methods is that lookup
times are O(1) WRT the size of the index.  For sparse data sets, it is probably
not as efficient as performing a binary search on a sorted list, and for small
files, it has a lot of overhead.  The main advantage (at least from my 
perspective) is that it provides a relatively cheap method for finding a list
of words in a large, dense data set which B<begin> with a certain string.

The term "word" in this documentation can refer to one of two things: either a
reference to an array of strings, or a scalar which is not a reference.  In
the case of the former, each element of the array is treated as a "letter"
of the "word".  In the case of the latter, the scalar is evaluated in string
context and it is split into its component letters.  Return values of methods
match the values of what is passed in -- that is, if you call lookup() with
an array reference, the return value will be an array reference (if
appropriate).

NOTE: The return semantics of the lookup_data method have CHANGED from version
1.0 to version 1.1.  If you use this method, be sure to see the perldoc on
that method for details.

=head1 METHODS

=over 4


=item new()

=item new({I<option0> => I<value0>, I<option1> => I<value1>, ...})

This is the constructor method for the class.  You may optionally pass it
a hash reference with a set of I<option> => I<value> pairs.  The options
which can be set at object creation-time are "deepsearch", "end_marker" and
"freeze_end_marker".  See the documentation on the methods which set and
report those values for more information.

=item $trie->add(I<I<word>>, I<word1>, ...)

This method attempts to add the words to the trie.  Returns, in list
context, the words successfully added to the trie.  In scalar context, returns
the number of words successfully added.  As of this release, the only reason
a word would fail to be added is if it is already in the trie.

=item $trie->add_all(I<I<trie>>, I<trie1>, ...)

This method adds all of the words from the argument tries to the trie.  By
performing the traversal of both source and target tries simultaneously,
this mechanism is much faster first doing a lookup on one trie and then an
add on the other.  Has no return value.

=item $trie->add_data(I<I<word>> => I<data0>, I<word1> => I<data1>, ...)

This method works in basically the same way as C<add()>, except in addition to
adding words to the trie, it also adds data associated with those words.  Data
values may be overwritten by adding data for words already in the trie.  Its
return value is the same and applies only to new words added to the trie, not
data modified in existing words.

=item $trie->remove(I<I<word>>, I<word1>, ...)

This method attempts to remove the words from the trie.  Returns, in
list context, the words successfully removed from the trie.  In scalar context,
returns the number of words successfully removed.  As of this release, the only
reason a word would fail to be removed is if it is not already in the trie.

=item $trie->delete_data(I<I<word>>, I<word1>, ...)

This method simply deletes data associated with words in the trie.  It
is the equivalent to perl's delete builtin operating on a hash.  It returns
the number of data items deleted in scalar context, or a list of words
for which data has been removed, in list context.

=item $trie->lookup(I<word>)

=item $trie->lookup(I<word>, I<suffix_length>)

This method performs lookups on the trie.  In list context, it returns a
complete list of words in the trie which begin with I<word>.
In scalar context, the value returned depends on the setting of the 'deepsearch'
option.  You can set this option while creating your Trie object, or by using
the deepsearch method.  Valid deepsearch values are:

boolean: Will return a true value if any word in the trie begins with I<word>.
This setting is the fastest.

choose: Will return one word in the trie that begins with I<word>, or undef if
nothing is found.  If I<word> exists in the trie exactly, it will be returned.

count: Will return a count of the words in the trie that begin with I<word>.
This operation may require walking the entire tree, so it can possibly be
significantly slower than other options.

prefix: Will return the longest entry in the trie that is a prefix of I<word>.
For example, if you had a list of file system mount points in your trie, you
could use this option, pass in the full path of a file, and would be returned
the name of the mount point on which the file could be found.

exact: If the exact word searched for exists in the trie, will return that
word (or the data associated therewith), undef otherwise.  This is essentially
equivalent to a hash lookup, but it does have utility in some cases.

For reasons of backwards compatibility, 'choose' is the default value
of this option.

To get a list of all words in the trie, use C<lookup("")> in list context.

If the I<suffix_length> option is provided, the behavior is a little bit
different:  Instead of returning words from the trie, it will instead return
suffixes that follow I<word>, and those suffixes will be no longer than the
numerical value of the option.  If the option's value is negative, suffixes
of all lengths will be returned.  This option only has effect if the
call to lookup() is in list context, or if the 'deepsearch' parameter
is set to either 'count' or 'choose'.  It has no meaning for the other
scalar deepsearch settings, and will be ignored in those cases.

For example, assume your trie contains 'foo', 'food' and 'fish'.
C<lookup('f', 1)> would return 'o' and 'i'.  C<lookup('f', 3)> would
return 'oo', 'ood' and 'ish'.  C<lookup('fo', -1)> would return 'o' and
'od'.  In scalar context, these calls would return what you'd expect, based
on the value of deepsearch, with the 'count' and 'choose' options operating
only over the set of suffixes.  That is, The first call would return 2
with 'count', and either 'o' or 'i' with 'choose'.

Note that C<lookup("", -1)> is the same as C<lookup("")>.

=item $trie->lookup_data(I<word>)

This method operates in essentially the same way as C<lookup()>, with the
exception that in list context it returns a list of word => data value
pairs and in scalar context, where C<lookup()> would return a word,
C<lookup_data()> returns the data value associated with that word.  In
cases where the deepsearch setting is such that C<lookup()> would
return a number, C<lookup_data()> will return the same number.

Please note that the return value in list context is NOT a hash.  It can
be coerced into a hash, and if you are not using any multi-character letters
in your trie, this will work fine.  However otherwise, if it is coerced into
a hash, all the of the array references (remember, words are array refs when
using multi-character letters) will be stringified, which renders them (for
the most part) useless.

=item $trie->deepsearch()

=item $trie->deepsearch(I<new_setting>)

If option is specified, sets the deepsearch parameter.  Option may be one of:
'boolean', 'choose', 'count', 'prefix'.  Please see the documentation for the
lookup method for the details of what these options mean.  Returns the
current (new) value of the deepsearch parameter.

=item $trie->end_marker()

=item $trie->end_marker(I<new_marker>)

If the marker is provided, sets the string used internally to indicate the
end of a word in the trie to that marker.  Doing this causes a complete
traversal of the trie, where all old end markers are replaced with the new
one.  This can get very slow, so try to call this method when the trie is
still small.  Returns the current (new) end marker value.

=item $trie->freeze_end_marker()

=item $trie->freeze_end_marker(I<new_flag>)

If flag is provided and a true value, turns off checking and automatic
updating of the end marker.  If flag is provided and false, turns this
checking on.  Returns the current (new) truth value of this setting.

=back

=head1 End Markers

=head2 Overview

The following discussion is only important for those people using
multi-character letters, or words as array references.  If you are just
using this module with words as simple strings, you may disregard this
section.

First, it's important to understand how data is stored in the trie.  As
described above, the trie structure is basically just a complicated hash of
hashes, with each key of each has being a letter.  There needs to be a distinct
way of determining when we're at the end of a word; we can't just use the
end of the hash structure as a guide, because we need to distinguish between
the word "barn" being in the trie and the words "bar" and "barn" being there.

The answer is an end marker -- a distinct token that signifies that we're
at the end of the word.  Using the above example, if "bar" and "barn" are
in the trie, then the keys of the hash at "r" would be "n" and this end
marker.  Choosing this end marker is easy when all letters are just one
character -- we just choose any two-character string and we know that it will
never match a letter.  However, once we allow arbitrary multi-character
letters, then things get much more difficult: there is no possible end
marker which can be guaranteed to always work.  Here is where we enter
some dark water.

=head2 Dark Water

In order to make sure that the end marker is always safe, we must check
incoming letters on every word submission.  If the word is an array ref, then
each letter in it is compared to the current end marker.  This does add
overhead, but it's necessary.  If it is found that a letter does conflict
with the end marker, then we choose a new end marker.

In order to find a new end marker, we obviously need to find a string that
isn't already being used in the trie.  This requires a complete traversal of
the trie to collect a complete set of the letters in use.  Once we have this
it is a simple exercise to generate a new marker which is not in use.

Then we must replace the marker.  This of course requires a complete
traversal once again.  As you can see, this adds a bit of overhead to working
with multi-character letters, but it's neccessary to make sure things keep
working correctly.  This should be fine for people with small data sets,
or who just do a bunch of additions ahead of time and then only do lookups.
However, if computation time is important to you, there are ways to
avoid this mess.

=head2 Speeding Things Up

One way to speed things up is to avoid the need to replace the end marker.
You can set the trie's end marker using the C<end_marker()> method, or at
creation time, by passing the C<end_marker> option to the trie in its
constructor's option hashref.  Note that setting the end marker causes
a trie traversal, as it must update existing data.  As such, you want to
set the end marker as soon as possible.

Note that end marker MUST be at least 2 characters long.

Just setting the end marker though, won't stop the trie from checking each
letter as you add arrayref words.  If you are 100% sure that the end
marker you set won't ever show up in an added word, you can either use
the C<freeze_end_marker()> method or the C<freeze_end_marker> construction
option to tell the trie not to check any more.  However, be careful --
once this option is enabled, the data structure is no longer self-policing,
so if a letter that matches your end marker does end up slipping in, strange
things will begin to happen.

=head2 Examples

Here are some situations in which you might want to use the methods described
in the previous section.

Let's say your application takes user input data describing travel across
the united states, and each node in the trie is a two-letter state abbreviation.
In this case, it would probably be fairly safe to set your end marker to
something like '00'.  However, since this is user-supplied data, you don't
want to let some user break your whole system by entering '00', so you should
probably not freeze the end marker in this case.

Let's say you're using the trie for a networking application -- your words
will be IP addresses, and your letters will be the four "quads" of an IP
address.  In this case you can safely set your end marker to 'xx' or anything
with letters in it, and know that there will never be a collision.  It is
entirely reasonable to set the freeze tag in this case.

=head1 Future Work

=over 4

=item *

There are a few methods of compression that allow you same some amount of space 
in the trie.  I have to figure out which ones are worth implementing.  I may
end up making the different compression methods configurable.

I have now made one of them the default.  It's the least effective one, of
course.

=item *

The ability to have Tree::Trie be backed by a "live" file instead of keeping
data in memory.  This is, unfortunately, more complicated than simply using
TIE, so this will take some amount of work.

=back

=head1 Known Problems

=over 4

=item *

None at this time.

=back

=head1 AUTHOR

Copyright 2011 Avi Finkel <F<avi@finkel.org>>

This package is free software and is provided "as is" without express
or implied warranty.  It may be used, redistributed and/or modified
under the terms of the Perl Artistic License (see
http://www.perl.com/perl/misc/Artistic.html)

=cut
