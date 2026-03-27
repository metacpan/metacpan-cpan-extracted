package Tlaloc;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.03';

require XSLoader;
XSLoader::load('Tlaloc', $VERSION);

# import() is implemented in XS - no Exporter needed

1;

__END__

=head1 NAME

Tlaloc - Wetness magic on Perl scalars, blessed by the Aztec rain god

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

    use Tlaloc 'all';

    my $scalar = "hello";

    wet($scalar);                # wetness = 50, evap_rate = 10
    drench($scalar);             # wetness = 100
    print wetness($scalar);      # 90  (each call costs evap_rate)
    print wetness($scalar);      # 80
    print is_wet($scalar);       # 1
    print is_dry($scalar);       # 0

    # Custom evaporation rate
    wet($scalar, 5);             # wetness = 50, evap_rate = 5
    drench($scalar, 20);         # wetness = 100, evap_rate = 20
    evap_rate($scalar, 1);       # change evap_rate to 1
    print evap_rate($scalar);    # 1

    dry($scalar);
    print is_dry($scalar);       # 1
    print $scalar;               # hello  (value always unchanged)

=head1 DESCRIPTION

Tlaloc attaches invisible "wetness" metadata to any Perl scalar using
Perl's internal MAGIC system (C<PERL_MAGIC_ext> with a custom C<MGVTBL>
vtable). The wetness level (0-100) decreases by a configurable evaporation
rate (default 10) on each access -- whether that is an explicit call to
C<wetness()>, C<is_wet()>, or C<is_dry()>, or a Perl-level read of the
variable (string interpolation, numeric conversion, etc.) which fires the
C<mg_get> vtable callback.

When wetness reaches zero, the scalar is dry.

=head1 EXPORTS

Nothing is exported by default. Use C<'all'> to import everything:

    use Tlaloc 'all';

Or import individual functions:

    use Tlaloc qw( wet is_dry );

=head1 FUNCTIONS

=head2 wet($scalar)

=head2 wet($scalar, $evap_rate)

Makes C<$scalar> wet with a wetness of 50. If C<$scalar> is already wet,
tops up by 50, capped at 100. If C<$evap_rate> is provided, sets the
evaporation rate (default 10).

=head2 drench($scalar)

=head2 drench($scalar, $evap_rate)

Drenches C<$scalar>, setting wetness to exactly 100 regardless of its
current level. If C<$evap_rate> is provided, sets the evaporation rate.

=head2 dry($scalar)

Removes all wetness magic from C<$scalar>. After this call C<is_dry>
will return true and C<wetness> will return 0.

=head2 wetness($scalar)

Returns the current wetness level as an integer (0-100). Each call
counts as one access and decrements wetness by the evaporation rate
(default 10).

=head2 is_wet($scalar)

Returns 1 if C<$scalar> currently has wetness greater than 0, 0
otherwise. Counts as one access.

=head2 is_dry($scalar)

Returns 1 if C<$scalar> has wetness equal to 0 or has no wetness magic
attached. Returns 0 otherwise. Counts as one access.

=head2 evap_rate($scalar)

=head2 evap_rate($scalar, $new_rate)

Gets or sets the evaporation rate for C<$scalar>. Without a second argument,
returns the current rate. With a second argument, sets the rate and returns
the new value. Does NOT count as an access (no evaporation occurs).
Returns 0 if the scalar has no wetness magic.

=head1 TIED WRAPPERS

For arrays and hashes, the magic-based wetness only evaporates when you
explicitly call C<wetness()>, C<is_wet()>, or C<is_dry()>. Element access
(C<$arr[0]>, C<$hash{key}>) does NOT trigger evaporation.

To get passive evaporation on element access, use tied wrappers:

    use Tlaloc 'all';
    
    my @arr = (1, 2, 3);
    my $tied = wet_tie(\@arr, 5);    # tie with evap_rate=5
    
    my $x = $arr[0];                  # evaporates!
    my $y = $arr[1];                  # evaporates!
    print $tied->wetness, "\n";       # 85 (100 - 5 - 5 - 5)
    
    untie_wet(\@arr);                 # restore normal array

=head2 wet_tie(\@array)

=head2 wet_tie(\@array, $evap_rate)

=head2 wet_tie(\%hash)

=head2 wet_tie(\%hash, $evap_rate)

Ties the array or hash with wetness tracking. Returns the tied object,
which you can use to call C<wetness()>, C<is_wet()>, C<is_dry()>,
C<evap_rate()>, C<drench()>, C<wet()> methods.

Element access (FETCH), existence checks, iterations, and
removal operations (POP, SHIFT, SPLICE) all trigger evaporation. Stores,
additions (STORE, PUSH, UNSHIFT), and size queries do NOT evaporate.

    my @arr = (1, 2, 3);
    my $tied = wet_tie(\@arr, 10);

    # These evaporate:
    my $x = $arr[0];       # FETCH
    for (@arr) { }         # iteration (FETCH per element)
    exists $arr[0];        # EXISTS
    my $p = pop @arr;      # POP
    my $s = shift @arr;    # SHIFT

    # These do NOT evaporate:
    $arr[0] = 99;          # STORE
    push @arr, 4;          # PUSH
    unshift @arr, 0;       # UNSHIFT
    my $len = scalar @arr; # FETCHSIZE (metadata only)

=head2 untie_wet(\@array)

=head2 untie_wet(\%hash)

Removes the tie and restores the original array/hash data.

=head2 Tied Object Methods

The tied object supports these methods:

    my $tied = wet_tie(\@arr);
    
    $tied->wetness();         # current wetness (evaporates)
    $tied->is_wet();          # true if wetness > 0 (evaporates)
    $tied->is_dry();          # true if wetness == 0 (evaporates)
    $tied->evap_rate();       # get current rate (no evaporation)
    $tied->evap_rate(5);      # set rate to 5
    $tied->drench();          # set wetness to 100
    $tied->drench(20);        # set wetness to 100, evap_rate to 20
    $tied->wet();             # add 50 wetness (capped at 100)
    $tied->wet(3);            # add 50, set evap_rate to 3

=head1 EVAPORATION

Wetness decrements by the evaporation rate (default 10) per access.
An "access" is:

=over 4

=item * Any call to C<wetness()>, C<is_wet()>, or C<is_dry()>

=item * Any Perl-level read of the scalar (string interpolation,
numeric context, assignment to another variable, use in a Perl built-in
such as C<join>, C<sprintf>, C<substr>, C<split>, regex match, etc.)

=back

A drenched scalar (100) with default evap_rate (10) will be dry after 10 accesses.
A wet scalar (50) with default evap_rate (10) will be dry after 5 accesses.
With evap_rate of 1, a drenched scalar takes 100 accesses to dry.

=head1 CAVEATS

=over 4

=item * Passing a literal (C<wet(42)>) attaches magic to a temporary SV
that is immediately freed. Only use variables, not literals.

=item * Magic is per-SV. Assigning C<$y = $x> copies the value but not
the magic. C<$y> will be dry.

=item * Not thread-safe across interpreter threads.

=back

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 BUGS

Please report bugs at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Tlaloc>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
