package Tie::OrderedHash;

use 5.010;
use strict;
use warnings;
use Tie::Hash ();

use DynaLoader;
our @ISA = ('Tie::Hash', 'DynaLoader');
our $VERSION = '0.04';
sub dl_load_flags { 0x01 }   # RTLD_GLOBAL

__PACKAGE__->bootstrap($VERSION);

1;

__END__

=head1 NAME

Tie::OrderedHash - Ordered Hashes with a public C ABI

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Tie::OrderedHash;

    tie my %h, 'Tie::OrderedHash';
    $h{z} = 1;
    $h{a} = 2;
    $h{m} = 3;
    print join(",", keys %h), "\n";   # z,a,m  (insertion order)

    # Optional initial list, same as Tie::IxHash:
    tie my %g, 'Tie::OrderedHash', alpha => 1, beta => 2, gamma => 3;

    # OO interface
    my $oh = Tie::OrderedHash->new(first => 1, second => 2);
    $oh->Push(third => 3);
    my @keys = $oh->Keys;             # ('first','second','third')
    my ($k, $v) = $oh->Pop;           # ('third', 3)

=head1 STORAGE

Internally each Tie::OrderedHash impl is a blessed AV of four slots:

  $self->[0]   # HV mapping key string -> insertion index (IV)
  $self->[1]   # AV of keys, in insertion order
  $self->[2]   # AV of values, in insertion order
  $self->[3]   # IV cursor used by FIRSTKEY/NEXTKEY

This shape is deliberately the same as L<Tie::IxHash>'s, so code that
poked at C<< $ixhash->[1] >> for a key list still gets the right
answer when migrated to Tie::OrderedHash. 

=head1 TIED-HASH INTERFACE

The standard L<perltie> hash methods are implemented in XS:

=over 4

=item TIEHASH(class, ?LIST)

C<tie %h, 'Tie::OrderedHash', LIST> seeds the hash with LIST as
key/value pairs in source order, same as Tie::IxHash.

=item FETCH, STORE, EXISTS, DELETE, CLEAR

Standard. STORE on an existing key updates the value but preserves
that key's position - matches Tie::IxHash's invariant. DELETE shifts
all following keys down by one (so iteration order remains contiguous).

=item FIRSTKEY, NEXTKEY

Walk insertion order. The cursor lives on C<< $self->[3] >>; only one
Perl-level iterator is supported per impl object at a time, same as
Tie::IxHash. C-level callers should use the L</Public C ABI> below,
which uses an external cursor and supports concurrent iteration.

=item SCALAR

Returns the count of stored pairs (truthy iff non-empty). C<< scalar %h >>
on a Tie::OrderedHash gives the same answer as C<< scalar keys %h >>.

=back

=head1 OO METHODS

These mirror the most-used parts of Tie::IxHash's OO surface. They
accept the impl object directly:

    my $oh = Tie::OrderedHash->new(...);

or the tied implementation:

    tie my %h, 'Tie::OrderedHash';
    my $oh = tied %h;
    $oh->Push(more => 'data');

=head2 new(LIST)

Construct a fresh impl, optionally seeded with LIST as key/value pairs.
Returns the blessed impl object directly (no tie magic).

=head2 Push(LIST)

Insert each (key, value) pair in LIST, in source order. If a key
already exists its value is updated and its position is preserved.
Returns the post-insert count.

=head2 Pop

Remove the last key/value pair. Returns C<(key, value)>, or the
empty list if the hash is empty.

=head2 Shift

Remove the first key/value pair. Returns C<(key, value)>, or the
empty list if empty.

=head2 Unshift(LIST)

Prepend each (key, value) pair in LIST to the front, in source order.
If a key already exists its value is updated in place (no
re-positioning), matching Tie::IxHash's documented behaviour.
Returns the post-insert count.

=head2 Keys(?INDICES)

With no arguments, returns the full key list in insertion order.
With one or more numeric indices, returns the keys at those positions
(negative indices count from the end).

=head2 Values(?INDICES)

Same, for values.

=head2 Length

Returns the number of stored pairs.

=head2 Clear

Empty the hash.

=head1 PUBLIC C ABI

C<#include "tie_orderedhash.h">. Pull it in via
L<ExtUtils::Depends>:

    my $pkg = ExtUtils::Depends->new('Foo', 'Tie::OrderedHash');

The header declares C<tie_oh_new>, C<tie_oh_store>, C<tie_oh_fetch>,
C<tie_oh_delete>, C<tie_oh_clear>, C<tie_oh_count>, C<tie_oh_iter_init>/
C<tie_oh_iter_next>, and C<tie_oh_is_instance>. See the header
itself for the full prototypes and ownership conventions.

The intended use is "I have a tied HV and want to write to its
underlying Tie::OrderedHash without paying for C<call_method>":

    MAGIC *mg = mg_find((SV *)hv, PERL_MAGIC_tied);
    if (mg && mg->mg_obj && tie_oh_is_instance(mg->mg_obj)) {
        tie_oh_store(aTHX_ mg->mg_obj, key, klen, value);
    } else {
        /* foreign tie class - dispatch via call_method */
    }

The iterator is caller-owned (C<tie_oh_iter_t> on the stack), so
multiple C-level walks can run concurrently - useful for emitting
serialised output while a Perl-level C<each %h> is still running.

=head1 PERFORMANCE

Two distinct paths.  The B<tied-hash interface> still pays Perl's
tie-magic dispatch per operation; the speedup vs Tie::IxHash is
modest (~1.2x) because the dispatch cost dominates the body.  The
B<public C ABI> bypasses the tie-magic dispatch entirely and that's
where the big win lives.

If you only need ordering at the Perl level, the gain over
Tie::IxHash is real but small.  If your callers are a downstream XS
module that wants to manipulate the structure from C, the gain is
the entire point of this dist.

=head1 COMPATIBILITY WITH Tie::IxHash

The standard tied-hash methods plus C<Push>/C<Pop>/C<Shift>/C<Unshift>/
C<Keys>/C<Values>/C<Length>/C<Clear>/C<new> are present. 

=head1 SEE ALSO

L<Tie::IxHash> 

L<Hash::Ordered> 

=head1 AUTHOR

LNATION, C<< <email@lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Tie-OrderedHash>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0 (GPL
Compatible).

=cut
