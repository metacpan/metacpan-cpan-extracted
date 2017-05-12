package XML::Grammar::Fiction::FromProto;

use strict;
use warnings;
use autodie;

use Carp;

use MooX 'late';

extends("XML::Grammar::FictionBase::TagsTree2XML");

my $fiction_ns = q{http://web-cpan.berlios.de/modules/XML-Grammar-Fortune/fiction-xml-0.2/};


our $VERSION = '0.14.11';



my %lookup = (map { $_ => $_ } qw( li ol ul ));

around '_calc_passthrough_cb' => sub
{
    my $orig = shift;
    my $self = shift;
    my ($name) = @_;

    if ($lookup{$name})
    {
        return $name;
    }

    return $orig->($self, @_);
};

sub _output_tag_with_childs_and_common_attributes
{
    my ($self, $elem, $tag_name, $args) = @_;

    my $id = $elem->lookup_attr("id");
    my $lang = $elem->lookup_attr("lang");
    my $href = $elem->lookup_attr("href");

    my @attr;

    if (!defined($id))
    {
        if (! $args->{optional_id} )
        {
            Carp::confess($args->{missing_id_msg} || "Unspecified id!");
        }
    }
    else
    {
        push @attr, ([$self->_get_xml_xml_ns, "id"] => $id);
    }

    if (defined($lang))
    {
        push @attr, ([$self->_get_xml_xml_ns, 'lang'] => $lang);
    }

    if (! defined($href))
    {
        if ($args->{required_href})
        {
            Carp::confess(
                $args->{missing_href_msg} || 'Unspecified href in tag!'
            );
        }
    }
    else
    {
        push @attr, ([$self->_get_xlink_xml_ns(), 'href'] => $href);
    }

    return $self->_output_tag_with_childs(
        {
            'start' => [$tag_name, @attr,],
            elem => $elem,
        }
    );
}

sub _paragraph_tag
{
    return "p";
}

sub _handle_elem_of_name_a
{
    my ($self, $elem) = @_;

    $self->_output_tag_with_childs_and_common_attributes(
        $elem,
        'span',
        {
            optional_id => 1,
            required_href => 1,
            missing_href_msg => 'Unspecified href in a tag.',
        },
    );

    return;
}

sub _handle_elem_of_name_blockquote
{
    my ($self, $elem) = @_;

    $self->_output_tag_with_childs_and_common_attributes(
        $elem,
        'blockquote',
        {
            optional_id => 1,
        },
    );

    return;
}


sub _handle_elem_of_name_programlisting
{
    my ($self, $elem) = @_;

    my $throw_found_tag_exception = sub {
        XML::Grammar::Fiction::Err::Parse::ProgramListingContainsTags->throw(
            error => "<programlisting> tag cannot contain other tags.",
            line => $elem->open_line(),
        );
    };

    return $self->_output_tag(
        {
            start => ['programlisting'],
            elem => $elem,
            'in' => sub {
                foreach my $child (@{ $elem->_get_childs() })
                {
                    if ($child->_short_isa("Paragraph"))
                    {
                        foreach my $text_node (
                            @{ $child->children()->contents() }
                        )
                        {
                            if ($text_node->_short_isa("Text"))
                            {
                                $self->_write_elem({elem => $text_node});
                            }
                            else
                            {
                                $throw_found_tag_exception->();
                            }
                        }
                    }
                    else
                    {
                        $throw_found_tag_exception->();
                    }
                    # End of paragraph.
                    $self->_writer->characters("\n\n");
                }

                return;
            },
        }
    );

    return;
}

sub _handle_elem_of_name_span
{
    my ($self, $elem) = @_;

    $self->_output_tag_with_childs_and_common_attributes(
        $elem,
        'span',
        {
            optional_id => 1,
            missing_id_msg => "Unspecified id for span!",
        },
    );

    return;
}

sub _handle_elem_of_name_title
{
    my ($self, $elem) = @_;

    # TODO :
    # Eliminate the Law-of-Demeter-syndrome here.
    my $list = $elem->_get_childs()->[0];

    $self->_output_tag(
        {
            start => ["title"],
            in => sub {
                $self->_write_elem(
                    {
                        elem => $list,
                    }
                ),
            },
        },
    );

    return;
}

sub _bold_tag_name
{
    return "b";
}

sub _italics_tag_name
{
    return "i";
}

sub _write_Element_Text
{
    return shift->_write_elem_childs(@_);
}

sub _write_Element_List
{
    my ($self, $elem) = @_;

    foreach my $child (@{$elem->contents()})
    {
        $self->_write_elem({elem => $child, });
    }

    return;
}

around '_calc_write_elem_obj_classes' => sub
{
    my $orig = shift;
    my $self = shift;

    return ['List', @{$orig->($self)}];
};

sub _write_scene_main
{
    my ($self, $scene) = @_;

    $self->_output_tag_with_childs_and_common_attributes(
        $scene,
        "section",
        { missing_id_msg => "Unspecified id for scene!", },
    );

    return;
}

sub _write_body
{
    my $self = shift;
    my $args = shift;

    my $body = $args->{'body'};

    my $tag = $body->name;

    if ($tag ne "body")
    {
        confess "Improper body tag - should be '<body>'!";
    }

    $self->_output_tag_with_childs_and_common_attributes(
        $body,
        'body',
        { missing_id_msg => "Unspecified id for body tag!", },
    );

    return;
}

sub _get_default_xml_ns
{
    return $fiction_ns;
}

sub _convert_write_content
{
    my ($self, $tree) = @_;

    my $writer = $self->_writer;

    $writer->startTag([$fiction_ns, "document"], "version" => "0.2");
    $writer->startTag([$fiction_ns, "head"]);
    $writer->endTag();

    $self->_write_body({body => $tree});

    $writer->endTag();

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

XML::Grammar::Fiction::FromProto - module that converts well-formed
text representing prose to an XML format.

=head1 VERSION

version 0.14.11

=head1 VERSION

Version 0.14.11

=head2 new()

Accepts no arguments so far. May take some time as the grammar is compiled
at that point.

=head2 meta()

Internal - (to settle pod-coverage.).

=head2 $self->convert({ source => { file => $path_to_file } })

Converts the file $path_to_file to XML and returns it. Throws an exception
on failure.

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
