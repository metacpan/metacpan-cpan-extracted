package Text::Markup::Pod;

use 5.8.1;
use strict;
use warnings;
use Pod::Simple::XHTML 3.15;

# Disable the use of HTML::Entities.
$Pod::Simple::XHTML::HAS_HTML_ENTITIES = 0;

our $VERSION = '0.31';

sub parser {
    my ($file, $encoding, $opts) = @_;
    my $p = Pod::Simple::XHTML->new;
    # Output everything as UTF-8.
    $p->html_header_tags('<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />');
    $p->strip_verbatim_indent(sub { (sort map { /^(\s+)/ } @{$_[0]})[0] });
    $p->output_string(\my $html);
    # Want user supplied options to override even these default behaviors,
    # if necessary
    my $opt = $opts ? { @$opts } : {};
    foreach my $method ( keys %$opt ) {
        my $v = $opt->{$method};
        $p->$method($v);
    }
    $p->parse_file($file);
    return unless $p->content_seen;
    utf8::encode($html);
    return $html;
}

1;
__END__

=head1 Name

Text::Markup::Pod - Pod parser for Text::Markup

=head1 Synopsis

  use Text::Markup;
  my $pod = Text::Markup->new->parse(file => 'README.pod');

=head1 Description

This is the L<Pod|perlpod> parser for L<Text::Markup>. It runs the file
through L<Pod::Simple::XHTML> and returns the result. If the Pod contains any
non-ASCII characters, the encoding must be declared either via a BOM or via
the C<=encoding> tag. Text::Markup::Pod recognizes files with the following
extensions as Pod:

=over

=item F<.pod>

=item F<.pm>

=item F<.pl>

=back

=head1 Options

You may pass an arrayref of settings to this parser which changes the output returned.  For example,
to suppress an HTML header and footer, pass:

  my $pod_fragment = Text::Markup->new->parse(
          file => 'README.pod',
          options => [
              html_header => '',
              html_footer => '',
          ]
  );

This implementation makes method calls to the L<Pod::Simple::XHTML> parser using the key as the method
name and the value as the parameter list to pass.  

See L<Pod::Simple::XHTML> and L<Pod::Simple> for the full list of options and inherited options
which can be manipulated.

=head1 Author

David E. Wheeler <david@justatheory.com>

=head1 Copyright and License

Copyright (c) 2011-2023 David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
