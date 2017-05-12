package threads::shared::scalar;

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
#      2 initial value
# OUT: 1 instantiated object

sub TIESCALAR {

# Obtain the class
# Obtain the initial value
# Return it as a blessed object

    my $class = shift;
    bless \do{ my $o = @_ && Scalar::Util::reftype($_[0]) eq 'SCALAR' ? $_[0] : \(my $s) },$class;
} #TIESCALAR

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
# OUT: 1 value

sub FETCH { ${${$_[0]}} } #FETCH

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2 new value

sub STORE { ${${$_[0]}} = $_[1] } #STORE

#---------------------------------------------------------------------------

__END__

=head1 NAME

threads::shared::scalar - default class for tie-ing scalars to threads with forks

=head1 DESCRIPTION

Helper class for L<forks::shared>.  See documentation there.

=head1 ORIGINAL AUTHOR CREDITS

Implementation inspired by L<Tie::StdScalar>.

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
