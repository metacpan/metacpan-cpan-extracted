#!/usr/bin/env perl

use strict;
use warnings;

use Curses::UI;
use Encode qw(encode_utf8);
use Unicode::Block::Ascii;
use Unicode::Block::List;

# Get unicode block list.
my $list = Unicode::Block::List->new;
my @unicode_block_list = $list->list;

# Window.
my $cui = Curses::UI->new;
my $win = $cui->add('window_id', 'Window');
$win->set_binding(\&exit, "\cQ", "\cC");

# Popup menu.
my $popupbox = $win->add(
        'mypopupbox', 'Popupmenu',
        '-labels' => {
                map { $_, $_ } @unicode_block_list,
        },
        '-onchange' => sub {
                my $self = shift;
                $cui->leave_curses;
                my $block = $list->block($self->get);
                my $block_ascii = Unicode::Block::Ascii->new(%{$block});
                print encode_utf8($block_ascii->get)."\n";
                exit 0;
        },
        '-values' => \@unicode_block_list,
);
$popupbox->focus;

# Loop.
$cui->mainloop;

# Output after select 'Geometric Shapes' item:
# ┌────────────────────────────────────────────────────────┐
# │                    Geometric Shapes                    │
# ├────────┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┤
# │        │ 0│ 1│ 2│ 3│ 4│ 5│ 6│ 7│ 8│ 9│ A│ B│ C│ D│ E│ F│
# ├────────┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┤
# │ U+25ax │ ■│ □│ ▢│ ▣│ ▤│ ▥│ ▦│ ▧│ ▨│ ▩│ ▪│ ▫│ ▬│ ▭│ ▮│ ▯│
# ├────────┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┤
# │ U+25bx │ ▰│ ▱│ ▲│ △│ ▴│ ▵│ ▶│ ▷│ ▸│ ▹│ ►│ ▻│ ▼│ ▽│ ▾│ ▿│
# ├────────┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┤
# │ U+25cx │ ◀│ ◁│ ◂│ ◃│ ◄│ ◅│ ◆│ ◇│ ◈│ ◉│ ◊│ ○│ ◌│ ◍│ ◎│ ●│
# ├────────┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┤
# │ U+25dx │ ◐│ ◑│ ◒│ ◓│ ◔│ ◕│ ◖│ ◗│ ◘│ ◙│ ◚│ ◛│ ◜│ ◝│ ◞│ ◟│
# ├────────┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┤
# │ U+25ex │ ◠│ ◡│ ◢│ ◣│ ◤│ ◥│ ◦│ ◧│ ◨│ ◩│ ◪│ ◫│ ◬│ ◭│ ◮│ ◯│
# ├────────┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┤
# │ U+25fx │ ◰│ ◱│ ◲│ ◳│ ◴│ ◵│ ◶│ ◷│ ◸│ ◹│ ◺│ ◻│ ◼│◽│◾│ ◿│
# └────────┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┘