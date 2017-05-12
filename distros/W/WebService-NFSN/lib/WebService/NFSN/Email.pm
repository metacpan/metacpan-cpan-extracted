#---------------------------------------------------------------------
package WebService::NFSN::Email;
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
# ABSTRACT: Access NFSN email forwarding
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
    type => 'email',
    methods => {
      'listForwards:JSON' => [],
      removeForward => [qw(forward)],
      setForward    => [qw(forward dest_email)],
    }
  );
} # end BEGIN

#=====================================================================
# Package Return Value:

1;

__END__

=head1 NAME

WebService::NFSN::Email - Access NFSN email forwarding

=head1 VERSION

This document describes version 1.03 of
WebService::NFSN::Email, released April 30, 2014
as part of WebService-NFSN version 1.03.

=head1 SYNOPSIS

    use WebService::NFSN;

    my $nfsn = WebService::NFSN->new($USER, $API_KEY);
    my $email = $nfsn->email($DOMAIN);
    $email->setForward(forward => 'name',
                       dest_email => 'to@example.com');

=head1 DESCRIPTION

WebService::NFSN::Email provides access to NearlyFreeSpeech.NET's
email forwarding API.  It is only useful to people who have
NearlyFreeSpeech.NET's email forwarding service.

=head1 INTERFACE

=over

=item C<< $email = $nfsn->email($DOMAIN) >>

This constructs a new Email object for the specified
C<$DOMAIN> (like C<'example.com'>).  Equivalent to
S<< C<< $email = WebService::NFSN::Email->new($nfsn, $DOMAIN) >> >>.

=back

=head2 Properties

None.

=head2 Methods

=over

=item C<< $email->listForwards() >>

Returns a hash reference listing all forwarding instructions for this
domain.  For each entry, the key is the username and the value is the
forwarding address for that name.  The special username C<*>
represents the "Everything Else" entry.

=item C<< $email->removeForward(forward => $NAME) >>

Removes forwarding instructions from C<"$NAME\@$DOMAIN">.

=item C<< $email->setForward(forward => $NAME, dest_email => $TO) >>

This method is used to create a new email forward or update an
existing one. C<$NAME> is only the username component, so if you have
C<example.com> and you want to set up an email forward for forwarding
C<testuser@example.com> to C<realuser@example.net> then you would pass
C<testuser> as C<$NAME> and C<realuser@example.net> as C<$TO>.

If C<$NAME> already had a forwarding address, it will be overwritten
with the new C<$TO>.

To cause an email address to bounce, forward it to
C<bounce@nearlyfreespeech.net>. To cause it to be silently discarded,
forward it to C<discard@nearlyfreespeech.net>.

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
