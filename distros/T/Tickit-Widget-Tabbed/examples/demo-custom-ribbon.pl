#!/usr/bin/perl

use strict;
use warnings;

use Tickit;

use Tickit::Widget::Static;
use Tickit::Widget::Tabbed;

my $tabbed = Tickit::Widget::Tabbed->new(
   tab_position => "bottom",
   ribbon_class => "CustomRibbon",
   style => {
           active_b => 1,
           active_u => 1,
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

package CustomRibbon;
use base qw( Tickit::Widget::Tabbed::Ribbon );

use Tickit::Style -copy;

BEGIN {
        style_definition base =>
                current_fg => 8;
}

package CustomRibbon::horizontal;
use base qw( CustomRibbon );

use Tickit::Utils qw( textwidth );

sub lines { 1 }
sub cols  { 1 }

sub render_to_rb
{
        my $self = shift;
        my ( $rb, $rect ) = @_;

        my @tabs = $self->tabs;

        $rb->goto( 0, 0 );
        $rb->text( sprintf "[%d tabs]: ", scalar @tabs );

        my $active = $self->active_tab;
        $rb->text( $active->label, $self->active_pen );

        $rb->text( " [also:" );

        foreach my $tab ( @tabs ) {
                $rb->erase( 1 );
                if( $tab == $active ) {
                        $rb->text( "x" x textwidth( $tab->label ), $self->get_style_pen( "current" ) );
                }
                else {
                        $rb->text( $tab->label );
                }
        }

        $rb->text( "]" );

        $rb->erase_to( $self->window->cols );
}

sub scroll_to_visible { }
