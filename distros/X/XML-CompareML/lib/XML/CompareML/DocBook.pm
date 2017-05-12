package XML::CompareML::DocBook;

use strict;
use warnings;

=head1 NAME

XML::CompareML::DocBook - convert CompareML to DocBook

=head1 SYNOPSIS

See L<XML::CompareXML>.

=cut

use XML::LibXML::Common qw(:w3c);

use base 'XML::CompareML::Base';

sub _print_header
{
    my $self = shift;
    my $o = $self->{o};
    print {*{$o}} <<"EOF";
<?xml version="1.0" encoding="iso-8859-1"?>
<!DOCTYPE article PUBLIC "-//OASIS//DTD DocBook XML V4.1.2//EN"
"/usr/share/sgml/docbook/xml-dtd-4.1.2/docbookx.dtd"[
]>
<article>

EOF
}

# Do Nothing
sub _start_rendering
{
}

# Do Nothing
sub _finish_rendering
{
}

sub _print_footer
{
    my $self = shift;
    print {*{$self->{o}}} "</article>\n";
}

sub _render_section_start
{
    my $self = shift;
    my %args = (@_);

    my $depth = $args{depth};
    my $id = $args{id};
    my $title_string = $args{title_string};
    my $expl = $args{expl};
    my $sub_sections = $args{sub_sections};

    if ($depth)
    {
        $self->_out("<section id=\"$id\">\n");
    }

    $self->_out("<title>$title_string</title>\n");

    if ($depth == 0)
    {
        if (defined($self->_timestamp()))
        {
            $self->_out("<articleinfo><date>" . $self->_timestamp() .
                "</date></articleinfo>\n");
        }
    }

    if ($expl)
    {
        $self->_out("<para>\n" . $self->_xml_node_contents_to_string($expl) . "\n</para>\n");
    }
}

sub _render_sys_table_start
{
    my ($self,%args) = @_;

    my $title_string = $args{title_string};

    $self->_out(<<"EOF");
<table frame=\"all\">
<title>Comparison - $title_string</title>
<tgroup cols=\"2\" align=\"left\" colsep=\"1\" rowsep=\"1\">
<colspec colname=\"system\" />
<colspec colname=\"description\" />
<thead>
<row>
<entry><emphasis>System</emphasis></entry>
<entry><emphasis>Description</emphasis></entry>
</row>
</thead>
<tbody>
EOF
}

sub _html_to_docbook
{
    my $parent_node = shift;
    my $not_first = shift;
    my @child_nodes = $parent_node->childNodes();
    my $ret = "";

    foreach my $node (@child_nodes)
    {
        if ($node->nodeType() == ELEMENT_NODE())
        {
            if ($node->nodeName() eq "a")
            {
                $ret .= "<ulink url=\"" . $node->getAttribute("href") . "\">";
            }
            else
            {
                my @attrs = $node->attributes();
                $ret .= "<" . $node->nodeName() . " " . join(" ", map { "$_=\"".$node->getAttribute($_)."\""} @attrs) . ">";
            }
            $ret .= _html_to_docbook($node, 1);

            if ($node->nodeName() eq "a")
            {
                $ret .= "</ulink>";
            }
            else
            {
                $ret .= "</" . $node->nodeName() . ">";
            }
        }
        else
        {
            $ret .= $node->toString();
        }
    }
    # Remove leading and trailing space.
    if (1)
    {
        $ret =~ s!^\s+!!mg;
        $ret =~ s/\s+$//mg;
    }
    return $ret;
}

sub _render_s_elem
{
    my ($self, $s_elem) = @_;
    return _html_to_docbook($s_elem);
}

sub _render_sys_table_row
{
    my ($self, %args) = @_;

    $self->_out("<row>\n<entry>" . $args{name}. "</entry>\n" .
                "<entry>\n" . $args{desc} . "\n</entry>\n</row>\n");
}

sub _render_sys_table_end
{
    my $self = shift;
    $self->_out("</tbody>\n</tgroup>\n</table>\n");
}

sub _render_section_end
{
    my ($self, %args) = @_;

    my $depth = $args{depth};

    if ($depth)
    {
        $self->_out("</section>\n");
    }
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

