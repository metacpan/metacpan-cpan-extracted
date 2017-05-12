package XML::Grammar::FictionBase::TagsTree2XML;

use strict;
use warnings;

use MooX 'late';

our $VERSION = '0.14.11';

use XML::Writer;
use HTML::Entities ();

sub _get_xml_xml_ns
{
    return "http://www.w3.org/XML/1998/namespace";
}

sub _get_xlink_xml_ns
{
    return "http://www.w3.org/1999/xlink";
}


has '_parser_class' =>
(
    is => "ro",
    isa => "Str",
    init_arg => "parser_class",
    default => "XML::Grammar::Fiction::FromProto::Parser::QnD",
);

has "_parser" => (
    'is' => "rw",
    lazy => 1,
    default => sub {
        my $self = shift;
        return $self->_parser_class->new();
    },
);

sub _get_initial_writer
{
    my $self = shift;

    my $writer = XML::Writer->new(
        OUTPUT => $self->_buffer(),
        ENCODING => "utf-8",
        NAMESPACES => 1,
        PREFIX_MAP =>
        {
            $self->_get_default_xml_ns() => "",
            $self->_get_xml_xml_ns() => 'xml',
            $self->_get_xlink_xml_ns() => 'xlink',
        },
    );

    $writer->xmlDecl("utf-8");

    return $writer;
}

has "_writer" => (
    'is' => "rw",
    lazy => 1,
    default => sub { return shift->_get_initial_writer(); },
);

sub _get_initial_buffer {
    my $buffer = '';
    return \$buffer;
}

has '_buffer' => (
    is => "rw",
    lazy => 1,
    default => sub { return shift->_get_initial_buffer; },
);

sub _reset_buffer
{
    my $self = shift;

    $self->_buffer($self->_get_initial_buffer());
    $self->_writer($self->_get_initial_writer());

    return;
}

sub _flush_buffer
{
    my $self = shift;

    my $ret = $self->_buffer();
    $self->_reset_buffer();

    return $ret;
}

my %passthrough_elem =
(
    b => sub { return shift->_bold_tag_name(); },
    i => sub { return shift->_italics_tag_name(); },
);

sub _calc_passthrough_cb
{
    my ($self, $name) = @_;

    if (exists($passthrough_elem{$name}))
    {
        return $passthrough_elem{$name};
    }
    else
    {
        return undef();
    }
}

sub _calc_passthrough_name
{
    my ($self, $name, $elem) = @_;

    my $cb = $self->_calc_passthrough_cb($name);

    if (ref($cb) eq 'CODE')
    {
        return $cb->($self, $name, $elem,);
    }
    else
    {
        return $cb;
    }
}

sub _write_elem
{
    my ($self, $args) = @_;

    my $elem = $args->{elem};

    if (ref($elem) eq "")
    {
        $self->_writer->characters($elem);
    }
    else
    {
        return $self->_write_elem_obj($args);
    }
}

sub _write_Element_Paragraph
{
    my ($self, $elem) = @_;

    return $self->_output_tag_with_childs(
        {
            start => [$self->_paragraph_tag()],
            elem => $elem,
        },
    );
}

sub _write_Element_Element
{
    my ($self, $elem) = @_;

    return $self->_write_Element_elem($elem);
}

sub _write_Element_Comment
{
    my ($self, $elem) = @_;

    my $text = $elem->text();

    # To avoid trailing space due to a problem in XML::Writer
    $text =~ s{\A[\r\n]+}{}ms;

    if ($text =~ m{\n\z})
    {
        $text .= ' ';
    }

    $self->_writer->comment($text);
}

sub _calc_write_elem_obj_classes
{
    return [qw(Text Paragraph Element Comment)];
}

sub _output_tag_with_childs
{
    my ($self, $args) = @_;

    return
        $self->_output_tag({
            %$args,
            'in' => sub {
                return $self->_write_elem_childs( $args->{elem} );
            },
        });
}

sub _write_elem_childs
{
    my ($self, $elem) = @_;

    foreach my $child (@{$elem->_get_childs()})
    {
        $self->_write_elem({ elem => $child,},);
    }

    return;
}

sub _write_elem_obj
{
    my ($self, $args) = @_;

    my $elem = $args->{elem};

    foreach my $class (@{$self->_calc_write_elem_obj_classes()})
    {
        if ($elem->_short_isa($class))
        {
            my $meth = "_write_Element_$class";
            $self->$meth($elem);
            return;
        }
    }

    Carp::confess("Class of element not detected - " . ref($elem) . "!");
}

