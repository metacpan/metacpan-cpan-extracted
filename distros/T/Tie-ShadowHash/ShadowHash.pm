# Tie::ShadowHash -- Merge multiple data sources into a hash.
#
# Copyright 1999, 2002, 2010 by Russ Allbery <rra@stanford.edu>
#
# This program is free software; you may redistribute it and/or modify it
# under the same terms as Perl itself.
#
# This module combines multiple sources of data into a single tied hash, so
# that they can all be queried simultaneously, the source of any given
# key-value pair irrelevant to the client script.  Data sources are searched
# in the order that they're added to the shadow hash.  Changes to the hashed
# data aren't propagated back to the actual data files; instead, they're saved
# within the tied hash and override any data obtained from the data sources.

##############################################################################
# Modules and declarations
##############################################################################

package Tie::ShadowHash;
require 5.006;

use strict;
use vars qw($VERSION);

$VERSION = '1.00';

##############################################################################
# Regular methods
##############################################################################

# This should pretty much never be called; tie calls TIEHASH.
sub new {
    my $class = shift;
    return $class->TIEHASH (@_);
}

# Given a file name and optionally a split regex, builds a hash out of the
# contents of the file.  If the split sub exists, use it to split each line
# into an array; if the array has two elements, those are taken as the key and
# value.  If there are more, the value is an anonymous array containing
# everything but the first.  If there's no split sub, take the entire line
# modulo the line terminator as the key and the value the number of times it
# occurs in the file.
sub text_source {
    my ($self, $file, $split) = @_;
    unless (open (HASH, '<', $file)) {
        require Carp;
        Carp::croak ("Can't open file $file: $!");
    }
    local $_;
    my ($key, @rest, %hash);
    while (<HASH>) {
        chomp;
        if (defined $split) {
            ($key, @rest) = &$split ($_);
            $hash{$key} = (@rest == 1) ? $rest[0] : [ @rest ];
        } else {
            $hash{$_}++;
        }
    }
    close HASH;
    return \%hash;
}

# Add data sources to the shadow hash.  This takes a list of either anonymous
# arrays (in which case the first element is the type of source and the rest
# are arguments), filenames (in which case it's taken to be a text file with
# each line being a key), or hash references (possibly to tied hashes).
sub add {
    my ($self, @sources) = @_;
    for my $source (@sources) {
        if (ref $source eq 'ARRAY') {
            my ($type, @args) = @$source;
            if ($type eq 'text') {
                $source = $self->text_source (@args);
            } else {
                require Carp;
                Carp::croak ("Invalid source type $type");
            }
        } elsif (!ref $source) {
            $source = $self->text_source ($source);
        }
        push (@{ $$self{SOURCES} }, $source);
    }
    return 1;
}

##############################################################################
# Tie methods
##############################################################################

# DELETED is a hash holding all keys that have been deleted; it's checked
# first on any access.  EACH is a pointer to the current structure being
# traversed on an "each" of the shadow hash, so that they can all be traversed
# in order.  OVERRIDE is a hash containing values set directly by the user,
# which override anything in the shadow hash's underlying data structures.
# And finally, SOURCES is an array of the data structures (all Perl hashes,
# possibly tied).
sub TIEHASH {
    my $class = shift;
    $class = ref $class || $class;
    my $self = {
        DELETED  => {},
        EACH     => -1,
        OVERRIDE => {},
        SOURCES  => []
    };
    bless ($self, $class);
    $self->add (@_) if @_;
    return $self;
}

# Note that this doesn't work quite right in the case of keys with undefined
# values, but we can't make it work right since that would require using
# exists and a lot of common data sources (such as NDBM_File tied hashes)
# don't implement exists.
sub FETCH {
    my ($self, $key) = @_;
    return if $self->{DELETED}{$key};
    return $self->{OVERRIDE}{$key} if exists $self->{OVERRIDE}{$key};
    for my $source (@{ $self->{SOURCES} }) {
        return $source->{$key} if defined $source->{$key};
    }
    return;
}

