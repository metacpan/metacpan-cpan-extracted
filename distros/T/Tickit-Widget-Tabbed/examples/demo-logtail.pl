#!/usr/bin/perl

use strict;
use warnings;

use Tickit::Async;

use Tickit::Widget::Tabbed;
use Tickit::Widget::Scroller;
use Tickit::Widget::Scroller::Item::Text;

use IO::Async::Loop;
use IO::Async::FileStream;
use IO::Async::Protocol::LineStream;

my $tabbed = Tickit::Widget::Tabbed->new(
        tab_position => "bottom",
        pen_active => Tickit::Pen->new( u => 1 ),
);

my $loop = IO::Async::Loop->new;
foreach my $path ( @ARGV ) {
        open my $fh, "<", $path or die "Cannot open $path for reading - $!";

        my $scroller = Tickit::Widget::Scroller->new;
        my $tab = $tabbed->add_tab( $scroller, label => $path );

        my $stream = IO::Async::Protocol::LineStream->new(
                transport => IO::Async::FileStream->new(
                        read_handle => $fh,
                        on_initial => sub {
                                my ( $self ) = @_;
                                $self->seek_to_last( "\n" );
                        },
                ),
                on_read_line => sub {
                        my ( $self, $line ) = @_;
                        my $item = Tickit::Widget::Scroller::Item::Text->new( $line );
                        $scroller->push( $item );
                        $tab->pen->chattr( fg => 5 );
                },
        );

        $tab->set_on_activated( sub {
                my $self = shift;
                $self->pen->delattr( 'fg' );
        } );

        $loop->add( $stream );
}

my $tickit = Tickit::Async->new;
$loop->add( $tickit );

$tickit->set_root_widget( $tabbed );

$tickit->run;
