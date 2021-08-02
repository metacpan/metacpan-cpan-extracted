package Text::Markdown::Discount;

use 5.008000;
use strict;
use warnings;

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

our $VERSION = '0.13';

require XSLoader;
XSLoader::load('Text::Markdown::Discount', $VERSION);

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
        $flags = MKD_NOHEADER()|MKD_NOPANTS();
    }
    return _markdown($text, $flags);
}


1;
__END__

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

The interface of the C<markdown()> function in this module
is not compatible with the C<markdown()> function in L<Text::Markdown>.

=head2 EXPORT

I<markdown> is exported by default.


=head2 FUNCTION

=over

=item C<Text::Markdown::Discount::with_html5_tags()>

This function enables html5 block-level elements support.
C<< Text::Markdown::Discount::markdown() >> will handle these html5 tags as
block elements: aside, footer, header, hgroup, nav, section, article.

B<NOTE>: There is no way to disable/re-enable this feature in one process right now.

  use Text::Markdown::Discount;
  Text::Markdown::Discount::with_html5_tags();
  my $html = markdown('<article>content</article>');
  #
  # In $html, <article> tag won't be wrapped with <p> tag

=back

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
