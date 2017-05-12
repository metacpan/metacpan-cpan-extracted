#
# $Id: Catalogs.pm,v 1.8 2004/08/25 21:49:38 brian.kaney Exp $
#
# XML::ASCX12::Catalogs
#
# Copyright (c) Vermonster LLC <http://www.vermonster.com>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# For questions, comments, contributions and/or commercial support
# please contact:
#
#    Vermonster LLC <http://www.vermonster.com>
#    312 Stuart St.  2nd Floor
#    Boston, MA 02116  US
#
# vim: set expandtab tabstop=4 shiftwidth=4
#

=head1 NAME

XML::ASCX12::Catalogs - Catalog Looping Rules for ASCX12 EDI Data

=cut
package XML::ASCX12::Catalogs;

use Carp qw(croak);
use vars qw(@ISA @EXPORT $VERSION $LOOPNEST);

BEGIN
{
    @ISA = ('Exporter');
    @EXPORT = qw($LOOPNEST load_catalog);
    $VERSION = '0.1';
}



=head1 DESCRIPTION

This defines how the loops are constructed per catalog.  By catalog
we mean EDI transaction set.

The C<0> catalog is the general relationship for ASCX12.  It say
that the parent loop C<ISA> can have C<GS> child loops.  Also, C<GS> child
loops can have C<ST> child loops.  This one shouldn't have to change.

To include additional catalogs, use the pattern and enclose in the
conditional structure.


=head1 PUBLIC STATIC VARIABLES

=over 4

=item $LOOPNEST


This is a reference to an array hash.  The array contains the looping
rules on a per-catalog basis.

=back

=cut

our $LOOPNEST;

=head1 PUBLIC STATIC METHODS

=over 4

=item void = load_catalog($catalog_number)


This is a static public method that loads the C<$LOOPNEST> reference with
the appropiate catalog relationship data.  It is called by L<XML-ASCX12|XML::ASCX12>.

To add additional catalogs, follow the same pattern.  If you do add catalogs,
please submit this file and the Segments.pl to the author(s) so we can make
this library grow.

=cut
sub load_catalog($)
{
    if ($_[1] eq '0')
    {
        #
        # CATALOG 0 - Fake catalog used to load up general ASCX12 relationship
        #
        push @{$LOOPNEST->{ISA}}, qw(GS);
        push @{$LOOPNEST->{GS}}, qw(ST);
    }
    elsif ($_[1] eq '110')
    {
        #
        # CATALOG 110 - Airfreight Details & Invoice
        #
        push @{$LOOPNEST->{ST}}, qw(N1 LX SE L3);
        push @{$LOOPNEST->{LX}}, qw(N1 L5);
        push @{$LOOPNEST->{L5}}, qw(L1);
    }
    elsif ($_[1] eq '820')
    {
        #
        # CATALOG 820 - Payment Order / Remittance Advice
        #
        push @{$LOOPNEST->{ST}}, qw(N1 ENT);
        push @{$LOOPNEST->{ENT}}, qw(NM1 RMR);
        push @{$LOOPNEST->{RMR}}, qw(REF ADX);
    }
    elsif ($_[1] eq '997')
    {
        #
        # CATALOG 920 - Functional Acknowledgement
        #
        push @{$LOOPNEST->{ST}}, qw(AK2);
        push @{$LOOPNEST->{AK2}}, qw(AK3);
    }
    #
    # XXX Add your catalogs here following the pattern.
    # XXX Remember to update XML::ASCX12::Segments as well.
    #
    # XXX Please submit additional catalogs to the authors
    # XXX so they can become part of the library for everyone's
    # XXX benefit!
    #
    else
    {
        croak "Catalog \"$_[0]\" has not been defined!";
    }
}

=back

=head1 AUTHORS

Brian Kaney <F<brian@vermonster.com>>, Jay Powers <F<jpowers@cpan.org>>

L<http://www.vermonster.com/>

Copyright (c) 2004 Vermonster LLC.  All rights reserved.

This library is free software. You can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as
published by the Free Software Foundation; either version 2 of the
License, or (at your option) any later version.

Basically you may use this library in commercial or non-commercial applications.
However, If you make any changes directly to any files in this library, you are
obligated to submit your modifications back to the authors and/or copyright holder.
If the modification is suitable, it will be added to the library and released to
the back to public.  This way we can all benefit from each other's hard work!

If you have any questions, comments or suggestions please contact the author.

=head1 SEE ALSO

L<XML::ASCX12> and L<XML::ASCX12::Segments>

=cut
1;
