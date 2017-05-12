package WWW::Blog::Metadata::Yadis;

use strict;
use vars qw($VERSION);
$VERSION = '0.03';

use WWW::Blog::Metadata;

WWW::Blog::Metadata->mk_accessors(qw( xrds_location ));

sub on_got_tag {
    my $class = shift;
    my($meta, $tag, $attr, $base_uri) = @_;
    if ($tag eq 'meta' && $attr->{'http-equiv'}) {
        my %head = map { $_ => 1 } split /\s+/, lc $attr->{'http-equiv'};
        for my $srv (qw( yadis xrds )) {
            if ($head{"x-${srv}-location"}) {
                $meta->xrds_location($attr->{content}) unless ($meta->xrds_location);
            }
        }
    }
}

sub on_got_tag_order { 99 }

1;
__END__

=head1 NAME

WWW::Blog::Metadata::Yadis - Extract Yadis Resourse Descriptor URL from HTML header

=head1 SYNOPSIS

  use WWW::Blog::Metadata;
  my $meta = WWW::Blog::Metadata->extract_from_uri($uri)
      or die WWW::Blog::Metadata->errstr;
  print $meta->xrds_location;

=head1 DESCRIPTION

WWW::Blog::Metadata::Yadis is a WWW::Blog::Metadata plugin to extract
Yadis Resourse Descriptor URL from HTML header.

=head1 NOTICE

Yadis specification allows to describe Yadis Resourse Descriptor URL 
both on HTTP header and on HTML header's meta tag, but this module
parses only HTML header.

=head1 AUTHOR

OHTSUKA Ko-hei E<lt>nene@kokogiko.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<WWW::Blog::Metadata> L<Net::Yadis::Discovery> http://www.yadis.org/

=cut
