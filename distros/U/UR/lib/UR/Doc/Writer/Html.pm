package UR::Doc::Writer::Html;

use strict;
use warnings;

use UR;
our $VERSION = "0.47"; # UR $VERSION;

use UR::Doc::Section;
use UR::Doc::Pod2Html;
use Carp qw/croak/;

class UR::Doc::Writer::Html {
    is => 'UR::Doc::Writer',
};

sub render {
    my $self = shift;
    $self->content('');
    $self->_render_header;
    $self->_render_index;
    my $i = 0;
    for my $section ($self->sections) {
        $self->_render_section($section, $i++);
    }
    $self->_render_footer;
}

sub _render_header {
    my $self = shift;

    if ($self->navigation) {
        my @nav_html;
        for my $item (@{$self->navigation}) {
            my ($name, $uri) = @$item;
            if ($uri) {
                push(@nav_html, "<a href=\"$uri\">$name</a>");
            } else {
                push(@nav_html, $name);
            }
        }
        $self->_append(join(" :: ", @nav_html) . "<hr/>\n");
    }

    my $translator = new UR::Doc::Pod2Html;
    my $title;
    $translator->output_string($title);
    $translator->parse_string_document("=pod\n\n".$self->title."\n\n=cut\n\n");
    $self->_append("<h1><a name=\"___top\"></a>$title</h1>\n");

}

sub _render_index {
    my $self = shift;
    my @titles = grep { $_ and /./ } map { $_->title } $self->sections;
    my $i = 0;
    if (@titles) {
        $self->_append("\n<ul>\n".
            join("\n", map {"<li><a href=\"#___sec".($i++)."\">$_</a></li>"} @titles)."</ul>\n\n");
    }
}

sub _render_section {
    my ($self, $section, $idx) = @_;
    if (my $title = $section->title) {
        $self->_append("<h1><a name=\"___sec$idx\" href=\"#___top\">$title</a></h1>\n");
    }
    my $content = $section->content;
    if ($section->format eq 'html') {
        $self->_append($content);
    } elsif ($section->format eq 'txt' or $section->format eq 'pod') {
        $content = "\n\n=pod\n\n$content\n\n=cut\n\n";
        my $new_content;
        my $translator = new UR::Doc::Pod2Html;
        $translator->output_string($new_content);
        $translator->parse_string_document($content);
        $self->_append($new_content);
    } else {
        croak "Unknown section type " . $section->type;
    }
    $self->_append("<br/>\n");
}

sub _render_footer {
    my $self = shift;
    $self->_append("</body></html>");
}

sub generate_index {
    my ($self, @command_trees) = @_;
    return '' unless @command_trees;

    my $html = "<h1>Command Index</h1><hr/>\n";
    $html .= $self->_generate_index_body(@command_trees);
    return $html;
}

sub _generate_index_body {
    my ($self, @command_trees) = @_;
    return '' unless @command_trees;

    my $html = "<ul>\n";
    for my $tree (@command_trees) {
        my $name = $tree->{command_name_brief};
        my $uri = $tree->{uri};
        $html .= "<li><a href=\"$uri\">$name</a>\n";
        $html .= $self->_generate_index_body(@{$tree->{sub_commands}});
        $html .= "</li>\n";
    }
    $html .= "</ul>\n";
    return $html;
}

1;
