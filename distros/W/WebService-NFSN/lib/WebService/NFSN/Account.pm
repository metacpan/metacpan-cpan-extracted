#---------------------------------------------------------------------
package WebService::NFSN::Account;
#
# Copyright 2010 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created:  3 Apr 2007
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# ABSTRACT: Access NFSN account information
#---------------------------------------------------------------------

use 5.006;
use strict;
use warnings;

use parent 'WebService::NFSN::Object';

#=====================================================================
# Package Global Variables:

our $VERSION = '1.03'; # VERSION

#=====================================================================
BEGIN {
  __PACKAGE__->_define(
    type => 'account',
    ro => [qw(balance balanceCash balanceCredit balanceHigh
            status:JSON sites:JSON)],
    rw => [qw(friendlyName)],
    methods => {
      addSite       => [qw(site)],
      addWarning    => [qw(balance)],
      removeWarning => [qw(balance)],
    }
  );
} # end BEGIN

#=====================================================================
# Package Return Value:

1;

__END__

=head1 NAME

WebService::NFSN::Account - Access NFSN account information

=head1 VERSION

This document describes version 1.03 of
WebService::NFSN::Account, released April 30, 2014
as part of WebService-NFSN version 1.03.

=head1 SYNOPSIS

    use WebService::NFSN;

    my $nfsn = WebService::NFSN->new($USER, $API_KEY);
    my $balance = $nfsn->account($ACCOUNT_ID)->balance;

=head1 DESCRIPTION

WebService::NFSN::Account provides access to NearlyFreeSpeech.NET's account
API.  It is only useful to people who have websites hosted at
NearlyFreeSpeech.NET.

=head1 INTERFACE

=over

=item C<< $account = $nfsn->account($ACCOUNT_ID) >>

This constructs a new Account object for the specified
C<$ACCOUNT_ID> (a string like C<'A1B2-C3D4E5F6'>).  Equivalent to
S<< C<< $account = WebService::NFSN::Account->new($nfsn, $ACCOUNT_ID) >> >>.

=back

=head2 Properties

=over

=item C<< $account->balance() >>

Returns the current available account balance, without regard for distinctions
between cash and credit.

=item C<< $account->balanceCash() >>

Returns the current account cash balance.

=item C<< $account->balanceCredit() >>

Returns the current account credit balance. Credit balances represent
nonrefundable funds.

=item C<< $account->balanceHigh() >>

Returns the highest account balance ever recorded for this account. This can
be useful in conjunction with the C<balance> property to determine the
relative health of the account (for example, as a percentage).

=item C<< $account->friendlyName( [$NEW_NAME] ) >>

Gets or sets the account friendly name, an alternative to the 12-digit
account number that is intended to be more friendly to work with. For
example, if you have two accounts, you could name one "Personal" and
the other "Business."

You cannot use the account friendly name in API calls; it is intended
to be read/parsed only by humans.

The friendly name must be between 1 and 64 characters and is a
SimpleText field. It must be unique across all your accounts (but
other members may have accounts with the same friendly name).

=item C<< $account->status() >>

Returns the account status, which provides general information about
the health of the account.

The value returned is a hash reference with the following elements:

=over

=item C<status>

A text string describing the status.

=item C<short>

A 2-4 character uppercase abbreviation of the status.

=item C<color>

The recommended HTML color for displaying the status.

=back

=item C<< $account->sites() >>

Returns a list of sites associated with this account (as an array
reference of short names).

=back

=head2 Methods

=over

=item C<< $account->addSite(site => $SHORT_NAME) >>

This method creates a new site backed by this account. The site's
C<$SHORT_NAME> must not be in use by anyone at NFSN. If the call
succeeds, the site will be created relatively quickly, but please
allow a few minutes for DNS to propagate before attempting to use it.

The return value is not meaningful; the method throws an error if the
site cannot be created.

=item C<< $account->addWarning(balance => $BALANCE) >>

This adds a balance warning to the account, so that an email will be
sent when the balance drops below C<$BALANCE>.

C<$BALANCE> must be a positive dollar value specified to at
most two decimal digits (one cent).

=item C<< $account->removeWarning(balance => $BALANCE) >>

Removes an existing balance warning.

C<$BALANCE> must be the dollar value of an existing
balance warning, specified as a decimal number.

=back


=head1 SEE ALSO

L<WebService::NFSN>

=head1 AUTHOR

Christopher J. Madsen  S<C<< <perl AT cjmweb.net> >>>

Please report any bugs or feature requests
to S<C<< <bug-WebService-NFSN AT rt.cpan.org> >>>
or through the web interface at
L<< http://rt.cpan.org/Public/Bug/Report.html?Queue=WebService-NFSN >>.

You can follow or contribute to WebService-NFSN's development at
L<< https://github.com/madsen/webservice-nfsn >>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Christopher J. Madsen.

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
