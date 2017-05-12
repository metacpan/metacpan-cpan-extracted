# $Id: NoVersion.pm,v 1.5 2010-12-02 23:45:57 Martin Exp $

=head1 NAME

WWW::Search::Null::NoVersion - class for testing WWW::Search

=head1 SYNOPSIS

  use WWW::Search;
  my $oSearch = new WWW::Search('Null::NoVersion');

=head1 DESCRIPTION

This class is a specialization of WWW::Search that has no $VERSION.

This module is for testing the WWW::Search module.

=head1 AUTHOR

Martin 'Kingpin' Thurn, C<mthurn at cpan.org>, L<http://tinyurl.com/nn67z>.

=cut

package WWW::Search::Null::NoVersion;

use strict;
use warnings;

use base 'WWW::Search';
our $MAINTAINER = q{Martin Thurn <mthurn@cpan.org>};

1;

__END__

