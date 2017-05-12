#---------------------------------------------------------------------
package Tie::CPHash;
#
# Copyright 1997-2012 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: 08 Nov 1997
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# ABSTRACT: Case preserving but case insensitive hash table
#---------------------------------------------------------------------

use 5.006;
use strict;
use warnings;

#=====================================================================
# Package Global Variables:

our $VERSION = '2.000';
# This file is part of Tie-CPHash 2.000 (January 17, 2015)

#=====================================================================
# Tied Methods:
#---------------------------------------------------------------------
# TIEHASH classname
#      The method invoked by the command `tie %hash, classname'.
#      Associates a new hash instance with the specified class.

sub TIEHASH
{
    my $self = bless {}, shift;

    $self->add(\@_) if @_;

    return $self;
} # end TIEHASH

#---------------------------------------------------------------------
# STORE this, key, value
#      Store datum *value* into *key* for the tied hash *this*.

sub STORE
{
    $_[0]->{lc $_[1]} = [ $_[1], $_[2] ];
} # end STORE

#---------------------------------------------------------------------
# FETCH this, key
#      Retrieve the datum in *key* for the tied hash *this*.

sub FETCH
{
    my $v = $_[0]->{lc $_[1]};
    ($v ? $v->[1] : undef);
} # end FETCH

#---------------------------------------------------------------------
# FIRSTKEY this
#      Return the (key, value) pair for the first key in the hash.

sub FIRSTKEY
{
    my $a = scalar keys %{$_[0]};
    &NEXTKEY;
} # end FIRSTKEY

#---------------------------------------------------------------------
# NEXTKEY this, lastkey
#      Return the next (key, value) pair for the hash.

sub NEXTKEY
{
    my $v = (each %{$_[0]})[1];
    ($v ? $v->[0] : undef );
} # end NEXTKEY

#---------------------------------------------------------------------
# SCALAR this
#     Return bucket usage information for the hash (0 if empty).

sub SCALAR
{
    scalar %{$_[0]};
} # end SCALAR

#---------------------------------------------------------------------
# EXISTS this, key
#     Verify that *key* exists with the tied hash *this*.

sub EXISTS
{
    exists $_[0]->{lc $_[1]};
} # end EXISTS

#---------------------------------------------------------------------
# DELETE this, key
#     Delete the key *key* from the tied hash *this*.
#     Returns the old value, or undef if it didn't exist.

sub DELETE
{
    my $v = delete $_[0]->{lc $_[1]};
    ($v ? $v->[1] : undef);
} # end DELETE

#---------------------------------------------------------------------
# CLEAR this
#     Clear all values from the tied hash *this*.

sub CLEAR
{
    %{$_[0]} = ();
} # end CLEAR

#=====================================================================
# Other Methods:
#---------------------------------------------------------------------


sub add
{
    my $self = shift;
    my $list = (@_ == 1) ? shift : \@_;
    my $limit = $#$list;

    unless ($limit % 2) {
        require Carp;
        Carp::croak("Odd number of elements in CPHash add");
    }

    for (my $i = 0; $i < $limit; $i+=2 ) {
        $self->{lc $list->[$i]} = [ @$list[$i, $i+1] ];
    }

    return $self;
} # end add

# Aliases for Tie::IxHash users:
*Push    = \&add;
*Unshift = \&add;
#---------------------------------------------------------------------


sub key
{
    my $v = $_[0]->{lc $_[1]};
    ($v ? $v->[0] : undef);
}

#=====================================================================
# Package Return Value:

1;

__END__

=head1 NAME

Tie::CPHash - Case preserving but case insensitive hash table

=head1 VERSION

This document describes version 2.000 of
Tie::CPHash, released January 17, 2015.

=head1 SYNOPSIS

    use Tie::CPHash 2; # allows initialization during tie
    tie %cphash, 'Tie::CPHash', key => 'value';

    $cphash{'Hello World'} = 'Hi there!';
    printf("The key `%s' was used to store `%s'.\n",
           tied(%cphash)->key('HELLO WORLD'),
           $cphash{'HELLO world'});

=head1 DESCRIPTION

The Tie::CPHash module provides a hash table that is case
preserving but case insensitive.  This means that

    $cphash{KEY}    $cphash{key}
    $cphash{Key}    $cphash{keY}

all refer to the same entry.  Also, the hash remembers which form of
the key was last used to store the entry.  The C<keys> and C<each>
functions will return the key that was used to set the value.

An example should make this clear:

    tie %h, 'Tie::CPHash', Hello => 'World';
    print $h{HELLO};            # Prints 'World'
    print keys(%h);             # Prints 'Hello'
    $h{HELLO} = 'WORLD';
    print $h{hello};            # Prints 'WORLD'
    print keys(%h);             # Prints 'HELLO'

Tie::CPHash version 2.000 introduced the ability to pass a list of
S<C<< key => value >>> pairs to initialize the hash (along with the
C<add> method that powers it).  The list must include a value for
each key, or the constructor will croak.

The additional C<key> method lets you fetch the case of a specific key:

    # When run after the previous example, this prints 'HELLO':
    print tied(%h)->key('Hello');

(The C<tied> function returns the object that C<%h> is tied to.)

If you need a case insensitive hash, but don't need to preserve case,
just use C<$hash{lc $key}> instead of C<$hash{$key}>.  This has a lot
less overhead than Tie::CPHash.

C<use Tie::CPHash;> does not export anything into your namespace.

=for Pod::Coverage
Push
Unshift

=head1 METHODS

=head2 add

  tied(%h)->add( key => value, ... );
  tied(%h)->add( \@list_of_key_value_pairs );

This method (introduced in version 2.000) adds keys and values to the hash.
It's just like

  %h = @list_of_key_value_pairs;

except that it doesn't clear the hash first.  It accepts either a list
or an arrayref.  It croaks if the list has an odd number of entries.
It returns the tied hash object.

If the list contains duplicate keys, the last S<C<< key => value >>>
pair in the list wins.  (You can't pass a hashref to C<add> because it
would be ambiguous which key would win if two keys differed only in case.)

For people used to L<Tie::IxHash>, C<add> is aliased to both C<Push>
and C<Unshift>.  (Tie::CPHash does not preserve the order of keys.)


=head2 key

  $set_using_key = tied(%h)->key( $key )

This method lets you fetch the case of a specific key.  For example:

  $h{HELLO} = 'World';
  print tied(%h)->key('Hello'); # prints HELLO

If the key does not exist in the hash, it returns C<undef>.

=head1 DIAGNOSTICS

=over

=item Odd number of elements in CPHash add

You passed a list with an odd number of elements to the C<add> method
(or to C<tie>, which uses C<add>).
The list must contain a value for each key.


=back

=head1 CONFIGURATION AND ENVIRONMENT

Tie::CPHash requires no configuration files or environment variables.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

Christopher J. Madsen  S<C<< <perl AT cjmweb.net> >>>

Please report any bugs or feature requests
to S<C<< <bug-Tie-CPHash AT rt.cpan.org> >>>
or through the web interface at
L<< http://rt.cpan.org/Public/Bug/Report.html?Queue=Tie-CPHash >>.

You can follow or contribute to Tie-CPHash's development at
L<< https://github.com/madsen/tie-cphash >>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Christopher J. Madsen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
