
package WKHTMLTOPDF;

use Moose;
with 'MooseX::Role::Cmd';

our $VERSION = '0.02';

=head1 NAME

WKHTMLTOPDF - Perl interface to the wkhtmltopdf program for producing PDF-File from HTML-File.

=head1 SYNOPSIS

    use WKHTMLTOPDF;

    my $pdf = new WKHTMLTOPDF;
    $pdf->_input_file('test.html');
    $pdf->_output_file('test.pdf');
    $pdf->grayscale(1);

    $pdf->generate;

=head1 DESCRIPTION

Please, visit http://code.google.com/p/wkhtmltopdf/

=cut

use constant DEFAULT_BIN_NAME => '/usr/bin/wkhtmltopdf';

=head1 ATTRIBUTES

=head2 _input_file

Path of input file.

=cut

has '_input_file' => ( is => 'rw', isa => 'Str' );

=head2 _out_file

Path of output file.

=cut

has '_output_file' => ( is => 'rw', isa => 'Str' );

=head2 bin_name

Sets the binary executable name for the command you want to run. Defaul is /usr/bin/wkhtmltopdf.

=cut

has 'bin_name' => ( is => 'rw', isa => 'Str', default => DEFAULT_BIN_NAME );

=head2 General Options

=head3 collate

Collate when printing multiple copies.

=cut

has 'collate' => (is => 'rw', isa => 'Bool', default => 0);

=head3 copies

Number of copies to print into the pdf file. Default is 1.

=cut

has 'copies' => (is => 'rw', isa => 'Int');

=head3 orientation

Set orientation to Landscape or Portrait.

=cut

has 'orientation' => (is => 'rw', isa => 'Str');

=head3 page-size

Set paper size to: A4, Letter, etc.

=cut

has 'page-size' => (is => 'rw', isa => 'Str');

=head3 proxy

Use a proxy.

=cut

has 'proxy' => (is => 'rw', isa => 'Str');

=head3 username

HTTP Authentication username.

=cut

has 'username' => (is => 'rw', isa => 'Str');

=head3 password

HTTP Authentication password.

=cut

has 'password' => (is => 'rw', isa => 'Str');

=head3 custom-header

Set an additional HTTP header (repeatable).

=cut

has 'custom-header' => ( is => 'rw', isa => 'Str');

=head3 book

Set the options one would usually set when printing a book.

=cut

has 'book' => ( is => 'rw', isa => 'Bool', default => 0);

=head3 cover

Use html document as cover. It will be inserted before the toc with no headers and footers.

=cut

has 'cover' => (is => 'rw', isa => 'Str');

=head3 default-header

Add a default header, with the name of the page to the left, and the page number to the right, this is short for: --header-left='[webpage]' --header-right='[page]/[toPage]' --top 2cm --header-line.

=cut

has 'default-header' => (is => 'rw', isa => 'Bool', default => 0);

=head3 toc

Insert a table of content in the beginning of the document.

=cut

has 'toc' => (is => 'rw', isa => 'Bool', default => 0);

=head3 dpi

Change the dpi explicitly (this has no effect on X11 based systems).

=cut

has 'dpi' => (is => 'rw', isa => 'Str');

=head3 disable-javascript

Do not allow web pages to run javascript.

=cut

has 'disable-javascript' => (is => 'rw', isa => 'Bool', default => 0);

=head3 grayscale

PDF will be generated in grayscale.

=cut

has 'grayscale' => (is => 'rw', isa => 'Bool', default => 0);

=head3 lowquality

Generates lower quality pdf/ps. Useful to shrink the result document space.

=cut

has 'lowquality' => (is => 'rw', isa => 'Bool', default => 0);

=head3 margin-bottom

Set the page bottom margin (default 10mm).

=cut

has 'margin-bottom' => (is => 'rw', isa => 'Str');

=head3 margin-left

Set the page left margin (default 10mm).

=cut

has 'margin-left' => (is => 'rw', isa => 'Str');

=head3 margin-right

Set the page right margin (default 10mm).

=cut

has 'margin-right' => (is => 'rw', isa => 'Str');

=head3 margin-top

