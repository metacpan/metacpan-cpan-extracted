package WWW::Blog::Metadata::IsTypePad;
use strict;

use WWW::Blog::Metadata;
WWW::Blog::Metadata->mk_accessors(qw( is_typepad finished ));

sub on_got_html {
    my $class = shift;
    my($meta, $html, $base_uri) = @_;
    $meta->is_typepad($base_uri =~ /\.typepad\.com/ ? 1 : 0);
}
sub on_got_html_order { 99 }

sub on_finished {
    my $class = shift;
    my($meta) = @_;
    $meta->finished(1);
}
sub on_finished_order { 99 }

1;
