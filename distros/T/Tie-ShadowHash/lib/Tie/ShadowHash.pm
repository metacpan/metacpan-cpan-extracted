# Tie::ShadowHash -- Merge multiple data sources into a hash.
#
# This module combines multiple sources of data into a single tied hash, so
# that they can all be queried simultaneously, the source of any given
# key-value pair irrelevant to the client script.  Data sources are searched
# in the order that they're added to the shadow hash.  Changes to the hashed
# data aren't propagated back to the actual data files; instead, they're saved
# within the tied hash and override any data obtained from the data sources.
#
# SPDX-License-Identifier: GPL-1.0-or-later OR Artistic-1.0-Perl

##############################################################################
# Modules and declarations
##############################################################################

package Tie::ShadowHash 2.01;

use 5.024;
use autodie;
use warnings;

use Carp qw(croak);

##############################################################################
# Regular methods
##############################################################################

# Given a file name and optionally a split regex, builds a hash out of the
# contents of the file.
#
# If the split sub exists, use it to split each line into an array; if the
# array has two elements, those are taken as the key and value.  If there are
# more, the value is an anonymous array containing everything but the first.
#
# If there's no split sub, take the entire line modulo the line terminator as
# the key and the value the number of times it occurs in the file.
#
# $file  - File containing the data
# $split - Optional anonymous sub that splits a line into key and value
#
# Returns: Hash created by loading the file
sub _text_source {
    my ($self, $file, $split) = @_;
    my %hash;
    open(my $fh, '<', $file);
    while (defined(my $line = <$fh>)) {
        chomp($line);
        if (defined($split)) {
            my ($key, @rest) = $split->($line);
            $hash{$key} = (@rest == 1) ? $rest[0] : [@rest];
        } else {
            $hash{$line}++;
        }
    }
    close($fh);
    return \%hash;
}

# Add data sources to the shadow hash.
#
# Each data source is one of the following:
#
# - An anonymous array, in which case the first element is the type of source
#   and the rest are arguments.  Currently, "text" is the only supported type.
#
# - A file name, which is taken to be a text file with each line as a key and
#   a value equal to the number of times that line appears.
#
# - A hash reference, possibly to a tied hash.
#
# @sources - Data sources to add
#
# Returns: True
sub add {
    my ($self, @sources) = @_;
    for my $source (@sources) {
        if (ref($source) eq 'ARRAY') {
            my ($type, @args) = $source->@*;
            if ($type eq 'text') {
                $source = $self->_text_source(@args);
            } else {
                croak("invalid source type $type");
            }
        } elsif (!ref($source)) {
            $source = $self->_text_source($source);
        }
        push($self->{SOURCES}->@*, $source);
    }
    return 1;
}

##############################################################################
# Tie methods
##############################################################################

# Create a new tied hash.
#
# @sources - Sources to add to the new hash
#
# Returns: Newly created tied hash
sub TIEHASH {
    my ($class, @sources) = @_;
    $class = ref($class) || $class;
    #<<<
    my $self = {
        DELETED  => {},  # All keys that have been deleted
        EACH     => -1,  # Index of source currently being traversed
        OVERRIDE => {},  # Values set directly by the user
        SOURCES  => [],  # Array of all of the underlying hashes
    };
    #>>>
    bless($self, $class);
    $self->add(@sources);
    return $self;
}

# Retrieve a value.
#
# This doesn't work quite right in the case of keys with undefined values, but
# we can't make it work right since that would require using exists and a lot
# of common data sources (such as NDBM_File tied hashes) don't implement
# exists.
#
# $key - Key to look up
#
# Returns: Value for that key, undef if it is not present
sub FETCH {
    my ($self, $key) = @_;
    if ($self->{DELETED}{$key}) {
        return;
    } elsif (exists($self->{OVERRIDE}{$key})) {
        return $self->{OVERRIDE}{$key};
    } else {
        for my $source ($self->{SOURCES}->@*) {
            if (defined($source->{$key})) {
                return $source->{$key};
            }
        }
        return;
    }
}

# Store a value.  This goes into the override hash, which is checked before
# any of the underlying data sources.
#
# $key   - Key to store a value for
# $value - Value to store
sub STORE {
    my ($self, $key, $value) = @_;
    delete $self->{DELETED}{$key};
    $self->{OVERRIDE}{$key} = $value;
    return;
}

# Delete a key.  The key is flagged in the deleted hash, which ensures that
# undef will be returned for any future retrieval.  Dropping the override
# value isn't required for currect future FETCH behavior, but it drops the
# reference so that memory can be released.
#
# $key - Key to delete
sub DELETE {
    my ($self, $key) = @_;
    delete $self->{OVERRIDE}{$key};
    $self->{DELETED}{$key} = 1;
    return;
}