sub _write_Element_elem
{
    my ($self, $elem) = @_;

    my $name = $elem->name();

    if ($elem->_short_isa("InnerDesc"))
    {
        $self->_output_tag_with_childs(
            {
                start => ["inlinedesc"],
                elem => $elem,
            }
        );
        return;
    }
    elsif (defined(my $out_name = $self->_calc_passthrough_name($name, $elem)))
    {
        return $self->_output_tag_with_childs(
            {
                start => [$out_name],
                elem => $elem,
            }
        );
    }
    else
    {
        my $method = "_handle_elem_of_name_$name";

        $self->$method($elem);

        return;
    }
}

sub _handle_elem_of_name_s
{
    my ($self, $elem) = @_;

    $self->_write_scene({scene => $elem});
}

sub _handle_elem_of_name_br
{
    my ($self, $elem) = @_;

    $self->_writer->emptyTag("br");

    return;
}

sub _output_tag
{
    my ($self, $args) = @_;

    my @start = @{$args->{start}};
    $self->_writer->startTag([$self->_get_default_xml_ns(),$start[0]], @start[1..$#start]);

    $args->{in}->($self, $args);

    $self->_writer->endTag();
}

sub _convert_while_handling_errors
{
    my ($self, $args) = @_;

    eval {
        my $output_xml = $self->convert(
            $args->{convert_args},
        );

        open my $out, ">", $args->{output_filename};
        binmode $out, ":utf8";
        print {$out} $output_xml;
        close($out);
    };

    # Error handling.

    my $e;
    if ($e = Exception::Class->caught("XML::Grammar::Fiction::Err::Parse::TagsMismatch"))
    {
        warn $e->error(), "\n";
        warn "Open: ", $e->opening_tag->name(),
            " at line ", $e->opening_tag->line(), "\n"
            ;
        warn "Close: ",
            $e->closing_tag->name(), " at line ",
            $e->closing_tag->line(), "\n";

        exit(-1);
    }
    elsif ($e = Exception::Class->caught("XML::Grammar::Fiction::Err::Parse::LineError"))
    {
        warn $e->error(), "\n";
        warn "At line ", $e->line(), "\n";
        exit(-1);
    }
    elsif ($e = Exception::Class->caught("XML::Grammar::Fiction::Err::Parse::TagNotClosedAtEOF"))
    {
        warn $e->error(), "\n";
        warn "Open: ", $e->opening_tag->name(),
            " at line ", $e->opening_tag->line(), "\n"
            ;

        exit(-1);
    }
    elsif ($e = Exception::Class->caught())
    {
        if (ref($e))
        {
            $e->rethrow();
        }
        else
        {
            die $e;
        }
    }

    return;
}

sub _read_file
{
    my ($self, $filename) = @_;

    open my $in, "<", $filename or
        Carp::confess("Could not open the file \"$filename\" for slurping.");
    binmode $in, ":utf8";
    my $contents;
    {
        local $/;
        $contents = <$in>;
    }
    close($in);

    return $contents;
}

sub _calc_tree
{
    my ($self, $args) = @_;

    my $filename = $args->{source}->{file} or
        confess "Wrong filename given.";

    return $self->_parser->process_text($self->_read_file($filename));
}

sub _write_scene
{
    my ($self, $args) = @_;

    my $scene = $args->{scene};

    my $tag = $scene->name;

    if (($tag eq "s") || ($tag eq "scene"))
    {
        $self->_write_scene_main($scene);
    }
    else
    {
        confess "Improper scene tag - should be '<s>' or '<scene>'!";
    }

    return;
}


sub convert
{
    my ($self, $args) = @_;

    my $tree = $self->_calc_tree($args);
    if (!defined($tree))
    {
        Carp::confess("Parsing failed.");
    }

    $self->_convert_write_content($tree);

    return ${$self->_flush_buffer()};
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

XML::Grammar::FictionBase::TagsTree2XML - base class for the tags-tree
to XML converters.

=head1 VERSION

version 0.14.11

=head1 VERSION

Version 0.14.11

=head2 $self->convert({ source => { file => $path_to_file } })

Converts the file $path_to_file to XML and returns it. Throws an exception
on failure.

=head2 meta()

Internal - (to settle pod-coverage.).

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
