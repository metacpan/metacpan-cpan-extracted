#!/usr/bin/perl

use strict;
use warnings;

use Tickit;

use Tickit::Widget::Static;
use Tickit::Widget::Tabbed;

my $tabbed = Tickit::Widget::Tabbed->new(
        tab_position => "top",
        ribbon_class => "IndexCard",
        style => {
                active_fg => "hi-green",
                active_bg => "black",
        },
);

my $counter = 1;
sub add_tab
{
        $tabbed->add_tab(
                Tickit::Widget::Static->new( text => "Content for tab $counter" ),
                label => "tab$counter",
        );
        $counter++
}

add_tab for 1 .. 3;

my $tickit = Tickit->new();

$tickit->set_root_widget( $tabbed );

$tickit->bind_key(
        'C-a' => \&add_tab
);
$tickit->bind_key(
        'C-d' => sub {
                $tabbed->remove_tab( $tabbed->active_tab );
        },
);

$tickit->run;

use 5.026;
use Object::Pad 0.22;

class IndexCard extends Tickit::Widget::Tabbed::Ribbon;

method lines () { 3 }

use Tickit::Style -copy;
BEGIN {
        style_definition base =>
                tab_fg => "grey",
                tab_bg => 0,
                tab_b  => 0;
}

class IndexCard::horizontal extends IndexCard;

use Tickit::RenderBuffer qw(LINE_SINGLE);
use Tickit::Utils qw( textwidth );

method lines () { 2 }
method cols  () { 1 }

method render_to_rb ( $rb, $rect ) {
        my @tabs = $self->tabs;

        my $win = $self->window;
        $rb->clip( $rect );

        my $pen = $self->get_style_pen( "tab" );
        my $x = 1;
        $rb->erase_at(0, 0, $win->cols, $pen);
        $rb->hline_at(1, 0, $win->cols - 1, LINE_SINGLE, $pen);
        foreach my $tab (@tabs) {
                my $len = textwidth $tab->label;
                $rb->erase_at(1, $x, $len + 4, $pen) if $tab->is_active;
                $rb->hline_at(1, $x - 1, $x, LINE_SINGLE, $pen);
                $rb->hline_at(1, $x + $len + 3, $x + $len + 5, LINE_SINGLE, $pen);
                $rb->hline_at(0, $x, $x + $len + 3, LINE_SINGLE, $pen);
                $rb->vline_at(0, 1, $x, LINE_SINGLE, $pen);
                $rb->vline_at(0, 1, $x + $len + 3, LINE_SINGLE, $pen);
                $rb->text_at(0, $x + 2, $tab->label, $tab->is_active ? $self->active_pen : $pen);
                $x += $len + 4;
        }
}

method scroll_to_visible ($) { }
