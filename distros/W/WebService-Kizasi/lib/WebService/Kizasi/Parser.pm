package WebService::Kizasi::Parser;

use strict;
use warnings;
use Carp;

use XML::RSS::LibXML;
use WebService::Kizasi::Item;
use WebService::Kizasi::Items;

sub parse {
    my ( $class, $res ) = @_;
    my ( $rss, $ret, @items );
    $ret = new WebService::Kizasi::Items;
    if ( $res->is_success ) {
        $rss = new XML::RSS::LibXML;
        eval { $rss->parse( $res->content ) };
        if ($@) {
            $ret->status('RSSParseError');
            $ret->status_message($@);
            $ret->items( [] );
        }
        else {
            for my $entry ( @{ $rss->{'items'} } ) {
                my $item = new WebService::Kizasi::Item;
                $item->title( $entry->{'title'} );
                $item->pubDate( $entry->{'pubDate'} );
                $item->link( $entry->{'link'} );
                $item->guid( $entry->{'guid'} );
                $item->description( $entry->{'description'} );
                unshift @items, $item;
            }
            $ret->items( \@items );
        }
    }
    else {
        $ret->status('AgentError');
        $ret->status_message( $res->status_line );
        $ret->items( [] );
    }
    return $ret;
}
1;

=head1 NAME

WebService::Kizasi::Parser - Class methods for parsing Kizasi
web service's response

=head1 INTERFACE

=head2 parse

Parse Response

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
