package Tie::Hash::Abbrev::Smart;

=head1 NAME

Tie::Hash::Abbrev::Smart - a hash which can be accessed using abbreviated keys

=head1 SYNOPSIS

  use Tie::Hash::Abbrev::Smart;

  tie my %hash, 'Tie::Hash::Abbrev::Smart';

  %hash = ( sonntag   =>0, montag =>1, dienstag=>2, mittwoch =>3,
            donnerstag=>4, freitag=>5, samstag =>6,
            sunday    =>0, monday =>1, tuesday =>2, wednesday=>3,
            thursday  =>4, friday =>5, saturday=>6 );

  print $hash{do}; # will print "4"
  print $hash{fr}; # will print "5"
  print $hash{t};  # undef

  my @deleted = tied(%hash)->delete_abbrev(qw(do fr t));
    # will delete elements "donnerstag", "freitag" and "friday";
      @deleted will be (4,5,5)

=head1 DESCRIPTION

This module implements a subclass of L<Tie::Hash::Abbrev>.
The contents of hashes tied to this class may be accessed via unambiguously
abbreviated keys.
(Please note, however, that this is not true for
L<deleting|perlfunc/"delete EXPR"> hash elements;
for that you can use L<Tie::Hash::Abbrev/delete_abbrev()> via the object
interface.)

In contrast to L<Tie::Hash::Abbrev>, an abbreviation is still considered to be
unambiguous even if more than one key starting with the respective string
exists, as long as all of the corresponding elements have identical (string)
values.

=head1 BUGS

None known so far.

=head1 AUTHOR

	Martin H. Sluka
	mailto:perl@sluka.de
	http://martin.sluka.de/

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

L<Tie::Hash::Abbrev>

=cut

use strict;
use vars '$VERSION';
use Tie::Hash::Abbrev; # for buggy base.pm in Perl 5.005_03
use base 'Tie::Hash::Abbrev';

$VERSION = 0.01;

sub equals {
    my ( $self, $value0, $value1 ) = @_;
    defined $value0 ? defined $value1 && $value0 eq $value1 : !defined $value1;
}

1
