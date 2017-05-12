package WWW::Mechanize::DecodedContent;

use strict;
our $VERSION = '0.02';

use Encode ();
use HTTP::Response::Encoding;

sub WWW::Mechanize::decoded_content {
    my $mech = shift;
    my $content = $mech->content(@_);
    return $content unless $mech->{ct} && $mech->{ct} =~ m!^text/!i;

    ## WWW::Mechanize 1.50 or over calls decoded_content() to get page
    return $content if Encode::is_utf8($content);

    if (my $enc = $mech->res->encoding) {
        return Encode::decode($enc, $content);
    } else {
        return;
    }
}

1;
__END__

=for stopwords HTML HTTP Mech iso-8859-1

=head1 NAME

WWW::Mechanize::DecodedContent - decode Mech content using its HTTP response encoding

=head1 SYNOPSIS

  use WWW::Mechanize;
  use WWW::Mechanize::DecodedContent;

  my $mech = WWW::Mechanize->new;
     $mech->get($url);

  my $content = $mech->decoded_content || $mech->content;

=head1 DESCRIPTION

WWW::Mechanize::DecodedContent is a plugin to add I<decoded_content>
utility method to WWW::Mechanize.

B<NOTE> If you're using WWW::Mechanize 1.50 or later, just use
C<< $mech->content >> and it will return decoded content.

=head1 METHODS

=over 4

=item res->encoding

Because it loads L<HTTP::Response::Encoding> module, it automatically
adds I<encoding> method to HTTP::Response class.

  my $enc = $mech->res->encoding;

Note that I<$enc> might be empty if HTTP response header doesn't
contain valid charset attribute.

=item decoded_content

  my $content = $mech->decoded_content;

returns HTML as decoded using HTTP response encoding. Returns undef if
encoding is not specified. In that case you might need to get the raw
content using C<< $mech->content >>, and decode it using the default
encoding, which is likely to be iso-8859-1.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<HTTP::Response::Encoding>, L<WWW::Mechanize>

=cut
