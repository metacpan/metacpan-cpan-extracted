package WWW::Blog::Metadata::RSD;
use strict;

use WWW::Blog::Metadata;

WWW::Blog::Metadata->mk_accessors(qw( rsd_uri ));

sub on_got_tag {
    my $class = shift;
    my($meta, $tag, $attr) = @_;
    if ($tag eq 'link' && $attr->{rel} =~ /\bedituri\b/i &&
        lc $attr->{type} eq 'application/rsd+xml') {
        $meta->rsd_uri($attr->{href});
    }
}
sub on_got_tag_order { 99 }

1;
