package XML::Grammar::Fortune;
$XML::Grammar::Fortune::VERSION = '0.1000';
use warnings;
use strict;

use Fatal (qw(open));

use MooX qw/late/;

use XML::GrammarBase::Role::RelaxNG v0.2.2;
use XML::GrammarBase::Role::XSLT v0.2.2;

with('XML::GrammarBase::Role::RelaxNG');
with XSLT( output_format => 'html' );

has '+module_base'         => ( default => 'XML-Grammar-Fortune' );
has '+rng_schema_basename' => ( default => 'fortune-xml.rng' );

has '+to_html_xslt_transform_basename' =>
    ( default => 'fortune-xml-to-html.xslt' );

has '_mode'        => ( is => 'rw', init_arg => 'mode' );
has '_output_mode' => ( is => 'rw', init_arg => 'output_mode', );


sub run
{
    my $self = shift;
    my $args = shift;

    my $xslt_params = $args->{'xslt_params'} || {};

    my $output = $args->{'output'};
    my $input  = $args->{'input'};

    my $mode = $self->_mode();

    if ( $mode eq "validate" )
    {
        return $self->rng_validate_file($input);
    }
    elsif ( $mode eq "convert_to_html" )
    {
        my $translate = sub {
            my ( $medium, $encoding ) = @_;

            return $self->perform_xslt_translation(
                {
                    output_format => 'html',
                    source        => { file => $input },
                    output        => $medium,
                    encoding      => $encoding,
                    xslt_params   => $xslt_params,
                }
            );
        };
        if ( $self->_output_mode() eq "string" )
        {
            $$output .= $translate->( 'string', 'bytes' );
        }
        else
        {
            $translate->( { file => $output }, 'utf8' );
        }
    }

    return;
}

1;    # End of XML::Grammar::Fortune

__END__

=pod

=encoding UTF-8

=head1 NAME

XML::Grammar::Fortune - convert the FortunesXML grammar to other formats and from plaintext.

=head1 VERSION

version 0.1000

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

=head2 open

This function is introduced by Fatal. It is mentioned here, in order to settle
L<Pod::Coverage> . Ignore.

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/> .

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2008 by Shlomi Fish

This program is distributed under the MIT (Expat) License:
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

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/XML-Grammar-Fortune>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=XML-Grammar-Fortune>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/XML-Grammar-Fortune>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/X/XML-Grammar-Fortune>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=XML-Grammar-Fortune>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=XML::Grammar::Fortune>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-xml-grammar-fortune at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=XML-Grammar-Fortune>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/fortune-xml>

  git clone git://github.com/shlomif/fortune-xml.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/fortune-xml/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut
