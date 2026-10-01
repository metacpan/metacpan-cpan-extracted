package Text::Markdown::Discount;

use 5.008001;
use strict;
use warnings;

use Carp qw(croak);

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Text::Markdown::XS ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
    markdown	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.19';

require XSLoader;
XSLoader::load('Text::Markdown::Discount', $VERSION);

my %DISCOUNT_OPTION_FLAG = (
    normal_listitem => 0x01,
    alt_as_title    => 0x02,
    extended_attr   => 0x04,
);

sub with_html5_tags {
    # nop, just for compatibility
}

sub new {
    return bless {}, 'Text::Markdown::Discount';
}

sub markdown {
    my ($self, $text, $flags) = @_;

    # Detect functional mode, and create an instance for this run..
    unless (ref $self) {
        if ( $self ne __PACKAGE__ ) {
            my $ob = __PACKAGE__->new();
                                # $self is text, $text is options
            return $ob->markdown($self, $text, $flags);
        }
        else {
            croak('Calling ' . $self . '->markdown (as a class method) is not supported.');
        }
    }
    if (not defined $flags) {
        $flags = MKD_NOHEADER()|MKD_NOPANTS()|MKD_DLEXTRA()|MKD_FENCEDCODE();
    }

    if (ref $flags) {
        croak('markdown options must be a hash reference')
            unless ref $flags eq 'HASH';

        my %options = %{$flags};
        my $legacy_flags = delete $options{flags};
        if (not defined $legacy_flags) {
            $legacy_flags = MKD_NOHEADER()|MKD_NOPANTS()|MKD_DLEXTRA()|MKD_FENCEDCODE();
        }

        my $option_flags = 0;
        for my $name (keys %DISCOUNT_OPTION_FLAG) {
            $option_flags |= $DISCOUNT_OPTION_FLAG{$name}
                if delete $options{$name};
        }
        if (keys %options) {
            croak('unknown markdown option(s): ' . join(', ', sort keys %options));
        }

        return _markdown_with_options($text, $legacy_flags, $option_flags);
    }

    return _markdown($text, $flags);
}


1;
__END__

=for stopwords testsuite html5 hgroup nav superset

=head1 NAME

Text::Markdown::Discount - fast function for converting markdown to HTML (requires C compiler)

=head1 SYNOPSIS

  use Text::Markdown::Discount;
  my $html = markdown($text)

=head1 DESCRIPTION

Text::Markdown::Discount is a perl interface to the C<Discount> library,
a C implementation of John Gruber's C<markdown>.

It is the fastest of the
Perl modules available for converting markdown: see the list in L<"SEE ALSO">.
It passes Gruber's Markdown testsuite.

Given that the performance of Discount, Text::Markdown::Discount processes
markdown formatted text quickly and passes the Markdown test suite at
L<http://daringfireball.net/projects/downloads/MarkdownTest_1.0.zip>

The interface of the C<markdown()> function in this module
is not compatible with the C<markdown()> function in L<Text::Markdown>.

=head2 EXPORT

I<markdown> is exported by default.


=head2 FUNCTION

=over

=item C<< markdown($text, [$flags_or_options]) >>

=back

The legacy form accepts a scalar bitmap made by combining C<MKD_*>
constants:

  my $html = markdown(
      $text,
      MKD_NOHEADER | MKD_NOPANTS | MKD_FENCEDCODE,
  );

The options form accepts a hash reference:

  my $html = markdown($text, {
      flags           => MKD_NOHEADER | MKD_NOPANTS,
      normal_listitem => 1,
      alt_as_title    => 1,
      extended_attr   => 1,
  });

The C<flags> option is the same legacy bitmap accepted by the scalar form.
If it is omitted or undefined, the existing default bitmap is used.

C<normal_listitem> disables GitHub-style checkbox list items.
C<alt_as_title> uses image alt text as its title when no title is specified.
With the bundled Discount 3.0.2.0 release, images are not rendered as expected
when this option is enabled. The option is passed through unchanged so it will
follow upstream behavior when Discount is updated.
C<extended_attr> enables extended attribute suffixes on links, images, and
reference links. These options do not consume bits in the legacy bitmap and
are therefore safe on 32-bit Perl builds.

=head1 SEE ALSO

There are other modules on CPAN for converting Markdown:

=over 4

=item *

L<Text::Markdown> is a pure-perl markdown converter.

=item *

L<Markdent> is a toolkit for parsing markdown,
which can also be used to convert markdown to HTML.

=item *

L<Text::Markup> is a converter than can handle a number of input formats, including markdown.

=item *

L<Text::MultiMarkdown> converts MultiMarkdown (a superset of the original markdown format)
to HTML.

=back

Additional markdown resources:

=over 4

=item *

L<Discount|http://www.pell.portland.or.us/~orc/Code/markdown/> -
David Loren Parsons's library for converting markdown, written in C.

=item *

L<Markdown definition|http://daringfireball.net/projects/markdown/> -
John Gruber's original definition of the markdown format.

=item *

L<Markdown testsuite|http://daringfireball.net/projects/downloads/MarkdownTest_1.0.zip> -
John Gruber's testsuite for markdown.

=item *

L<Markdown modules|http://neilb.org/reviews/markdown.html> - a review
of all Perl modules for handling markdown, written by Neil Bowers.

=back

=head1 AUTHOR

Masayoshi Sekimura, E<lt>sekimura@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Masayoshi Sekimura

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

This product includes software developed by
David Loren Parsons <http://www.pell.portland.or.us/~orc>

=cut