Set the page top margin (default 10mm).

=cut

has 'margin-top' => (is => 'rw', isa => 'Str');

=head3 redirect-delay

Wait some milliseconds for js-redirects (default 200).

=cut

has 'redirect-delay' => (is => 'rw', isa => 'Int');

=head3 enable-plugins

Enable installed plugins (such as flash).

=cut

has 'enable-plugins' => ( is => 'rw', isa => 'Bool', default => 0);

=head3 zoom

Use this zoom factor (default 1).

=cut

has 'zoom' => (is => 'rw', isa => 'Str');

=head3 disable-internal-links

Do no make local links.

=cut

has 'disable-internal-links' => (is => 'rw', isa => 'Bool', default => 0);

=head3 disable-external-links

Do no make links to remote web pages.

=cut

has 'disable-external-links' => (is => 'rw', isa => 'Bool', default => 0);

=head3 print-media-type

Use print media-type instead of screen.

=cut

has 'print-media-type' => (is => 'rw', isa => 'Bool', default => 0);

=head3 page-offset

Set the starting page number (default 1).

=cut

has 'page-offset' => (is => 'rw', isa => 'Int');

=head3 disable-smart-shrinking 

Disable the intelligent shrinking strategy used by WebKit that makes the pixel/dpi ratio none constant.

=cut

has 'disable-smart-shrinking' => (is => 'rw', isa => 'Bool', default => 0);

=head3 use-xserver

Use the X server (some plugins and other stuff might not work without X11).

=cut

has 'use-xserver' => (is => 'rw', isa => 'Bool', default => 0);

=head3 enconding

Set the default text encoding, for input.

=cut

has 'encoding' => ( is => 'rw', isa => 'Str');

=head3 no-background

Do not print background.

=cut

has 'no-background' => (is => 'rw', isa => 'Bool', default => 0);

=head3 user-style-sheet

Specify a user style sheet, to load with every page.

=cut

has 'user-style-sheet' => (is => 'rw', isa => 'Str');

=head2 Headers and footer options

=head3 footer-center

Centered footer text.

=cut

has 'footer-center' => (is => 'rw', isa => 'Str');

=head3 footer-font-name

Set footer font name (default Arial)

=cut

has 'footer-font-name' => (is => 'rw', isa => 'Str');

=head3 footer-font-size

Set footer font size (default 11)

=cut

has 'footer-font-size' => (is => 'rw', isa => 'Int');

=head3 footer-left

Left aligned footer text.

=cut

has 'footer-left' => (is => 'rw', isa => 'Str');

=head3 footer-line

Display line above the footer

=cut

has 'footer-line' => (is => 'rw', isa => 'Bool', default => 0);

=head3 footer-right

Right aligned footer text.

=cut

has 'footer-right' => (is => 'rw', isa => 'Str');

=head3 footer-spacing

Spacing between footer and content in mm (default 0).

=cut

has 'footer-spacing' => (is => 'rw', isa => 'Str');

=head3 footer-html

Adds a html footer.

=cut

has 'footer-html' => (is => 'rw', isa => 'Str');


=head3 header-center

Centered header text.

=cut

has 'header-center' => (is => 'rw', isa => 'Str');

=head3 header-font-name

Set header font name (default Arial)

=cut

has 'header-font-name' => (is => 'rw', isa => 'Str');

=head3 header-font-size

Set header font size (default 11)

=cut

has 'header-font-size' => (is => 'rw', isa => 'Int');

=head3 header-left

Left aligned header text.

=cut

has 'header-left' => (is => 'rw', isa => 'Str');

=head3 header-line

Display line above the header.

=cut

has 'header-line' => (is => 'rw', isa => 'Bool', default => 0);

=head3 header-right

Right aligned header text.

=cut

has 'header-right' => (is => 'rw', isa => 'Str');

=head3 header-spacing

Spacing between header and content in mm (default 0).

=cut

has 'header-spacing' => (is => 'rw', isa => 'Str');

=head3 header-html

Adds a html header header.

=cut

has 'header-html' => (is => 'rw', isa => 'Str');

=head2 Table of content options

=head3 toc-font-name