sub STORE {
    my ($self, $key, $value) = @_;
    delete $self->{DELETED}{$key};
    $self->{OVERRIDE}{$key} = $value;
}

sub DELETE {
    my ($self, $key) = @_;
    delete $self->{OVERRIDE}{$key};
    $self->{DELETED}{$key} = 1;
}

sub CLEAR {
    my ($self) = @_;
    $self->{DELETED} = {};
    $self->{OVERRIDE} = {};
    $self->{SOURCES} = [];
    $self->{EACH} = -1;
}

# This could throw an exception if any underlying source doesn't support
# exists (like NDBM_File).
sub EXISTS {
    my ($self, $key) = @_;
    return if exists $self->{DELETED}{$key};
    for my $source ($self->{OVERRIDE}, @{ $self->{SOURCES} }) {
        return 1 if exists $source->{$key};
    }
    return;
}

# We have to reset the each counter on all hashes.  For tied hashes, we call
# FIRSTKEY directly because it's potentially more efficient than calling keys
# on the hash.
sub FIRSTKEY {
    my ($self) = @_;
    keys %{ $self->{OVERRIDE} };
    for my $source (@{ $self->{SOURCES} }) {
        my $tie = tied $source;
        if ($tie) {
            $tie->FIRSTKEY;
        } else {
            keys %$source;
        }
    }
    $self->{EACH} = -1;
    return $self->NEXTKEY;
}

# Walk the sources by calling each on each one in turn, skipping deleted
# keys and keys shadowed by earlier hashes and using $self->{EACH} to
# store the number of source we're at.
sub NEXTKEY {
    my ($self) = @_;
    my @result = ();
  SOURCE:
    while (!@result && $self->{EACH} < @{ $self->{SOURCES} }) {
        if ($self->{EACH} == -1) {
            @result = each %{ $self->{OVERRIDE} };
        } else {
            @result = each %{ $self->{SOURCES}[$self->{EACH}] };
        }
        if (@result && $self->{DELETED}{$result[0]}) {
            undef @result;
            next;
        }
        if (@result && $self->{EACH} > -1) {
            my $key = $result[0];
            if (exists $self->{OVERRIDE}{$key}) {
                undef @result;
                next;
            }
            for (my $index = $self->{EACH} - 1; $index >= 0; $index--) {
                if (defined $self->{SOURCES}[$index]{$key}) {
                    undef @result;
                    next SOURCE;
                }
            }
        }
        return (wantarray ? @result : $result[0]) if @result;
        $self->{EACH}++;
    }
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
    use DB_File;
    tie (%db, 'DB_File', 'file.db');
    $obj = tie (%hash, 'Tie::ShadowHash', \%db, "otherdata.txt");

    # Accesses search %db first, then the hashed "otherdata.txt".
    print "$hash{key}\n";

    # Changes override data sources, but don't change them.
    $hash{key} = 'foo';
    delete $hash{bar};

    # Add more data sources on the fly.
    %extra = (fee => 'fi', foe => 'fum');
    $obj->add (\%extra);

    # Add a text file as a data source, taking the first "word" up
    # to whitespace on each line as the key and the rest of the line
    # as the value.
    $split = sub { split (' ', $_[0], 2) };
    $obj->add ([text => "pairs.txt", $split]);

    # Add a text file as a data source, splitting each line on
    # whitespace and taking the first "word" to be the key and an
    # anonymous array consisting of the remaining words to be the
    # data.
    $split = sub { split (' ', $_[0]) };
    $obj->add ([text => "triples.txt", $split]);

=head1 DESCRIPTION

This module merges together multiple sets of data in the form of hashes
into a data structure that looks to Perl like a single simple hash.  When
that hash is accessed, the data structures managed by that shadow hash are
searched in order they were added for that key.  This allows the rest of a
program simple and convenient access to a disparate set of data sources.

Tie::ShadowHash can handle anything that looks like a hash; just give it a
reference as one of the additional arguments to tie().  This includes
other tied hashes, so you can include DB and DBM files as data sources for
a shadow hash.  If given a plain file name instead of a reference, it will
build a hash to use internally, with each chomped line of the file being
the key and the number of times that line is seen in the file being the
value.

Tie::Shadowhash also supports special tagged data sources that can take
options specifying their behavior.  The only tagged data source currently
supported is C<text>, which takes a file name of a text file and a
reference to a sub.  The sub is called for every line of the file, with
that line as an argument, and is expected to return a list.  The first
element of the list will be the key, and the second and subsequent
elements will be the value or values.  If there is more than one value,
the value stored in the hash and associated with that key is an anonymous
array containing all of them.

Tagged data sources are distinguished from normal data sources by passing
them to tie() (or to add() -- see below) as an anonymous array.  The first
element is the data source tag and the remaining elements are arguments
for that data source.  For a text data source, see the usage summary above
for examples.

The shadow hash can be modified, and the modifications override the data
sources, but modifications aren't propagated back to the data sources.  In
other words, the shadow hash treats all data sources as read-only and
saves your modifications only in internal memory.  This lets you make
changes to the shadow hash for the rest of your program without affecting
the underlying data in any way (and this behavior is the main reason why
this is called a shadow hash).

If the shadow hash is cleared, by assigning the empty list to it, by
explicitly calling CLEAR(), or by some other method, all data sources are
dropped from the shadow hash.  There is no other way of removing a data
source from a shadow hash after it's been added (you can, of course,
always untie the shadow hash and dispose of the underlying object if you
saved it to destroy the shadow hash completely).

