package UR::Doc::Writer::Pod;

use strict;
use warnings;

use UR;
our $VERSION = "0.47"; # UR $VERSION;

use UR::Doc::Section;
use Carp qw/croak/;

class UR::Doc::Writer::Pod {
    is => 'UR::Doc::Writer',
};

sub render {
    my $self = shift;
    $self->content('');
    $self->_render_header;
    $self->_render_index;
    map { $self->_render_section($_) } $self->sections;
    $self->_render_footer;
    return $self->content;
}

sub _render_header {
    my $self = shift;

    $self->_append("\n\n=pod\n\n");
    if (my $title = $self->title) {
        $self->_append("=head1 $title\n\n");
    }
}

sub _render_index {
    # no indexing for pod
}

sub _render_section {
    my ($self, $section) = @_;
    my $title = $section->title;
    $self->_append("=head1 $title\n") if $title;
    my $content = $section->content;
    if ($section->format eq 'html') {
        $self->warning_message("Skipping html section '$title' while rendering pod");
    } elsif ($section->format eq 'txt' or $section->format eq 'pod') {
        $self->_append("\n\n=pod\n\n$content\n\n=cut\n\n");
    } else{
        croak "Unknown section type " . $section->type;
    }
}

sub _render_footer {
    my $self = shift;
}

1;
