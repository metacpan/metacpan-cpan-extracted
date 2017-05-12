package XML::Grammar::FictionBase::XSLT::Converter;

use strict;
use warnings;

use Carp;
use File::Spec;

use File::ShareDir ':ALL';

use XML::LibXML;
use XML::LibXSLT;

use MooX 'late';

has '_data_dir' =>
(
    isa => 'Str',
    is => 'rw',
    lazy => 1,
    default => sub {
        return shift->_calc_data_dir();
    },
);

has '_data_dir_from_input' =>
(
    isa => 'Str',
    is => 'rw',
    init_arg => 'data_dir',
);

has '_rng' =>
(
    is => 'rw',
    lazy => 1,
    default => sub {
        return shift->_calc_rng();
    },
);

sub _calc_rng
{
    my $self = shift;

    return
        XML::LibXML::RelaxNG->new(
            location =>
            File::Spec->catfile(
                $self->_data_dir(),
                $self->rng_schema_basename(),
            ),
        );
}

has '_xml_parser' =>
(
    is => 'rw',
    lazy => 1,
    default => sub {
        return shift->_calc_xml_parser();
    },
);

sub _calc_xml_parser
{
    my $self = shift;

    return XML::LibXML->new();
}

has '_xslt_processor' =>
(
    is => 'rw',
    lazy => 1,
    default => sub {
        return shift->_calc_xslt_processor();
    },
);

sub _calc_xslt_processor
{
    my ($self) = @_;

    return XML::LibXSLT->new();
}

has '_stylesheet' =>
(
    is => 'rw',
    lazy => 1,
    default => sub {
        return shift->_calc_stylesheet();
    },
);

sub _calc_stylesheet
{
    my ($self) = @_;

    my $style_doc = $self->_xml_parser()->parse_file(
            File::Spec->catfile(
                $self->_data_dir(),
                $self->xslt_transform_basename(),
            ),
        );

    return $self->_xslt_processor->parse_stylesheet($style_doc);
}

has 'rng_schema_basename' => (is => 'ro', isa => 'Str', required => 1,);
has 'xslt_transform_basename' => (is => 'ro', isa => 'Str', required => 1,);


our $VERSION = '0.14.11';


sub _calc_data_dir
{
    my ($self) = @_;

    return $self->_data_dir_from_input() || dist_dir( 'XML-Grammar-Fiction');
}


sub _undefize
{
    my $v = shift;

    return defined($v) ? $v : "(undef)";
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
            . _undefize($ret_code) . " ; $@]"
            ;
    }

    return $source_dom;
}

sub perform_translation
{
    my ($self, $args) = @_;

    my $source_dom = $self->_get_dom_from_source($args);

    my $stylesheet = $self->_stylesheet();

    my $results = $stylesheet->transform($source_dom);

    my $medium = $args->{output};

    if ($medium eq "string")
    {
        return $stylesheet->output_string($results);
    }
    elsif ($medium eq "dom")
    {
        return $results;
    }
    else
    {
        confess "Unknown medium";
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

XML::Grammar::FictionBase::XSLT::Converter - base module that converts an XML
file to a different XML file using an XSLT transform.

=head1 VERSION

version 0.14.11

=head1 VERSION

Version 0.14.11

=head1 METHODS

=head2 new()

Accepts no arguments so far. May take some time as the grammar is compiled
at that point.

=head2 meta()

Internal - (to settle pod-coverage.).

=head2 rng_schema_basename()

Inherited - (to settle pod-coverage.).

=head2 xslt_transform_basename()

Inherited - (to settle pod-coverage.).

=head2 $converter->perform_translation

=over 4

=item * my $final_source = $converter->perform_translation({source => {file => $filename}, output => "string" })

=item * my $final_source = $converter->perform_translation({source => {string_ref => \$buffer}, output => "string" })

=item * my $final_dom = $converter->perform_translation({source => {file => $filename}, output => "dom" })

=item * my $final_dom = $converter->perform_translation({source => {dom => $libxml_dom}, output => "dom" })

=back

Does the actual conversion. The C<'source'> argument points to a hash-ref with
keys and values for the source. If C<'file'> is specified there it points to the
filename to translate (currently the only available source). If
C<'string_ref'> is specified it points to a reference to a string, with the
contents of the source XML. If C<'dom'> is specified then it points to an XML
DOM as parsed or constructed by XML::LibXML.

The C<'output'> key specifies the return value. A value of C<'string'> returns
the XML as a string, and a value of C<'dom'> returns the XML as an
L<XML::LibXML> DOM object.

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2007 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
http://rt.cpan.org/NoAuth/Bugs.html?Dist=XML-Grammar-Fiction or by email to
bug-xml-grammar-fiction@rt.cpan.org.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc XML::Grammar::Fiction

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/XML-Grammar-Fiction>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/XML-Grammar-Fiction>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=XML-Grammar-Fiction>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/XML-Grammar-Fiction>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/XML-Grammar-Fiction>

=item *

CPAN Forum

The CPAN Forum is a web forum for discussing Perl modules.

L<http://cpanforum.com/dist/XML-Grammar-Fiction>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.perl.org/dist/overview/XML-Grammar-Fiction>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/X/XML-Grammar-Fiction>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=XML-Grammar-Fiction>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=XML::Grammar::Fiction>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-xml-grammar-fiction at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-Grammar-Fiction>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<http://bitbucket.org/shlomif/perl-XML-Grammar-Fiction>

  hg clone ssh://hg@bitbucket.org/shlomif/perl-XML-Grammar-Fiction

=cut
