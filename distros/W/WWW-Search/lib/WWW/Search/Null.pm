
=head1 NAME

WWW::Search::NULL - class for searching any web site

=head1 SYNOPSIS

    require WWW::Search;
    $search = new WWW::Search('Null');

=head1 DESCRIPTION

This class is a specialization of WWW::Search that only returns an
error message.

This class exports no public interface; all interaction should be done
through WWW::Search objects.

This modules is really a hack for systems that want to include
indices that have no corresponding WWW::Search module (like UNIONS)

=head1 AUTHOR

C<WWW::Search::Null> is written by Paul Lindner, <lindner@itu.int>

=head1 COPYRIGHT

Copyright (c) 1998 by the United Nations Administrative Committee 
on Coordination (ACC)

All rights reserved.

=cut

package WWW::Search::Null;

use strict;
use warnings;

use base 'WWW::Search';

use Carp ();
use WWW::SearchResult;

our
$VERSION = do { my @r = (q$Revision: 1.6 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };

sub _native_setup_search
  {
  my $self = shift;
  my ($native_query, $native_opt) = @_;
  my $native_url;
  $self->{_next_to_retrieve} = 0;
  $self->{_base_url} = $self->{_next_url} = $native_url;
  } # _native_setup_search

sub _native_retrieve_some
  {
  my $self = shift;
  # Null search just returns an error..
  return if (!defined($self->{_next_url}));
  my $response = new HTTP::Response(500, "This is a dummy search engine.");
  $self->{response} = $response;
  } # _native_retrieve_some

1;

__END__

