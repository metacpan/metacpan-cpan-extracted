package Tickit::Widget::Statusbar;
# ABSTRACT: Terminal widget for showing status, CPU and memory
use strict;
use warnings;
use Object::Pad;
class Tickit::Widget::Statusbar :isa(Tickit::ContainerWidget);

our $VERSION = '0.006';

=head1 NAME

Tickit::Widget::Statusbar - provides a simple status bar implementation

=head1 SYNOPSIS

 my $statusbar = Tickit::Widget::Statusbar->new;
 $statusbar->update_status('Ready to start');

=head1 DESCRIPTION

Provides a status bar, typically for use at the bottom of the terminal to
indicate when we're busy doing something. You'll probably want this as the
last widget in a L<Tickit::Widget::VBox> with C<expand> omitted or set to 0.

Currently the statusbar contains the status text, a memory usage indicator (VSZ),
CPU usage, and a clock. It should also allow progress bars, sparklines,
and the ability to configure things, but as yet it does not.

=cut

use curry::weak;
use Tickit::Widget::Statusbar::Icon;
use Tickit::Widget::Statusbar::Clock;
use Tickit::Widget::Statusbar::CPU;
use Tickit::Widget::Statusbar::Memory;
use Tickit::Style;
use List::Util qw(max);
use Tickit::Utils qw(substrwidth textwidth);
use Scalar::Util qw(blessed);
use String::Tagged;

use constant WIDGET_PEN_FROM_STYLE => 1;

BEGIN {
    style_definition base =>
        fg => 'white',
        bg => 236,
        b => 0,
        spacing => 1;

    style_reshape_keys qw(spacing);
}

=head1 METHODS

Not too many user-serviceable parts inside as yet. This is likely to change in future.

=cut

method lines { 1 }
method cols  { 1 }

method children {
    @{$self->{children}};
}

=head2 new

Instantiates the status bar.

=cut

BUILD (%args) {
    my $status = delete($args{status}) // '';
    $self->{children} = [];
    $self->update_status($status);

    $self->add(
        $self->{mem} = Tickit::Widget::Statusbar::Memory->new or die "no widget?"
    );
    $self->add(
        $self->{cpu} = Tickit::Widget::Statusbar::CPU->new or die "no widget?"
    );
    $self->add(
        $self->{clock} = Tickit::Widget::Statusbar::Clock->new or die "no clock?",
    );
    return $self;
}

method add ($w, @args) {
    unshift @{$self->{children}}, $w;
    $self->SUPER::add($w, @args);
}

method add_icon ($txt, @args) {
    my $w = Tickit::Widget::Statusbar::Icon->new;
    $w->set_icon($txt);
    unshift @{$self->{children}}, $w;
    $self->SUPER::add($w, @args);
    $w
}

method children_changed {
    return unless my $win = $self->window;
    my $x = $win->cols;
    for my $child (reverse $self->children) {
        if(my $sub = $child->window) {
            # Tickit::Window
            $sub->change_geometry(
                0, $x - $child->cols, 1, $child->cols
            );
        } else {
            my $sub = $win->make_sub(
                0, $x - $child->cols, 1, $child->cols
            );
            $child->set_window($sub);
        }
        $x -= $child->cols + $self->get_style_values('spacing');
    }
}

method reshape {
    $self->children_changed;
    $self->SUPER::reshape(@_);
}

method window_gained {
    $self->SUPER::window_gained(@_);
    $self->children_changed;
}

method status { $self->{status} }

method render_to_rb ($rb, $rect) {
    my $txt = substrwidth $self->status, $rect->left, $rect->cols;
    my $base_pen = $self->get_style_pen;
    if(defined(my $v = $self->status)) {
        $rb->goto($rect->top, $rect->left);
        $v->iter_substr_nooverlap(sub {
            my ($substr, %tags) = @_;
            my $pen = Tickit::Pen::Immutable->new(
                $base_pen->getattrs,
                %tags
            );
            $rb->text($substr, $pen);
        });
    }

#   $rb->text_at($rect->top, $rect->left, $txt, $self->get_style_pen);
    # $rb->erase_at($rect->top, $rect->left + textwidth($txt), $rect->cols - textwidth($txt), $self->get_style_pen);
#   $rb->text_at($rect->top, $rect->left + textwidth($txt), ' ' x ($rect->cols - textwidth($txt)));
}

=head2 update_status

Set current status. Takes a single parameter - the string to set the status
to.

Returns $self.

=cut

method update_status ($status = '') {
    my $old_status = $self->{status};
    $self->{status} = $status;
    $self->{status} = String::Tagged->new($self->{status}) unless blessed $self->{status};
    $self->{status}->merge_tags(sub {
        my ($k, $left, $right) = @_;
        return $left eq $right;
    });
    $self->window->expose(Tickit::Rect->new(
        left => 0,
        top => 0,
        lines => 1,
        cols => max(textwidth($old_status->str), textwidth($self->{status}->str))
    )) if $self->window;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2011-2020. Licensed under the same terms as Perl itself.