Set the font used for the toc (default Arial)

=cut

has 'toc-font-name' => (is => 'rw', isa => 'Str');

=head3 toc-no-dots

Do not use dots, in the toc

=cut

has 'toc-no-dots' => (is => 'rw', isa => 'Bool');

=head3 toc-depth

Set the depth of the toc (default 3).

=cut

has 'toc-depth' => (is => 'rw', isa => 'Int');

=head3 toc-header-text

The header text of the toc (default Table Of Contents).

=cut

has 'toc-header-text' => (is => 'rw', isa => 'Str');

=head3 toc-header-fs

The font size of the toc header (default 15).

=cut

has 'toc-hedaer-fs' => (is => 'rw', isa => 'Int');

=head3 toc-disable-links

Do not link from toc to sections

=cut

has 'toc-disable-links' => (is => 'rw', isa => 'Bool', default => 0);

=head3 toc-disable-back-links 

Do not link from section header to toc.

=cut

has 'toc-disable-back-links' => (is => 'rw', isa => 'Bool', default => 0);

=head3 toc-l1-font-size

Set the font size on level 1 of the toc (default 12)

=cut

has 'toc-l1-font-size' => (is => 'rw', isa => 'Int');

=head3 toc-l1-indentation

Set indentation on level 1 of the toc (default 0)

=cut

has 'toc-l1-indentation' => (is => 'rw', isa => 'Int');

=head3 toc-l2-font-size

Set the font size on level 2 of the toc (default 10)

=cut

has 'toc-l2-font-size' => (is => 'rw', isa => 'Int');

=head3 toc-l2-indentation

Set indentation on level 2 of the toc (default 20)

=cut

has 'toc-l2-indentation' => (is => 'rw', isa => 'Int');

=head3 toc-l3-font-size

Set the font size on level 3 of the toc (default 8)

=cut

has 'toc-l3-font-size' => (is => 'rw', isa => 'Int');

=head3 toc-l3-indentation

Set indentation on level 3 of the toc (default 40)

=cut

has 'toc-l3-indentation' => (is => 'rw', isa => 'Int');

=head3 toc-l4-font-size

Set the font size on level 6 of the toc (default 6)

=cut

has 'toc-l4-font-size' => (is => 'rw', isa => 'Int');

=head3 toc-l4-indentation

Set indentation on level 4 of the toc (default 6)

=cut

has 'toc-l4-indentation' => (is => 'rw', isa => 'Int');

=head3 toc-l5-font-size

Set the font size on level 5 of the toc (default 4)

=cut

has 'toc-l5-font-size' => (is => 'rw', isa => 'Int');

=head3 toc-l5-indentation

Set indentation on level 5 of the toc (default 80)

=cut

has 'toc-l5-indentation' => (is => 'rw', isa => 'Int');

=head3 toc-l6-font-size

Set the font size on level 6 of the toc (default 2)

=cut

has 'toc-l6-font-size' => (is => 'rw', isa => 'Int');

=head3 toc-l6-indentation

Set indentation on level 6 of the toc (default 100)

=cut

has 'toc-l6-indentation' => (is => 'rw', isa => 'Int');

=head3 toc-l7-font-size

Set the font size on level 7 of the toc (default 0)

=cut

has 'toc-l7-font-size' => (is => 'rw', isa => 'Int');

=head3 toc-l7-indentation

Set indentation on level 7 of the toc (default 120)

=cut

has 'toc-l7-indentation' => (is => 'rw', isa => 'Int');

=head2 Outline options

=head3 outline

Put an outline into the pdf.

=cut

has 'outline' => (is => 'rw', isa => 'Bool', default => 0);

=head3 outline-depth

Set the depth of the outline (default 4).

=cut

has 'outline-depth' => (is => 'rw', isa => 'Int');

=head1 METHODS

=head2 generate

Generate the PDF-File form a HTML-File.

=cut

sub generate {
    my $self = shift;
    $self->run(($self->_input_file, $self->_output_file));

}

=head1 AUTHOR

Thiago Rondon <thiago@aware.com.br>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under the same terms as Perl itself.

=cut


1;

