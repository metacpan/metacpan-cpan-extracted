package WWW::Link::Merge.pm;
$REVISION=q$Revision: 1.4 $ ; $VERSION = sprintf ( "%d.%02d", $REVISION =~ /(\d+).(\d+)/ );

=head1 NAME

WWW::Link::Merge.pm - merge two links

=head1 SYNOPSIS

B<Not yet implemented>

=head1 DESCRIPTION

This provides a simple function which merges two links (related to the
same URL) together to extract the maximum information from both of
them.  For example, the refresh date could be taken from one whilst
the test information could come from the other.

The interface is a simple function

=cut

use WWW::Link;

merge ($$) {
  my ($first, $second) = @_;

  croak "link urls must be identical for merge" 
    unless $first->{"url"} eq $second->{"url"};

  my $result=new WWW::Link $first->{"url"};

  #refresh time should be the latest of either
  ($first->{"last_refresh"} > $second->{"last_refresh"} 
  && $result->{"last_refresh"} > $first->{"last_refresh"} );

  #test information.. more complex.. take the latest information, but
  #if one is broken, but the other has tested okay recently,
  #compensate apropriately.

  die "not implemented"

  return $result
  
}


