#
# InsertOrderHash.pm - insert-order-preserving tied hash
#
# $Id$
#

package Tie::InsertOrderHash;

use v5.6.1;
use strict;
use warnings;

our $VERSION = '0.01';

use base qw(Tie::Hash);

sub TIEHASH  { my $c = shift;
	       bless [[@_[grep { $_ % 2 == 0 } (0..$#_)]], {@_}, 0], $c }

sub STORE    { @{$_[0]->[0]} = grep { $_ ne $_[1] } @{$_[0]->[0]};
	       push @{$_[0]->[0]}, $_[1];
	       $_[0]->[2] = -1;
	       $_[0]->[1]->{$_[1]} = $_[2] }

sub FETCH    { $_[0]->[1]->{$_[1]} }

sub FIRSTKEY { return wantarray ? () : undef
		 unless exists $_[0]->[0]->[$_[0]->[2] = 0];
	       my $key = $_[0]->[0]->[0];
	       return wantarray ? ($key, $_[0]->[1]->{$key}) : $key }

# Guard against deletion (see perldoc -f each)
sub NEXTKEY  { my $i = $_[0]->[2];
	       return wantarray ? () : undef unless exists $_[0]->[0]->[$i];
	       if ($_[0]->[0]->[$i] eq $_[1]) {
		 $i = ++$_[0]->[2] ;
		 return wantarray ? () : undef
		   unless exists $_[0]->[0]->[$i];
	       }
	       my $key = ${$_[0]->[0]}[$i];
	       return wantarray ? ($key, $_[0]->[1]->{$key}) : $key }

sub EXISTS   { exists $_[0]->[1]->{$_[1]} }

sub DELETE   { @{$_[0]->[0]} = grep { $_ ne $_[1] } @{$_[0]->[0]};
	       delete $_[0]->[1]->{$_[1]} }

sub CLEAR    { @{$_[0]->[0]} = ();
	       %{$_[0]->[1]} = () }

1;

__END__

=head1 NAME

Tie::InsertOrderHash - insert-order-preserving tied hash

=head1 SYNOPSIS

  tie my %hash => 'Tie::InsertOrderHash',
    one_two => 'buckle my shoe',
    3_4 => 'shut the door',
    V_VI => 'pick up sticks';
  %hash{7_of_9} => 'not bad';

  print "@{[keys %hash]}\n"; # prints keys in order inserted

=head1 DESCRIPTION

B<Tie::InsertOrderHash> is a tied hash which preserves the order of
inserted keys.  Regular perl hashes regurgitate keys in an unspecified
order, but at times one wishes to have the properties of both a hash
and an array.

As an extention, one may list I<key>/I<value> pairs as additional
arguments to C<tie>, as in the example above.

=head2 EXPORT

None.

=head1 AUTHOR

B. K. Oxley (binkley) E<lt>binkley@bigfoot.comE<gt>

=head1 SEE ALSO

=over 4

=item L<Tie::Hash>

B<Tie::Hash> provides a skeletal implementation for a tied hash.

=item L<perldata>

B<perldata> explains more about hashes and arrays.

=item L<perltie>

B<perltie> explains more about tying hashes, and describes the
internal C<sub>s used to implement them.

=item L<perlfunc/tie>

C<tie> explains more about how user code tie hashes and the implicit
C<use> of this module.

=back

=head1 COPYRIGHT

The DBI module is Copyright (c) 2002 B. K. Oxley (binkley).  All
rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=cut
