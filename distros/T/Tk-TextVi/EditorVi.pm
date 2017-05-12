package EditorVi;

use strict;
use warnings;

use Tk;
use Tk::TextVi;

use base qw' Tk::Frame ';

Construct Tk::Widget 'EditorVi';

sub ClassInit {
    my ($self,$args) = @_;

    $self->SUPER::ClassInit( $args );
}

sub Populate {
    my($self,$args) = @_;

    $self->SUPER::Populate( $args );

    my $bottom = $self->Frame->pack( -side => 'bottom', -fill => 'x' );
    $bottom->configure( -height => 20 );
    $bottom->packPropagate(0);
    my $left = $bottom->Label( -font => 'Courier' )->pack( -side => 'left', -fill => 'x', -anchor => 'w' );
    my $right = $bottom->Label( -font => 'Courier' )->pack( -side => 'right',  -fill => 'x', -anchor => 'e' );

    my $scr = $self->Scrolled( 'TextVi',
        -scrollbars => 'e',
        -background => '#FFFFFF',
    )->pack( -side => 'top', -expand => 1, -fill => 'both' );

    my $textvi = $scr->Subwidget('scrolled');

    $self->ConfigSpecs(
        DEFAULT => [ $textvi ],
    );

    $self->Delegates(
        DEFAULT => [ $textvi ],
    );

    $self->Advertise( scroll => $scr );
    $self->Advertise( textvi => $textvi );
    $self->Advertise( left => $left );
    $self->Advertise( right => $right );

    $self->{textvi} = $textvi;
    $self->{lleft} = $left;
    $self->{lright} = $right;

    $textvi->configure( -statuscommand =>
    sub {
        my ($mode,$keys) = @_;

        $keys =~ s/([\x01-\x19])/'^'.chr(0x40+ord($1))/ge;

        my $rec = (substr($mode,-1,1) eq 'q') ? 'recording' : '';

        $left->configure( -foreground => '#000000' );

        if( $mode =~ /^n/ ) {
            $left->configure( -text => ' '.$rec );
            $right->configure( -text => $keys );
        }
        elsif( $mode =~ /^c/ ) {
            $left->configure( -text => ':' . $keys );
        }
        elsif( $mode =~ /^\// ) {
            $left->configure( -text => '/' . $keys );
        }
        elsif( $mode =~ /^in/ ) {
            $left->configure( -text => '-- (insert) --'.$rec );
            $right->configure( -text => $keys );
        }
        elsif( $mode =~ /^i/ ) {
            $left->configure( -text => '-- INSERT --'.$rec );
            $right->configure( -text => $keys );
        }
        elsif( $mode =~ /^v/ ) {
            $left->configure( -text => '-- VISUAL --'.$rec );
            $right->configure( -text => $keys );
        }
        elsif( $mode =~ /^V/ ) {
            $left->configure( -text => '-- VISUAL LINE --'.$rec );
            $right->configure( -text => $keys );
        }
    } );

    $textvi->configure( -messagecommand =>
    sub {
        $left->configure( -foreground => '#000000' );
        $left->configure( -text => $textvi->viMessage() );
    } );

    $textvi->configure( -errorcommand =>
    sub {
        $left->configure( -foreground => '#FF0000' );
        $left->configure( -text => $textvi->viError() );
    } );

    my %commands;

    $commands{quit} = sub { Tk::exit(0); };
    $commands{q} = $commands{quit};

    $commands{NOT_SUPPORTED} = sub {
        $_[0]->setError("Unrecognised command :$_[1]" );
    };

    $commands{edit} = sub {
        my ($w,$force,$arg) = @_;
        local undef $/;
        open my $fh, "<$arg" or do {
            $w->Contents('');
            return;
        };
        $w->Contents( <$fh> );
        $w->SetCursor( '1.0' );
        close $fh;
    };
    $commands{e} = $commands{edit};

    $textvi->commands( %commands );
}

1;

=head1 NAME

Tk::EditorVi - Composite Tk::TextVi widget

=head1 SYNOPSIS

    use Tk::EditorVi;

    $text = $window->EditorVi()->pack();

=head1 DESCRIPTION

The Tk::TextVi widget is somewhat limited in that it requires the user to implement the status bar and several callback functions.  This module provides a single composite widget that encapsulates the Tk::TextVi widget along with the status bar and scrollbars.

All configuration settings and methods are delegated to the Tk::TextVi widget.

The intent of this module is to provide a framework which can be easily modified as needed, not a stand-alone module.  Depending on its use, different composites (such as Tk::LineNumberText) or additional functionality in the callbacks may be needed.  Future versions may provide more general wrapping functionality.

=head1 ADVERTISED WIDGETS

    scroll      The Tk::Scrolled composite widget
    textvi      The Tk::TextVi widget
    left        The left status bar used for messages and status information
    right       The right status bar used for commands in progress

=head1 BUGS

No where near as general as it needs to be.

=head1 AUTHOR

Joseph Strom, C<< <j-strom@verizon.net> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Joseph Strom, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

