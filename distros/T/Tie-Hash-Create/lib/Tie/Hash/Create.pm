package slot;

## These constant may be changed  but in accordance with the positions
## of the object created in the constuructors of class Tie::Hash::Create
## defined here and must hold for any class derived from Tie::Hash::Create
## too as e.g. Tie::Hash::KeysMask and Tie::Hash::Modulate.

 sub HREF()     {1}
 # sub STATUS() {2}  # reserved
 # sub DEFAULT(){3}  # -> Modulate  (subclass)
 # sub KM()     {4}  # -> KeysMask

package Tie::Hash::Create;

use 5.008007;
our $VERSION = 0.01;
use strict;
no strict 'subs';
use Carp;

require Tie::Hash;
our @ISA = qw ( Tie::ExtraHash );

sub newHASH
{
    my $class = shift;
    my %Baby = ();
    my $to = tie %Baby,$class,@_;
    $to->[slot::HREF] = \%Baby;
}

sub c {$_[0]->[slot::HREF]} # content

1;
__END__

=head1 NAME

Tie::Hash::Create
 - Extend Tie::ExtraHash, enables the tie-object to reflect the tied array


=head1 SYNOPSIS

    package Tie::Hash::MyClass; ## Choose your name for MyClass !
    use base Tie::Hash::Create;

    sub TIEHASH
    {
        my $class = shift;
        ..........................
        bless [{},undef,,,,],$class;
        # insert your stuff between the braces after "undef,"
    }

    # Optionally redefine other methods of Tie::Hash

S<------------ From within another file  ----------->

    use Tie::Hash::MyClass;

    my $myHash = Tie::Hash::MyClass->newHASH(....);

    # behaves as if

    my $myHash; tie %$myHash,'Tie::Hash::MyClass',...;


=head1 DESCRIPTION

Look at sections L<Inheriting from Tie::ExtraHash> in L<Tie::Hash>.
Consider an object, say C<$tob> returned by tie. It is an array, primitive
hash-operations are carried out on the first field of this array, that is $tob->[0],
a reference to a hash.
Surprisingly this hash reference and the reference to the tied hash variable
are not the same.

The purpose of this class is transmit to any derived class these features:

1. Store the reference to the real tied hash in the object C<$tob>.
2. Define an accessor C<$tob-E<gt>c> to this hash.
3. Provide an operation C<newHASH> which manages a tie but returns a
   reference to the real tied hash. This way the real hash-variable which appear as
   the first argument of C<tie> is omitted. Instead C<newHASH> returns an anonymous
   reference to this hash-object.

On the top of this file the package 'slot' defines a slot-name C<slot::HREF>
which identify an index positions of an object.
A derived class could also define its own slot names.
The choice of the index does not matter, however if two sources of code could
not be reused in one class as each one stores data of different matters
onto the same place, then it is easy to change one name-value assignment in package
'slot'. Of course the structure of an object created
by the constructor must meet such a change, this applies for any derived class too.

=head2 OPERATORS

=over 4

=item

=over 8

=item Constructor

TIEHASH inherited from superclass C<Tie::ExtraHash>. Note that the
object returned by TIEHASH, the same as returned by C<tie> is different
from the reference to the tied hash.

=item newHASH

Calls the constructor TIEHASH, however returns the reference identifying
the tied Hash.

=item c  (content operator)

Assume  C<$tob> is an object of C<Tie::Hash::MyClass> which is a subclass of
C<Tie::Hash::Create> and %H is the tied hash, so that C<$tob = tied %H>.
Then C<$tob-E<gt>c> evaluates to C<\%H>.

=back

=back

=head1 SEE ALSO

A Sample class derived from C<Tie::Hash::Create> is L<Tie::Hash::KeysMask>.

=head1 PREREQUISITES

This module requires these other modules and libraries:
 C<Tie::Hash>,<Tie::ExtraHash>

=head1 AUTHOR

Josef SchE<ouml>nbrunner E<lt>j.schoenbrunner@onemail.atE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2005  by Josef SchE<ouml>nbrunner
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut