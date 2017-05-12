# $Id: Korea.pm,v 2.35 2009/05/02 13:28:41 Martin Exp $

=head1 NAME

WWW::Search::Yahoo::Korea - class for searching Yahoo! Korea

=head1 SYNOPSIS

  use WWW::Search;
  my $oSearch = new WWW::Search('Yahoo::Korea');
  my $sQuery = WWW::Search::escape_query("Tokyo");
  $oSearch->native_query($sQuery);
  while (my $oResult = $oSearch->next_result())
    print $oResult->url, "\n";

=head1 DESCRIPTION

This class is a Yahoo! Korea specialization of L<WWW::Search>.  It
handles making and interpreting searches on Yahoo! Korea
F<http://kr.yahoo.com>.

This class exports no public interface; all interaction should
be done through L<WWW::Search> objects.

=head1 NOTES

=head1 SEE ALSO

To make new back-ends, see L<WWW::Search>.

=head1 BUGS

Please tell the maintainer if you find any!

=head1 TESTING

There are no tests defined for this module.

=head1 AUTHOR

C<WWW::Search::Yahoo> is maintained by Martin Thurn
(mthurn@cpan.org).

=head1 LEGALESE

Copyright (C) 1998-2009 Martin 'Kingpin' Thurn

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut

#####################################################################

package WWW::Search::Yahoo::Korea;

use strict;
use warnings;

use WWW::Search::Yahoo;

use base 'WWW::Search::Yahoo';
our
$VERSION = do { my @r = (q$Revision: 2.35 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };
our $MAINTAINER = 'Martin Thurn <mthurn@cpan.org>';

sub _native_setup_search
  {
  my ($self, $sQuery, $rh) = @_;
  $self->{'_options'} = {
                         'p' => $sQuery,
                        };
  $rh->{'search_base_url'} = 'http://kr.search.yahoo.com';
  $rh->{'search_base_path'} = '/bin/search';
  return $self->SUPER::_native_setup_search($sQuery, $rh);
  } # _native_setup_search

1;

__END__

