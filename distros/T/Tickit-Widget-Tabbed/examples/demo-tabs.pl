#!/usr/bin/perl

use strict;
use warnings;

use Tickit;

use Tickit::Widget::Static;
use Tickit::Widget::Tabbed;

use Getopt::Long;
GetOptions(
        'position|p=s' => \(my $position = "bottom"),
) or exit(1);

my $tabbed = Tickit::Widget::Tabbed->new(
        tab_position => $position,
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

$tickit->bind_key( 'M-Up'    => sub { $tabbed->tab_position( "top"    ) } );
$tickit->bind_key( 'M-Down'  => sub { $tabbed->tab_position( "bottom" ) } );
$tickit->bind_key( 'M-Left'  => sub { $tabbed->tab_position( "left"   ) } );
$tickit->bind_key( 'M-Right' => sub { $tabbed->tab_position( "right"  ) } );

$tickit->run;
