
# $Id: Error.pm,v 1.12 2010-12-02 23:45:57 Martin Exp $

=head1 NAME

WWW::Search::Null::Error - class for testing WWW::Search clients

=head1 SYNOPSIS

  require WWW::Search;
  my $oSearch = new WWW::Search('Null::Error');
  $oSearch->native_query('Makes no difference what you search for...');
  $oSearch->retrieve_some();
  my $oResponse = $oSearch->response;
  # You get an HTTP::Response object with a code of 500

=head1 DESCRIPTION

This class is a specialization of WWW::Search that only returns an
error message.

This module might be useful for testing a client program without
actually being connected to any particular search engine.

=head1 AUTHOR

Martin 'Kingpin' Thurn, C<mthurn at cpan.org>, L<http://tinyurl.com/nn67z>.

=cut

package WWW::Search::Null::Error;

use strict;
use warnings;

use base 'WWW::Search';
our
$VERSION = do { my @r = (q$Revision: 1.12 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };
our $MAINTAINER = q{Martin Thurn <mthurn@cpan.org>};

sub _native_setup_search
  {
  my($self, $native_query, $native_opt) = @_;
  } # native_setup_search


sub _native_retrieve_some
  {
  my $self = shift;
  my $response = new HTTP::Response(500,
                                    "This is a test of WWW::Search");
  $self->{response} = $response;
  return undef;
  } # native_retrieve_some


1;

__END__

