package WebService::Kizasi::Item;

use strict;
use warnings;
use Carp;
use base qw(Class::Accessor::Fast);

my @Fields = qw(title pubDate link guid description);
__PACKAGE__->mk_accessors(@Fields);
1;

=head1 NAME

WebServie::Kizasi::Item - WebService::Kizasi data class

=head1 ACCSSORS

=head2 title

For c10e_word_* methods, returns the cooccurrence (C10E) word,
for keyword_in_context method, it returns the title of blog, and
for ranking_* methods, it returns topics.

=head2 pubDate

For c10e_word_* methods, returns the time to compute the
C10E words, for keyword_in_context method, it returns the update
time of the blog, and for ranking_* methods, it returns update
time of rankings.

=head2 link

For c10e_word_* methods, returns the search result url by
kizasi.jp, for keyword_in_contxt method, it returns url of the
blog, and for ranking_* methods, it returns the search result
url by kizasi.jp.

=head2 guid

Same as link.

=head2 description

Returns 1 day / 1 week / 1month search result urls by kizasi.jp.

=head1 SEE ALSO
L<WebService::Kizasi>

=head1 AUTHOR

DAIBA, Keiichi  C<< keiichi@tokyo.pm.org >>


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2007, DAIBA, Keiichi C<< keiichi@tokyo.pm.org >>.
All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See C<perldoc perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE ''AS IS'' WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
