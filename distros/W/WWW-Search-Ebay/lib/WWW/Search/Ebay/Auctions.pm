
# $Id: Auctions.pm,v 1.9 2010-04-25 00:03:17 Martin Exp $

=head1 NAME

WWW::Search::Ebay::Auctions - backend for searching auctions at www.ebay.com

=head1 DESCRIPTION

This module is just a synonym of WWW::Search::Ebay.

=head1 AUTHOR

Martin 'Kingpin' Thurn, C<mthurn at cpan.org>, L<http://tinyurl.com/nn67z>.

=head1 LICENSE

Copyright (C) 1998-2009 Martin 'Kingpin' Thurn

=cut

package WWW::Search::Ebay::Auctions;

use strict;
use warnings;

use base 'WWW::Search::Ebay';
our
$VERSION = do { my @r = (q$Revision: 1.9 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };

1;

__END__