=head1 INSTANCE METHODS

=over 4

=item add(SOURCE [, SOURCE ...])

Adds the given sources to an existing shadow hash.  This method can be
called on the object returned by the initial tie() call.  It takes the
same arguments as the initial tie() and interprets them the same way.

=back

=head1 DIAGNOSTICS

=over 4

=item Can't open file %s: %s

Tie::ShadowHash was given a file name to use as a source, but when it
tried to open that file, the open failed with that system error message.

=item Invalid source type %s

Tie::Shadowhash was given a tagged data source of an unknown type.  The
only currently supported tagged data source is C<text>.

=back

=head1 CAVEATS

It's worth paying very careful attention to L<perltie/"The untie Gotcha">
when using this module.  It's also important to be careful about what you
do with tied hashes that are included in a shadow hash.  Tie::ShadowHash
stores a reference to such arrays; if you untie them out from under a
shadow hash, you may not get the results you expect.  Remember that if you
put something in a shadow hash, you'll need to clean out the shadow hash
as well as everything else that references a variable if you want to free
it completely.

Not all tied hashes implement EXISTS; in particular, ODBM_File, NDBM_File,
and some old versions of GDBM_File don't, and therefore AnyDBM_File
doesn't either.  Calling exists on a shadow hash that includes one of
those tied hashes as a data source may therefore result in an exception.
Tie::ShadowHash doesn't use exists except to implement the EXISTS method
because of this.

Because it can't use EXISTS due to the above problem, Tie::ShadowHash
cannot correctly distinguish between a non-existent key and an existing
key associated with an undefined value.  This isn't a large problem, since
many tied hashes can't store undefined values anyway, but it means that if
one of your data sources contains a given key associated with an undefined
value and one of your later data sources contains the same key but with a
defined value, when the shadow hash is accessed using that key, it will
return the first defined value it finds.  This is an exception to the
normal rule that all data sources are searched in order and the value
returned by an access is the first value found.  (Tie::ShadowHash does
correctly handle undefined values stored directly in the shadow hash.)

=head1 AUTHOR

Russ Allbery <rra@stanford.edu>

=head1 COPYRIGHT AND LICENSE

Copyright 1999, 2002, 2010 by Russ Allbery <rra@stanford.edu>

This program is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<perltie>

The current version of this module is always available from its web site
at L<http://www.eyrie.org/~eagle/software/shadowhash/>.

=cut
