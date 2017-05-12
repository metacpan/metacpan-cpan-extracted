package XML::GrammarBase::Role::XSLT::Global;

use strict;
use warnings;


=head1 NAME

XML::GrammarBase::Role::XSLT::Global - a base, non-parameterised, role for an XSLT converter.

=head1 VERSION

Version 0.2.3

=cut

use MooX::Role 'late';

use XML::LibXML '2.0017';
use XML::LibXSLT '1.80';

use autodie;

our $VERSION = '0.2.3';

with ('XML::GrammarBase::Role::RelaxNG');

has '_xml_parser' => (
    isa => "XML::LibXML",
    is => 'rw',
    default => sub { return XML::LibXML->new; },
    lazy => 1,
);

has '_xslt_parser' => (
    isa => "XML::LibXSLT",
    is => 'rw',
    default => sub { return XML::LibXSLT->new; },
    lazy => 1,
);

sub _calc_stylesheet {
    my ($self, $output_format) = @_;

    my $style_doc = $self->_xml_parser()->parse_file(
        $self->dist_path_slot("to_${output_format}_xslt_transform_basename"),
    );

    return $self->_xslt_parser->parse_stylesheet($style_doc);
}

sub _calc_and_ret_dom_without_validate
{
    my $self = shift;
    my $args = shift;

    my $source = $args->{source};

    return
          exists($source->{'dom'})
        ? $source->{'dom'}
        : exists($source->{'string_ref'})
        ? $self->_xml_parser()->parse_string(${$source->{'string_ref'}})
        : $self->_xml_parser()->parse_file($source->{'file'})
        ;
}

sub _get_dom_from_source
{
    my $self = shift;
    my $args = shift;

    my $source_dom = $self->_calc_and_ret_dom_without_validate($args);

    my $ret_code;

    eval
    {
        $ret_code = $self->_rng()->validate($source_dom);
    };

    if (defined($ret_code) && ($ret_code == 0))
    {
        # It's OK.
    }
    else
    {
        confess "RelaxNG validation failed [\$ret_code == "
            . $self->_undefize($ret_code) . " ; $@]"
            ;
    }

    return $source_dom;
}

sub perform_xslt_translation
{
    my ($self, $args) = @_;

    my $output_format = $args->{output_format};
    my $encoding = ($args->{encoding} || 'utf8');

    my $source_dom = $self->_get_dom_from_source($args);

    my $stylesheet_method = "_to_${output_format}_stylesheet";
    my $stylesheet = $self->$stylesheet_method();


    my $medium = $args->{output};

    my $is_string = ($medium eq 'string');
    my $is_dom = ($medium eq 'dom');

    my $xslt_params = $args->{xslt_params} || {};

    if ($is_string or $is_dom)
    {
        my $results = $stylesheet->transform($source_dom, %$xslt_params);

        return
            $is_dom
            ? $results
            : ($encoding eq 'bytes')
            ? $stylesheet->output_as_bytes($results)
            : $stylesheet->output_as_chars($results)
            ;
    }
    elsif (ref($medium) eq 'HASH')
    {
        if (exists($medium->{'file'}))
        {
            open my $out, '>', $medium->{'file'};
            $self->perform_xslt_translation(
                {
                    %$args,
                    output => {fh => $out,},
                    encoding => 'bytes',
                }
            );
            close ($out);
            return;
        }
        if (exists($medium->{'fh'}))
        {
            print {$medium->{'fh'}}
            $self->perform_xslt_translation(
                {
                    %$args,
                    output => "string",
                }
            );
            return;
        }
    }

    confess "Unknown medium";
}

=head1 SYNOPSIS

    package XML::Grammar::MyGrammar::RelaxNG::Validate;

    use Moo;

    with ('XML::GrammarBase::Role::XSLT::Global');

=head1 DESCRIPTION

This is a utility global (non-variant) role used by
L<XML::GrammarBase::Role::XSLT> . For internal use.

=head1 METHODS

=head2 $self->perform_xslt_translation(...)

See L<XML::GrammarBase::Role::XSLT> .

=head1 AUTHOR

Shlomi Fish, C<< <shlomif at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-xml-grammarbase at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-GrammarBase>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




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