# Clear the hash.  Removes all sources and all overrides and resets any
# iteration.
sub CLEAR {
    my ($self) = @_;
    $self->{DELETED} = {};
    $self->{OVERRIDE} = {};
    $self->{SOURCES} = [];
    $self->{EACH} = -1;
    return;
}

# Return whether a key exists.
#
# This could throw an exception if any underlying source doesn't support
# exists (like NDBM_File).
#
# $key - Key to query for existence
#
# Returns: True if the key exists, false otherwise
sub EXISTS {
    my ($self, $key) = @_;
    return if exists($self->{DELETED}{$key});
    for my $source ($self->{OVERRIDE}, $self->{SOURCES}->@*) {
        return 1 if exists($source->{$key});
    }
    return;
}

# Start an iteration.
#
# We have to reset the each counter on all hashes.  For tied hashes, we call
# FIRSTKEY directly because it's potentially more efficient than calling keys
# on the hash.
sub FIRSTKEY {
    my ($self) = @_;
    keys($self->{OVERRIDE}->%*);
    for my $source ($self->{SOURCES}->@*) {
        my $tie = tied($source);
        if ($tie) {
            $tie->FIRSTKEY();
        } else {
            keys($source->%*);
        }
    }
    $self->{EACH} = -1;
    return $self->NEXTKEY();
}

# Iterate through the hashes.
#
# Walk the sources by calling each on each one in turn, skipping deleted keys
# and keys shadowed by earlier hashes and using $self->{EACH} to store the
# number of source we're at.
#
# Returns: Next key in iteration, or undef if sources are exhausted
sub NEXTKEY {
    my ($self) = @_;

    # EACH is the numeric index in the SOURCES list for the source we're
    # currently calling each on, or -1 if we're just starting and thus
    # operating on the OVERRIDE hash.
    #
    # We have to loop until we find the next value, which may take several
    # iterations since keys could have been overridden by an earlier hash or
    # deleted.
  SOURCE:
    while ($self->{EACH} < $self->{SOURCES}->@*) {
        my $key;

        ## no critic (Each)
        if ($self->{EACH} == -1) {
            $key = each($self->{OVERRIDE}->%*);
        } else {
            $key = each($self->{SOURCES}[$self->{EACH}]->%*);
        }
        ## use critic

        # If we got a valid result, we have to check against DELETED,
        # OVERRIDE, and all earlier sources before returning it.
        if (defined($key)) {
            if ($self->{DELETED}{$key}) {
                next;
            } elsif ($self->{EACH} >= 0 && exists($self->{OVERRIDE}{$key})) {
                next;
            } elsif ($self->{EACH} > 0) {
                for my $index (reverse(0 .. $self->{EACH} - 1)) {
                    if (defined($self->{SOURCES}[$index]{$key})) {
                        next SOURCE;
                    }
                }
            }
            return $key;
        }
        $self->{EACH}++;
    }

    # We have exhausted all of the sources.
    return;
}

##############################################################################
# Module return value and documentation
##############################################################################

# Make sure the module returns true.
1;

__DATA__

=head1 NAME

Tie::ShadowHash - Merge multiple data sources into a hash

=for stopwords
DBM Allbery

=head1 SYNOPSIS

    use Tie::ShadowHash;
    use AnyDBM_File;
    use Fcntl qw(O_RDONLY);
    tie(my %db, 'AnyDBM_File', 'file', O_RDONLY, oct('666'));
    my $obj = tie(my %hash, 'Tie::ShadowHash', \%db, 'otherdata.txt');

    # Accesses search %db first, then the hashed otherdata.txt.
    print "$hash{key}\n";

    # Changes override data sources, but don't change them.
    $hash{key} = 'foo';
    delete $hash{bar};

    # Add more data sources on the fly.
    my %extra = (fee => 'fi', foe => 'fum');
    $obj->add(\%extra);

    # Add a text file as a data source, taking the first "word" up
    # to whitespace on each line as the key and the rest of the line
    # as the value.
    my $split = sub { my ($line) = @_; split(q{ }, $line, 2) };
    $obj->add([text => "pairs.txt", $split]);

    # Add a text file as a data source, splitting each line on
    # whitespace and taking the first "word" to be the key and an
    # anonymous array consisting of the remaining words to be the
    # data.
    $split = sub { my ($line) = @_; split(q{ }, $line) };
    $obj->add([text => "triples.txt", $split]);

=head1 DESCRIPTION

This module merges together multiple sets of data in the form of hashes into a
data structure that looks to Perl like a single simple hash.  When that hash
is accessed, the data structures managed by that shadow hash are searched in
order they were added for that key.  This allows the rest of a program simple
and convenient access to a disparate set of data sources.

The shadow hash can be modified, and the modifications override the data
sources, but modifications aren't propagated back to the data sources.  In
other words, the shadow hash treats all data sources as read-only and saves
your modifications in an overlay in memory.  This lets you make changes to the
shadow hash and have them reflected later in your program without affecting
the underlying data in any way.  This behavior is the reason why it is called
a shadow hash.

