package Tie::Hash::Abbrev;

=head1 NAME

Tie::Hash::Abbrev - a hash which can be accessed using abbreviated keys

=head1 SYNOPSIS

  use Tie::Hash::Abbrev;

  tie my %hash, 'Tie::Hash::Abbrev';

  %hash = ( sonntag   =>0, montag =>1, dienstag=>2, mittwoch =>3,
            donnerstag=>4, freitag=>5, samstag =>6,
            sunday    =>0, monday =>1, tuesday =>2, wednesday=>3,
            thursday  =>4, friday =>5, saturday=>6 );

  print $hash{do}; # will print "4"
  print $hash{fr}; # undef
  print $hash{t};  # undef

  my @deleted = tied(%hash)->delete_abbrev( qw{do fr t} );
    # will delete element "donnerstag"; @deleted will be (4)

=head1 DESCRIPTION

This module implements a subclass of L<Tie::Hash::Array>.
The contents of hashes tied to this class may be accessed via unambiguously
abbreviated keys.
(Please note, however, that this is not true for
L<deleting|perlfunc/"delete EXPR"> hash elements;
for that, can use L</delete_abbrev()> via the object interface.)

While you could achieve a similar behaviour by using the standard module
L<Text::Abbrev> for mapping abbreviations to the original keys, the (main)
advantage of Tie::Hash::Abbrev is that you do not have to calculate all possible
abbreviations in advance each time a key is altered, and you do not have to
store them in memory.

=cut

use strict;
use vars '$VERSION';
use base 'Tie::Hash::Array';

$VERSION = 0.10;

=head1 ADDITIONAL METHODS

=head2 delete_abbrev

  my @deleted = tied(%hash)->delete_abbrev('foo','bar');

Will delete all elements on the basis of all unambiguous (in the sense of this
module or the subclass used) abbreviations given as arguments and return a
(possibly empty) list of all deleted values.

=cut

sub delete_abbrev {
    my $self = shift;
    my @deleted;
    for (@_) {
        next
          unless
          defined( my $pos1 = $self->valid( $_, my $pos = $self->pos($_) ) );
        my $i = 0;
        push @deleted, grep $i++ & 1, $self->splice( $pos, 2 + $pos1 - $pos );
    }
    @deleted
}

sub equals { '' }

sub valid {
    my ( $self, $key, $pos ) = @_;
    return undef
      unless $pos <= $#$self && $key eq substr $self->[$pos], 0, length $key;
    my $value = $self->[ $pos + 1 ];
    return $value if $self->[$pos] eq $key; # always match if exact key is given
    while ( $pos + 2 <= $#$self && $key eq substr $self->[ $pos + 2 ], 0,
        length $key )
    {
        return undef
          unless $self->equals( $value, $self->[ ( $pos += 2 ) + 1 ] );
    }
    $pos;
}

=head1 SUBCLASSING

Please do not rely on the implementation details of this class for now,
since they may still be subject to change.

If you'd like to subclass this module, please let me know;
perhaps we can agree on some standards then.

=head1 BUGS

None known so far.

=head1 AUTHOR

	Martin H. Sluka
	mailto:perl@sluka.de
	http://martin.sluka.de/

=head1 COPYRIGHT & LICENCE

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

L<Tie::Hash::Array>, L<Tie::Hash::Abbrev::Smart>

=cut

1
