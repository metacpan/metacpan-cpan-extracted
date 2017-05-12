package WWW::Blog::Metadata::OpenSearch;

use strict;
our $VERSION = '0.01';

use WWW::Blog::Metadata;
use URI;

WWW::Blog::Metadata->mk_accessors(qw( _osd ));

sub on_got_tag {
    my $class = shift;
    my($meta, $tag, $attr, $base_uri) = @_;
    if ($tag eq 'link' && $attr->{rel} && lc($attr->{rel}) eq 'search'
        && $attr->{type} eq 'application/opensearchdescription+xml') {
        $meta->_osd([]) unless $meta->_osd;
        push @{$meta->_osd}, (URI->new_abs($attr->{href}, $base_uri)->as_string);
    }
}

sub WWW::Blog::Metadata::opensearch_description {
    my $self = shift;
    wantarray ? @{$self->_osd || []} : $self->_osd->[0];
}

sub on_got_tag_order { 99 }

1;
__END__

=head1 NAME

WWW::Blog::Metadata::OpenSearch - OpenSearch Description Auto-Discovery

=head1 SYNOPSIS

  use WWW::Blog::Metadata;
  use WWW::OpenSearch;

  my $meta = WWW::Blog::Metadata->extract_from_uri($uri)
      or die WWW::Blog::Metadata->errstr;
  if (my $xml = $meta->opensearch_description) {
      my $opensearch = WWW::OpenSearch->new($xml);
      my $feed = $opensearch->search('blog');
      ...
  }

  # When the site has multiple opensearch feeds:
  my @feeds = $meta->opensearch_description;

=head1 DESCRIPTION

WWW::Blog::Metadata::OpenSearch is a WWW::Blog::Metadata plugin to
find A9 OpenSearech Description Document 1.1 from XHTML links.

See L<http://opensearch.a9.com/spec/1.1/description/#autodiscovery>
for the Auto-Discovery spec of OpenSearch 1.1.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<WWW::Blog::Metadata>, L<WWW::OpenSearch>, L<http://opensearch.a9.com/spec/1.1/description/#autodiscovery>

=cut
