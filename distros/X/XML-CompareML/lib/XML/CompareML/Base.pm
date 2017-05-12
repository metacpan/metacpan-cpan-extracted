package XML::CompareML::Base;

use strict;
use warnings;

=head1 NAME

XML::CompareML::Base - base class for the CompareML-to-something converters.

=head1 SYNOPSIS

see L<XML::CompareML>.

=head1 METHODS

=head2 new()

A constructor - should be used by a derived class.

=head2 $compare->process()

See L<XML::CompareML>
=cut

use XML::LibXML;

use XML::CompareML::DTD::Generate;

use base qw(Class::Accessor);

__PACKAGE__->mk_accessors(
    qw(_timestamp root_elem impls_indexes impls_names),
    qw(parser dom),
);

sub new
{
    my $class = shift;
    my $self = {};
    bless $self, $class;
    $self->_initialize(@_);
    return $self;
}

sub _findnodes
{
    my $self = shift;
    return $self->root_elem->findnodes(@_);
}

sub _xml_node_contents_to_string
{
    my $self = shift;
    my $node = shift;
    my @child_nodes = $node->childNodes();
    my $ret = join("", map { $_->toString() } @child_nodes);
    # Remove leading and trailing space.
    $ret =~ s!^\s+!!mg;
    $ret =~ s/\s+$//mg;
    return $ret;
}

sub _impl_get_tag_text
{
    my $self = shift;
    my $impl_elem = shift;
    my $tag = shift;
    my ($name_elem) = $impl_elem->getChildrenByTagName($tag);
    if (!defined($name_elem))
    {
        return;
    }
    return $self->_xml_node_contents_to_string($name_elem);
}

sub _impl_get_name
{
    my $self = shift;
    my $impl_elem = shift;
    return $self->_impl_get_tag_text($impl_elem, "name");
}

sub _get_implementations
{
    my $self = shift;
    return
        [
            map
                {
                    +{
                        'id' => $_->getAttribute("id"),
                        'name' => $self->_impl_get_name($_)
                    }
                }
            $self->_findnodes("/comparison/meta/implementations/impl")
        ];
}

sub _get_timestamp
{
    my $self = shift;
    my @nodes = $self->_findnodes("/comparison/meta/timestamp");
    if (@nodes)
    {
        return $self->_xml_node_contents_to_string($nodes[0]);
    }
    else
    {
        return undef;
    }
}

sub _initialize
{
    my $self = shift;
    my %args = (@_);
    my $parser;
    my $dom;
    if ($args{input_filename})
    {
        $parser = XML::LibXML->new();
        $parser->validation(0);
        $dom = $parser->parse_file($args{input_filename});
        my $dtd =
            XML::LibXML::Dtd->parse_string(
                XML::CompareML::DTD::Generate::get_dtd()
            );
        $dom->validate($dtd);
    }
    else
    {
        die "input_filename must be specified!";
    }
    if ($args{output_handle})
    {
        $self->{o} = $args{output_handle};
    }
    else
    {
        die "output_handle must be specified!";
    }
    $self->parser($parser);
    $self->dom($dom);
    $self->root_elem($dom->getDocumentElement());
}

sub process
{
    my $self = shift;

    my ($contents_elem) = $self->root_elem->getChildrenByTagName("contents");
    my ($top_section_elem) = $contents_elem->getChildrenByTagName("section");

    my @impls = @{$self->_get_implementations()};

    $self->{impls} = \@impls;
    $self->impls_indexes(+{ map { $impls[$_]->{'id'} => $_ } (0 .. $#impls) });
    $self->impls_names(+{map { $_->{'id'} => $_->{'name'} } @impls });
    $self->_timestamp($self->_get_timestamp());

    $self->{document_text} = "";
    $self->{toc_text} = "";

    # Make sure we print anything only when we finished extracting all
    # the meta-data.
    $self->_print_header();

    $self->_start_rendering();

    $self->_render_section('elem' => $top_section_elem, 'depth' => 0,);

    $self->_finish_rendering();

    print {*{$self->{o}}} $self->{document_text};

    $self->_print_footer();
}

sub _name
{
    my $self = shift;
    my $id = shift;
    return $self->impls_names->{$id};
}

sub _sorter
{
    my $self = shift;
    my $impl = shift;

    my $indexes = $self->impls_indexes();

    if (!exists($indexes->{$impl}))
    {
        die "Unknown system $impl";
    }
    return $indexes->{$impl};
}

sub _out
{
    my $self = shift;
    $self->{document_text} .= join("", @_);
}

sub _toc_out
{
    my $self = shift;
    $self->{toc_text} .= join("", @_);
}

sub _render_section
{
    my $self = shift;
    my %args = (@_);
    my $section_elem = $args{elem};
    my $depth = $args{depth} || 0;

    my ($expl) = $section_elem->getChildrenByTagName("expl");
    my ($title) = $section_elem->getChildrenByTagName("title");
    my ($compare) = $section_elem->getChildrenByTagName("compare");
    my @sub_sections = $section_elem->getChildrenByTagName("section");

    my $title_string = $title->string_value();

    my $id = $section_elem->getAttribute("id");

    my @args = (
        'depth' => $depth,
        'id' => $id,
        'title_string' => $title_string,
        'expl' => $expl,
        'sub_sections' => \@sub_sections,
        );

    $self->_render_section_start(
        @args
    );

    if ($compare)
    {
        $self->_render_sys_table_start(@args);

        my @systems = ($compare->getChildrenByTagName("s"));
        my %kv =
            (map
                { $_->getAttribute("id") => $self->_render_s_elem($_) }
                @systems
            );
        my @keys_sorted = (sort { $self->_sorter($a) <=> $self->_sorter($b) } keys(%kv));
        foreach my $k (@keys_sorted)
        {
            $self->_render_sys_table_row(
                'name' => $self->_name($k),
                'desc' => $kv{$k},
            );
        }
        $self->_render_sys_table_end();
    }

    foreach my $sub (@sub_sections)
    {
        $self->_render_section(
            'elem' => $sub,
            'depth' => ($depth+1)
            );
    }

    $self->_render_section_end(
        @args,
    );
}

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/>.

=head1 SEE ALSO

L<XML::CompareML>

=head1 COPYRIGHT AND LICENSE

Copyright 2004, Shlomi Fish. All rights reserved.

You can use, modify and distribute this module under the terms of the MIT X11
license. ( L<http://www.opensource.org/licenses/mit-license.php> ).

=cut

1;
