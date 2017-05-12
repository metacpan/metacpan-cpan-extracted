package WWW::Blog::Metadata::MobileLinkDiscovery;

use strict;
use vars qw($VERSION);
$VERSION = '0.02';

use WWW::Blog::Metadata;
use URI;

WWW::Blog::Metadata->mk_accessors(qw( mobile_link mobile_link_type ));

sub on_got_tag {
    my $class = shift;
    my($meta, $tag, $attr, $base_uri) = @_;
    if ($tag eq 'link' && $attr->{rel} && lc($attr->{rel}) eq 'alternate' && $attr->{media} =~ /handheld/) {
        my %media = map { s/[^a-zA-Z0-9\-].*$//; ($_ => 1) }
            split /,\s*/, $attr->{media};
        if ($media{handheld}) {
            $meta->mobile_link(URI->new_abs($attr->{href}, $base_uri)->as_string);
            $meta->mobile_link_type($attr->{type});
        }
    }
}

sub on_got_tag_order { 99 }

1;
__END__

=head1 NAME

WWW::Blog::Metadata::MobileLinkDiscovery - Mobile Link Discovery plugin for WWW::Blog::Metadata

=head1 SYNOPSIS

  use WWW::Blog::Metadata::MobileLinkDiscovery;
  my $meta = WWW::Blog::Metadata->extract_from_uri($uri)
      or die WWW::Blog::Metadata->errstr;

  my $url  = $meta->mobile_link;
  my $type = $meta->mobile_link_type;

=head1 DESCRIPTION

WWW::Blog::Metadata::MobileLinkDiscovery is a plugin for WWW::Blog::Metadata to find Mobile Link Discovery tag within XHTML head.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<WWW::Blog::Metadata>

=cut
