package XML::GrammarBase::Role::XSLT;

use strict;
use warnings;


=head1 NAME

XML::GrammarBase::Role::XSLT - a parameterized role for XSLT conversions.

=head1 VERSION

Version 0.2.3

=cut

use Package::Variant
    importing => ['MooX::Role' => ['late'],],
    subs => [ qw(has with) ];

# use MooX 'late';

use XML::LibXML '2.0017';
use XML::LibXSLT '1.80';

use autodie;

our $VERSION = '0.2.3';


sub make_variant
{
    my ($class, $target_package, %args) = @_;

    my $output_format = $args{output_format};

    with ('XML::GrammarBase::Role::XSLT::Global');

    has "to_${output_format}_xslt_transform_basename"
        => (isa => 'Str', is => 'rw');

    has "_to_${output_format}_stylesheet" =>
    (
        isa => "XML::LibXSLT::StylesheetWrapper",
        is => 'rw',
        default => sub { return shift->_calc_stylesheet($output_format), },
        lazy => 1,
    );

    return;
}

=head1 SYNOPSIS

    package XML::Grammar::MyGrammar::ToOtherStuff;

    use MooX 'late';

    use XML::GrammarBase::Role::RelaxNG;
    use XML::GrammarBase::Role::XSLT;

    with ('XML::GrammarBase::Role::RelaxNG');
    with XSLT(output_format => 'html');
    with XSLT(output_format => 'docbook');

    has '+module_base' => (default => 'XML-Grammar-MyGrammar');
    has '+rng_schema_basename' => (default => 'my-grammar.rng');

    has '+to_html_xslt_transform_basename' => (default => 'mygrammar-xml-to-html.xslt');
    has '+to_docbook_xslt_transform_basename' => (default => 'mygrammar-xml-to-docbook.xslt');

    package main;

    my $xslt = XML::Grammar::MyGrammar::ToOtherStuff->new(
        data_dir => "/path/to/data-dir",
    );

    # Throws an exception on failure.
    my $as_html = $xslt->perform_xslt_translation(
        {
            output_format => 'html'
            source => {file => $input_filename, },
            output => "string",
        }
    );

=head1 PARAMATERS

=head2 output_format

A Perl identifier string identifying the format.

=head1 SLOTS

=head2 module_base

The basename of the module - used for dist dir.

=head2 data_dir

The data directory where the XML assets can be found (the RELAX NG schema, etc.)

=head2 rng_schema_basename

The Relax NG Schema basename.

=head2 to_${output_format}_xslt_transform_basename

The basename of the primary XSLT transform file. Should be overrided in
the constructor or using C<has '+to_html'>. For example:

    has '+to_html_xslt_transform_basename' => (default => 'fiction-xml-to-html.xslt');

=head1 METHODS

=head2 $self->rng_validate_dom($source_dom)

Validates the DOM ( $source_dom ) using the RELAX-NG schema.

=head2 $self->rng_validate_file($file_path)

Validates the file in $file_path using the RELAX-NG schema.

=head2 $self->rng_validate_string($xml_string)

Validates the XML in the $xml_string using the RELAX-NG schema.

=head2 $converter->perform_xslt_translation

=over 4

=item * my $final_source = $converter->perform_xslt_translation({output_format => $format, source => {file => $filename}, output => "string" })

=item * my $final_source = $converter->perform_xslt_translation({output_format => $format, source => {string_ref => \$buffer}, output => "string" })

=item * my $final_dom = $converter->perform_xslt_translation({output_format => $format, source => {file => $filename}, output => "dom" })

=item * my $final_dom = $converter->perform_xslt_translation({output_format => $format, source => {dom => $libxml_dom}, output => "dom" })

=item * my $final_dom = $converter->perform_xslt_translation({output_format => $format, source => {dom => $libxml_dom}, output => {file => $path_to_file,}, })

=item * my $final_dom = $converter->perform_xslt_translation({output_format => $format, source => {dom => $libxml_dom}, output => {fh => $filehandle,}, })

=back

This method does the actual conversion with the output format of
$format. The C<'source'> argument points to a hash-ref with
keys and values for the source. If C<'file'> is specified there it points to the
filename to translate (currently the only available source). If
C<'string_ref'> is specified it points to a reference to a string, with the
contents of the source XML. If C<'dom'> is specified then it points to an XML
DOM as parsed or constructed by XML::LibXML.

The C<'output'> key specifies the return value. A value of C<'string'> returns
the XML as a string, and a value of C<'dom'> returns the XML as an
L<XML::LibXML> DOM object. If it is a hash ref then it specifies a
C<'file'> or a C<'fh'> with a filepath or filehandle respectively.

An optional C<'encoding'> parameter determines if one should output the string
as C<'utf8'> (the deafult - using L<XML::LibXSLT>'s
output_as_chars()) or as C<'bytes'> - using its output_as_bytes() .

An optional 'xslt_params' parmater allows one to specify a hash of XSLT
parameters.

=cut

=head2 BUILD

L<Moo> constructor. For internal use.

=head2 make_variant

L<Package::Variant> constructor. For internal use.

=head1 AUTHOR

Shlomi Fish, C<< <shlomif at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-xml-grammarbase at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-GrammarBase>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 THANKS

Thanks to Matt S. Trout L<http://metacpan.org/author/MSTROUT> and other
people from #moose on irc.perl.org for helping me figure out
L<Moo> / L<MooX> and steer me away from L<Any::Moose> , and for writing
the L<Moo> ecosystem.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc XML::GrammarBase

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=XML-GrammarBase>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/XML-GrammarBase>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/XML-GrammarBase>

=item * Search CPAN

L<http://search.cpan.org/dist/XML-GrammarBase/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Shlomi Fish.

This program is distributed under the MIT (X11) License:
L<http://www.opensource.org/licenses/mit-license.php>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

=cut

1; # End of XML::GrammarBase::RelaxNG::Validate

