#
# (C) Copyright 2011-2015 Sergey A. Babkin.
# This file is a part of Triceps.
# See the file COPYRIGHT for the copyright notice and license information
#
# Perl methods for the TableType class.

package Triceps::TableType;

our $VERSION = 'v2.0.1';

use Carp;

use strict;

# Find an index type by a path of index names leading from the root.
# @param self - the TableType object
# @param idxName, ... - array of names
# @return - the found index type
# If not found, confesses.
sub findIndexPath # (self, idxName, ...)
{
	my $myname = "Triceps::TableType::findIndexPath";
	my $self = shift;

	confess("$myname: idxPath must be an array of non-zero length, table type is:\n" . $self->print() . " ")
		unless ($#_ >= 0);
	my $cur = $self; # table type is the root of the tree
	my $progress = '';
	foreach my $p (@_) {
		$progress .= $p;
		$cur = $cur->findSubIndexSafe($p)
			or confess("$myname: unable to find the index type at path '$progress', table type is:\n" . $self->print() . " ");
		$progress .= '.';
	}
	return $cur;
}

# Find an index type and its key fields by a path of index names leading from the root.
# The keys include all the key fields from all the indexes in the path, in the order
# they were defined.
# @param self - the TableType object
# @param idxName, ... - array of names
# @return - the array of (found index type, keys...)
# If not found, confesses.
sub findIndexKeyPath # (self, idxName, ...)
{
	my $myname = "Triceps::TableType::findIndexKeyPath";
	my $self = shift;

	confess("$myname: idxPath must be an array of non-zero length, table type is:\n" . $self->print() . " ")
		unless ($#_ >= 0);
	my $cur = $self; # table type is the root of the tree
	my $progress = '';
	my %seenkeys;
	my @keys;
	foreach my $p (@_) {
		$progress .= $p;
		$cur = $cur->findSubIndexSafe($p) 
			or confess("$myname: unable to find the index type at path '$progress', table type is:\n" . $self->print() . " ");
		my @pkey = $cur->getKey();
		confess("$myname: the index type at path '$progress' does not have a key, table type is:\n" . $self->print() . " ")
			unless ($#pkey >= 0);
		foreach my $k (@pkey) {
			confess("$myname: the path '$progress' involves the key field '$k' twice, table type is:\n" . $self->print() . " ")
				if (exists $seenkeys{$k});
			$seenkeys{$k} = 1;
		}
		push @keys, @pkey;
		$progress .= '.';
	}
	return ($cur, @keys);
}

# Find if possible a ready index that matches the input set of key
# fields.
# @param @keyFld - names of the desired key fields
# @return - the array with the key path if found, or empty if no match found
sub findIndexPathForKeys # ($self, @keyFld1)
{
	my $myname = "Triceps::TableType::findIndexKeyPath";
	my $self = shift;

	return if ($#_ < 0); # no keys, no index

	my %keys;
	my $f;
	for $f (@_) { # hashable for easy matching against
		$keys{$f} = 1;
	}

	my @curpath; # the path of the current index
	my @curkeys = ( \%keys ); # keys for each level traversed
	my @todo = ( [$self->getSubIndexes()] ); # array of arrays of sub-indexes, by level

	# traverse the tree until find a match or run out of indexes
	OUTER: while(1) {
		my $idxlist = $todo[$#todo];
		if ($#$idxlist < 0) { # end of list, go one level up
			pop @todo;
			pop @curpath;
			pop @curkeys;
			return if ($#todo < 0); # went through everything and found no match
			next;
		}
		my $idxname = shift @$idxlist;
		my $idx = shift @$idxlist;

		my @pkey = $idx->getKey();
		next if ($#pkey < 0); # index with no key can not be used

		my %keysleft = %{$curkeys[$#curkeys]};
		for $f (@pkey) {
			next OUTER if (!exists $keysleft{$f}); # key mismatch
			delete $keysleft{$f};
		}

		# ok, by now the current index fits into the requested keys
		push @curpath, $idxname;
		return @curpath if (!scalar(%keysleft)); # found an exact match, done

		push @curkeys, \%keysleft;
		push @todo, [$idx->getSubIndexes()]; # go deeper
	}
}

# Find an existing index that matches these keys, or if none found then
# add a new one as a secondary index at the top level (the name will
# be created from the names of the fields). Either way will return
# the index type path.
#
# If the index type is added, it will always be a Hashed one
# with a Fifo under it (since supposedly the primary index would
# be alredy defined and not matching, so the required index is
# a secondary with probably multiple rows per key).
#
# This table type must be not initialized yet.
#
# Confesses on errors. Also may leave the table type with errors
# to be found during initialization.
#
# @param @keyFld - names of the desired key fields
# @return - the array with the key path
sub findOrAddIndex # ($self, @keyFld)
{
	my $myname = "Triceps::TableType::findOrAddIndex";
	my $self = shift;

	confess "$myname: no index fields specified" if ($#_ < 0);

	my @path = $self->findIndexPathForKeys(@_);
	return @path unless ($#path < 0);

	# Check that all the field names are valid, otherwise
	# it will show up at initialization time anyway but will
	# be harder to track to where it was created.
	my %rtdef = $self->getRowType()->getdef();
	for my $f (@_) {
		confess("$myname: can not use a non-existing field '$f' to create an index\n  table row type:\n  "
				. $self->getRowType()->print("  ") . "\n ")
			unless (exists $rtdef{$f});
	}

	my $idxname = "by_" . join('_', @_);
	# make sure that it doesn't conflict
	my %ihash = $self->getSubIndexes();
	while (exists $ihash{$idxname}) {
		$idxname .= '_';
	}

	my $idx = Triceps::IndexType->newHashed(key => [ @_ ]);
	$idx->addSubIndex("fifo", Triceps::IndexType->newFifo());
	$self->addSubIndex($idxname, $idx);
	return ($idxname);
}

# Copy a table type by extracting only a subsef of indexes,
# without any aggregators. This is generally used for exporting the
# table types to the other threads, supplying barely enough to keep
# the correct structure in the copied table but without any extra
# elements that the local table might have for the side computations.
#
# The path to the first leaf index is included by default.
# It is usually enough, but more indexes can be included for the
# special cases.
#
# @param @paths - list of paths to include into the copy; each path
#        is a reference to an array containing the path; all indexes
#        in the paths will be copied; 
#        a special case is when the value is not an array reference
#        but a string "NO_FIRST_LEAF": it will prevent the default
#        first leaf from being included;
#        the copying will be done in the order it is specified in the
#        arguments, so with "NO_FIRST_LEAF" the first index specified
#        will become the first leaf and thus the default index.
#        The special syntax is supported for the last element in the path:
#            "+" - copy the path to the first leaf from this level down
sub copyFundamental # ($self, @paths)
{
	my $myname = "Triceps::TableType::copyFundamental";
	my $self = shift;
	my @extra;
	my $nofirst = 0;

	while ($#_ >= 0) {
		my $p = shift;
		if ($p eq "NO_FIRST_LEAF") {
			$nofirst = 1;
		} elsif (ref($p) ne "ARRAY") {
			confess "$myname: the arguments must be either references to arrays of path strings or 'NO_FIRST_LEAF', got '$p'";
		} else {
			push @extra, $p;
		}
	}

	if (!$nofirst) {
		# The implicit first leaf amounts to prepending this.
		unshift @extra, [ "+" ];
	}

	my $newtt = Triceps::TableType->new($self->getRowType());

	foreach my $p (@extra) {
		my $curold = $self;
		my $curnew = $newtt;

		my $progress = '';
		my $toleaf = 0;
		foreach my $n (@$p) {
			confess("$myname: the '+' may occur only at the end of the path, got '" . join('.', @$p) . "'")
				if ($toleaf);
			if ($n eq "+") {
				$toleaf = 1;
				while (1) {
					my @allsub = $curold->getSubIndexes();
					last if ($#allsub < 1);

					$progress .= $allsub[0];
					my $nextnew = ( $curnew->findSubIndexSafe($allsub[0])
						or $curnew->addSubIndex($allsub[0], $allsub[1]->flatCopy())->findSubIndex($allsub[0]));
					$progress .= '.';
					$curold = $allsub[1];
					$curnew = $nextnew;
				}
			} else {
				$progress .= $n;
				my $nextold = $curold->findSubIndexSafe($n)
					or confess("$myname: unable to find the index type at path '$progress', table type is:\n" . $self->print() . " ");
				my $nextnew = ( $curnew->findSubIndexSafe($n)
					or $curnew->addSubIndex($n, $nextold->flatCopy())->findSubIndex($n));
				$progress .= '.';
				$curold = $nextold;
				$curnew = $nextnew;
			}
		}
	}

	return $newtt;
}

1;
