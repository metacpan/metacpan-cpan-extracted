# $Id: Icon.pm 1933 2006-04-22 04:53:48Z btrott $

package WWW::Blog::Metadata::Icon;
use strict;

our $VERSION = '0.02';

use WWW::Blog::Metadata;
use XML::FOAF;
use URI;
use LWP::UserAgent;

WWW::Blog::Metadata->mk_accessors(qw( icon_uri favicon_uri foaf_icon_uri ));

sub on_got_html {
    my $class = shift;
    my($meta, $html, $base_uri) = @_;
    my $ua = LWP::UserAgent->new;
    my $req = HTTP::Request->new(HEAD => $base_uri . 'favicon.ico');
    my $res = $ua->request($req);
    if ($res->is_success) {
        $meta->favicon_uri($base_uri . 'favicon.ico');
    }
    my $foaf_uri = XML::FOAF->find_foaf_in_html($html, $base_uri)
        or return;
    my $foaf = XML::FOAF->new(URI->new($foaf_uri))
        or return;
    $meta->foaf_icon_uri($foaf->person->img || $foaf->person->depiction);
}
sub on_got_html_order { 99 }

sub on_got_tag {
    my $class = shift;
    my($meta, $tag, $attr, $base_uri) = @_;
    if ($tag eq 'link' && $attr->{rel}) {
        my %rel = map { $_ => 1 } split /\s+/, lc $attr->{rel};
        if ($rel{icon}) {
            $meta->favicon_uri(URI->new_abs($attr->{href}, $base_uri))->as_string;
        }
    }
}
sub on_got_tag_order { 99 }

sub on_finished {
    my $class = shift;
    my($meta) = @_;
    $meta->icon_uri($meta->foaf_icon_uri || $meta->favicon_uri);
}
sub on_finished_order { 99 }

1;
__END__

=head1 NAME

WWW::Blog::Metadata::Icon - Extract icon (FOAF photo, favicon) from weblog

=head1 SYNOPSIS

    use WWW::Blog::Metadata;
    my $meta = WWW::Blog::Metadata->extract_from_uri($uri)
        or die WWW::Blog::Metadata->errstr;
    print $meta->icon_uri;

=head1 DESCRIPTION

I<WWW::Blog::Metadata::Icon> is a plugin for I<WWW::Blog::Metadata> that
attempts to extract photos/icons for a weblog author. It looks in three
places:

=over 4

=item 1. a FOAF file, from either an C<img> or C<depiction> element.

=item 2. a I<shortcut icon> in a I<E<lt>link /E<gt>> tag in the document.

=item 3. a HEAD check on I<$uri>/favicon.ico.

=back

=head1 USAGE

I<WWW::Blog::Metadata::Icon> adds 3 methods to the metadata object.

=head2 $meta->favicon_uri

The URI for a shortcut/favicon from either source #2 or #3 above.

=head2 $meta->foaf_icon_uri

The URI for an icon/photo from the FOAF file (#1 above).

=head2 $meta->icon_uri

Equivalent to C<$meta-E<gt>foaf_icon_uri || $meta-E<gt>favicon_uri>.

=head1 LICENSE

I<WWW::Blog::Metadata::Icon> is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR & COPYRIGHT

Except where otherwise noted, I<WWW::Blog::Metadata::Icon> is Copyright 2005
Benjamin Trott, ben+cpan@stupidfool.org. All rights reserved.

=cut