=head1 Constructing the hash

Tie::ShadowHash takes one or more underlying data sources as additional
arguments to tie().  Data sources can also be added later by calling the add()
method on the object returned by tie().

A data source can be anything that looks like a hash.  This includes other
tied hashes, so you can include DB and DBM files as data sources for a shadow
hash.

If the data source is a scalar string instead of a hash reference,
Tie::ShadowHash will treat that string as a file name and construct a hash
from it.  Each chomped line of the file will be a key, and the number of times
that line is seen in the file will be the corresponding value.

Tie::Shadowhash also supports special tagged data sources that can take
options specifying their behavior.  Tagged data sources are distinguished from
normal data sources by passing them to tie() or add() as an array reference.
The first element is the data source tag and the remaining elements are
arguments for that data source.  The following tagged data sources are
supported:

=over 4

=item C<text>

The arguments must be the file name of a text file and a reference to a sub.
The sub is called for every line of the file, with that line as an argument,
and is expected to return a list.  The first element of the list will be the
key, and the second and subsequent elements will be the value or values.  If
there is more than one value, the value stored in the hash and associated with
that key is an anonymous array containing all of them.  See the usage summary
above for examples.

=back

=head1 Clearing the hash

If the shadow hash is cleared by assigning the empty list to it, calling
CLEAR(), or some other method, all data sources are dropped from the shadow
hash.  There is no other way of removing a data source from a shadow hash
after it's been added (you can, of course, always untie the shadow hash and
dispose of the underlying object if you saved it to destroy the shadow hash
completely).

=head1 INSTANCE METHODS

=over 4

=item add(SOURCE [, SOURCE ...])

Adds the given sources to an existing shadow hash.  This method can be called
on the object returned by the initial tie() call.  It takes the same arguments
as the initial tie() and interprets them the same way.

=back

=head1 DIAGNOSTICS

=over 4

=item invalid source type %s

Tie::ShadowHash was given a tagged data source of an unknown type.  The only
currently supported tagged data source is C<text>.

=back

If given a file name as a data source, Tie::ShadowHash will also raise an
L<autodie> exception if there is a problem with opening or reading that file.

=head1 CAVEATS

=head2 Iterating

If you iterate through the keys of a shadow hash, it in turn will iterate
through the keys of the underlying hash.  Since Perl stores only one iterator
position per hash, this means the shadow hash will reset any existing iterator
positions in its underlying hashes.  Iterating through both the shadow hash
and one of its underlying hashes at the same time is undefined and will
probably not do what you expect.

=head2 untie

If you are including tied hashes in a shadow hash, read L<perltie/The "untie"
Gotcha>. Tie::ShadowHash stores a reference to those hashes.  If you untie
them out from under a shadow hash, you may not get the results you expect.  If
you put something in a shadow hash, you'll need to clean out the shadow hash
as well as everything else that references a variable if you want to free it
completely.

=head2 EXISTS

Not all tied hashes implement EXISTS; in particular, ODBM_File, NDBM_File, and
some old versions of GDBM_File don't, and therefore AnyDBM_File doesn't
either.  Calling exists on a shadow hash that includes one of those tied
hashes as a data source may therefore result in an exception.  Tie::ShadowHash
doesn't use exists except to implement the EXISTS method because of this.

Because it can't use EXISTS due to the above problem, Tie::ShadowHash cannot
correctly distinguish between a non-existent key and an existing key
associated with an undefined value.  This isn't a large problem, since many
tied hashes can't store undefined values anyway, but it means that if one of
your data sources contains a given key associated with an undefined value and
one of your later data sources contains the same key but with a defined value,
when the shadow hash is accessed using that key, it will return the first
defined value it finds.  This is an exception to the normal rule that all data
sources are searched in order and the value returned by an access is the first
value found.  (Tie::ShadowHash does correctly handle undefined values stored
directly in the shadow hash.)

=head2 SCALAR

Tie::ShadowHash does not implement SCALAR and therefore relies on the default
Perl behavior, which is somewhat complex.  See L<perltie/SCALAR this> for a
partial description of this logic, which includes the note that Perl may
incorrectly return true in a scalar context if the hash is cleared by
repeatedly calling DELETE until it is empty.

SCALAR on a shadow hash does not return a count of keys the way that it does
for an untied hash.  The value returned is either true or false and carries no
other meaning.

=head1 AUTHOR

Russ Allbery <rra@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 1999, 2002, 2010, 2022 Russ Allbery <rra@cpan.org>

This program is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<perltie>

The current version of this module is always available from its web site
at L<https://www.eyrie.org/~eagle/software/shadowhash/>.

=cut

# Local Variables:
# copyright-at-end-flag: t
# End:
