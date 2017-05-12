package Thread::Tie::Scalar;

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
#      2 initial value
# OUT: 1 instantiated object

sub TIESCALAR {

# Obtain the class
# Obtain the initial value
# Return it as a blessed object

    my $class = shift;
    my $instance = shift || undef;
    bless \$instance,$class;
} #TIESCALAR

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
# OUT: 1 value

sub FETCH { ${$_[0]} } #FETCH

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2 new value

sub STORE { ${$_[0]} = $_[1] } #STORE

#---------------------------------------------------------------------------

__END__

=head1 NAME

Thread::Tie::Scalar - default class for tie-ing scalars to threads

=head1 DESCRIPTION

Helper class for L<Thread::Tie>.  See documentation there.

=head1 CREDITS

Implementation inspired by L<Tie::StdScalar>.

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
