package threads::shared::array;

# Make sure we have version info for this module
# Make sure we do everything by the book from now on

$VERSION = '0.36';
use strict;
use Scalar::Util;

# Satisfy -require-

1;

#---------------------------------------------------------------------------

# standard Perl features

#---------------------------------------------------------------------------
#  IN: 1 class for which to bless
#      2..N initial values
# OUT: 1 instantiated object

sub TIEARRAY { my $class = shift; bless \do{ my $o = @_ && Scalar::Util::reftype($_[0]) eq 'ARRAY' ? $_[0] : [] },$class } #TIEARRAY

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2 index of element to fetch
# OUT: 1 value of element

sub FETCH { ${$_[0]}->[$_[1]] } #FETCH

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
# OUT: 1 number of elements

sub FETCHSIZE { scalar @{${$_[0]}} } #FETCHSIZE

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2 index for which to store
#      3 new value

sub STORE { ${$_[0]}->[$_[1]] = $_[2] } #STORE

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2 new number of elements

sub STORESIZE { $#{${$_[0]}} = $_[1]-1 } #STORESIZE

#---------------------------------------------------------------------------
#  IN: 1 instantiated object

sub CLEAR { @{${$_[0]}} = () } #CLEAR

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
# OUT: 1 popped off value

sub POP { pop(@{${$_[0]}}) } #POP

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2..N values to push

sub PUSH { my $self = shift; push( @{${$self}},@_ ) } #PUSH

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
# OUT: 1 shifted off value

sub SHIFT { shift(@{${$_[0]}}) } #SHIFT

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2..N values to unshift

sub UNSHIFT { my $self = shift; unshift( @{${$self}},@_ ) } #UNSHIFT

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2 offset (index) from which to splice (default: 0)
#      3 number of elements to remove (default: rest)
#      4..N values to to put in place
# OUT: 1..N elements that were removed

sub SPLICE {

# Obtain the object
# Obtain the array object
# Obtain the current size of the list
# Obtain the offset to use
# Adapt if it was to be relative from the end
# Obtain the number of element to remove
    
    my $self = shift;
    my $list = ${$self};
    my $size  = $self->FETCHSIZE;
    my $offset = @_ ? shift : 0;
    $offset += $size if $offset < 0;
    my $length = @_ ? shift : $size - $offset;

# Perform the actual action and return its result

    splice( @$list, $offset, $length, @_ );
} #SPLICE

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2 index of element to check
# OUT: 1 flag: whether element exists

sub EXISTS { exists ${$_[0]}->[$_[1]] } #EXISTS

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2 index of element to delete

sub DELETE { delete ${$_[0]}->[$_[1]] } #DELETE

#---------------------------------------------------------------------------

__END__

=head1 NAME

threads::shared::array - default class for tie-ing arrays to threads with forks

=head1 DESCRIPTION

Helper class for L<forks::shared>.  See documentation there.

=head1 ORIGINAL AUTHOR CREDITS

Implementation inspired by L<Tie::StdArray>.

=head1 CURRENT AUTHOR AND MAINTAINER

Eric Rybski <rybskej@yahoo.com>.

=head1 ORIGINAL AUTHOR

Elizabeth Mattijsen, <liz@dijkmat.nl>.

=head1 COPYRIGHT

Copyright (c)
 2005-2014 Eric Rybski <rybskej@yahoo.com>,
 2002-2004 Elizabeth Mattijsen <liz@dijkmat.nl>.
All rights reserved.  This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<forks>, L<forks::shared>.

=cut
