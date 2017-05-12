package Thread::Tie::Hash;

# Make sure we have version info for this module
# Make sure we do everything by the book from now on

$VERSION = '0.13';
use strict;

# Load only the stuff that we really need

use load;

# Satisfy -require-

1;

#---------------------------------------------------------------------------

# Following subroutines are loaded on demand only

__END__

#---------------------------------------------------------------------------

# standard Perl features

#---------------------------------------------------------------------------
#  IN: 1 class for which to bless
#      2..N key-value pairs to initialize with
# OUT: 1 instantiated object

sub TIEHASH { my $class = shift; bless {@_},$class } #TIEHASH

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2 key of element to fetch
# OUT: 1 value of element

sub FETCH { $_[0]->{$_[1]} } #FETCH

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2 key for which to store
#      3 new value

sub STORE { $_[0]->{$_[1]} = $_[2] } #STORE

#---------------------------------------------------------------------------
#  IN: 1 instantiated object

sub CLEAR { %{$_[0]} = () } #CLEAR

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
# OUT: 1 first key of hash
#      2 value associated with first key

sub FIRSTKEY {

# Reset the each() magic
# Return first key/value pair

    scalar( keys %{$_[0]} );
    each %{$_[0]};
} #FIRSTKEY

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
# OUT: 1 next key of hash
#      2 value associated with next key

sub NEXTKEY { each %{$_[0]} } #NEXTKEY

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2 key of element to check
# OUT: 1 flag: whether element exists

sub EXISTS { exists $_[0]->{$_[1]} } #EXISTS

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2 key of element to delete

sub DELETE { delete $_[0]->{$_[1]} } #DELETE

#---------------------------------------------------------------------------

__END__

=head1 NAME

Thread::Tie::Hash - default class for tie-ing hashes to threads

=head1 DESCRIPTION

Helper class for L<Thread::Tie>.  See documentation there.

=head1 CREDITS

Implementation inspired by L<Tie::StdHash>.

=head1 AUTHOR

Elizabeth Mattijsen, <liz@dijkmat.nl>.

Please report bugs to <perlbugs@dijkmat.nl>.

=head1 COPYRIGHT

Copyright (c) 2002-2003 Elizabeth Mattijsen <liz@dijkmat.nl>. All rights
reserved.  This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Thread::Tie>.

=cut
