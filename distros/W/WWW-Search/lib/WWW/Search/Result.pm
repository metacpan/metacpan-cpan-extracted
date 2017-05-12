
# $Id: Result.pm,v 1.5 2007-11-12 01:13:49 Daddy Exp $

=head1 NAME

WWW::Search::Result - class for results returned from WWW::Search

=head1 DESCRIPTION

This module is just a synonym for L<WWW::SearchResult>

=head1 AUTHOR

Martin Thurn

=cut

package WWW::Search::Result;

use strict;
use warnings;

use base 'WWW::SearchResult';

our
$VERSION = do { my @r = (q$Revision: 1.5 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };

1;

__END__

