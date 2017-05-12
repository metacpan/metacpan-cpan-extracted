package XML::Grammar::Fortune;

use warnings;
use strict;

use Fatal (qw(open));

use File::Spec;

use MooX qw/late/;

use XML::GrammarBase::Role::RelaxNG v0.2.2;
use XML::GrammarBase::Role::XSLT v0.2.2;

with ('XML::GrammarBase::Role::RelaxNG');
with XSLT(output_format => 'html');

has '+module_base' => (default => 'XML-Grammar-Fortune');
has '+rng_schema_basename' => (default => 'fortune-xml.rng');


has '+to_html_xslt_transform_basename' =>
    (default => 'fortune-xml-to-html.xslt');

has '_mode' => (is => 'rw', init_arg => 'mode');
has '_output_mode' => (is => 'rw', init_arg => 'output_mode',);

=head1 NAME

XML::Grammar::Fortune - convert the FortunesXML grammar to other formats and from plaintext.

=head1 VERSION

Version 0.0600

=cut

our $VERSION = '0.0600';


=head1 SYNOPSIS

    use XML::Grammar::Fortune;

    # Validate files.

    my $validator =
        XML::Grammar::Fortune->new(
            {
                mode => "validate"
            }
        );

    # Returns 0 upon success - dies otherwise
    exit($validator->run({input => "my-fortune-file.xml"}));

    # Convert files to XHTML.

    my $converter =
        XML::Grammar::Fortune->new(
            {
                mode => "convert_to_html",
                output_mode => "filename"
            }
        );

    $converter->run(
        {
            input => "my-fortune-file.xml",
            output => "resultant-file.xhtml",
        }
    );

=head1 FUNCTIONS

=head2 my $processor = XML::Grammar::Fortune->new({mode => $mode, input => $in, output => $out, output_mode => "string",});

Creates a new processor with mode $mode, output_mode "string", and input and output files.

=head2 $self->run({ %args})

Runs the processor. If $mode is "validate", validates the document.

%args may contain:

=over 4

=item * xslt_params

Parameters for the XSLT stylesheet.

=item * input

Input source - depends on input_mode.

=item * output

Output destination - depends on output mode.

=back

=cut

sub run
{
    my $self = shift;
    my $args = shift;

    my $xslt_params = $args->{'xslt_params'} || {};

    my $output = $args->{'output'};
    my $input = $args->{'input'};

    my $mode = $self->_mode();

    if ($mode eq "validate")
    {
        return $self->rng_validate_file($input);
    }
    elsif ($mode eq "convert_to_html")
    {
        my $translate = sub {
            my ($medium, $encoding) = @_;

            return $self->perform_xslt_translation(
                {
                    output_format => 'html',
                    source => {file => $input},
                    output => $medium,
                    encoding => $encoding,
                    xslt_params => $xslt_params,
                }
            );
        };
        if ($self->_output_mode() eq "string")
        {
            $$output .= $translate->('string', 'bytes');
        }
        else
        {
            $translate->({file => $output}, 'utf8');
        }
    }

    return;
}

1; # End of XML::Grammar::Fortune

__END__

=head2 open

This function is introduced by Fatal. It is mentioned here, in order to settle
L<Pod::Coverage> . Ignore.

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/> .

=head1 BUGS

Please report any bugs or feature requests to C<bug-xml-grammar-fortune at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-Grammar-Fortune>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc XML::Grammar::Fortune


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=XML-Grammar-Fortune>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/XML-Grammar-Fortune>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/XML-Grammar-Fortune>

=item * Search CPAN

L<http://search.cpan.org/dist/XML-Grammar-Fortune>

=back


=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2008 by Shlomi Fish

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

