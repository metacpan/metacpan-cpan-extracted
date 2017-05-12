#---------------------------------------------------------------------
package WebService::NFSN::Member;
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
# ABSTRACT: Access NFSN member API
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
    type => 'member',
    ro => [qw(accounts:JSON sites:JSON)],
  );
} # end BEGIN

#=====================================================================
# Package Return Value:

1;

__END__

=head1 NAME

WebService::NFSN::Member - Access NFSN member API

=head1 VERSION

This document describes version 1.03 of
WebService::NFSN::Member, released April 30, 2014
as part of WebService-NFSN version 1.03.

=head1 SYNOPSIS

    use WebService::NFSN;

    my $nfsn = WebService::NFSN->new($USER, $API_KEY);
    my $accounts = $nfsn->member->accounts;

=head1 DESCRIPTION

WebService::NFSN::Member provides access to NearlyFreeSpeech.NET's
member API.  It is only useful to people who have websites hosted at
NearlyFreeSpeech.NET.

=head1 INTERFACE

=over

=item C<< $member = $nfsn->member( [$USER] ) >>

This constructs a new Member object for the specified
C<$USER>.  If C<$USER> is omitted, it defaults to the member login that
was passed to C<< WebService::NFSN->new >>.  Equivalent to
S<< C<< $member = WebService::NFSN::Member->new($nfsn, $USER) >> >>.

=back

=head2 Properties

=over

=item C<< $member->accounts() >>

Returns a list of all accounts owned by this member (as an array
reference of account IDs).

=item C<< $member->sites() >>

Returns a list of all sites owned by this member (as an array
reference of short names).

=back

=head2 Methods

None.


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
