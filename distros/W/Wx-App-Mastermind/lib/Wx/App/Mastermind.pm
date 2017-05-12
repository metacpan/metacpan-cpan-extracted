package Wx::App::Mastermind;

=head1 NAME

Wx::App::Mastermind - a nontrivial example of wxPerl threads

=head1 DESCRIPTION

A simple Mastermind game whose main purpose is to demonstrate
the use of thread in wxPerl, in a task for which threads are
overkill anyway.

=cut

use strict;
use warnings;
use base qw(Wx::Frame Class::Accessor::Fast);

our $VERSION = '0.02';

use Wx qw(:sizer);
use Wx::Event qw(EVT_MENU EVT_CLOSE);

use Wx::App::Mastermind::Board;
use Wx::App::Mastermind::Player::Computer;
use Wx::App::Mastermind::Player::Human;

__PACKAGE__->mk_accessors( qw(finished) );
__PACKAGE__->mk_ro_accessors( qw(human computer) );

sub new {
    my( $class ) = @_;
    my $self = $class->SUPER::new( undef, -1, 'MasterMind' );

    $self->{computer} = Wx::App::Mastermind::Player::Computer->new( tries => 10 );
    $self->{human} = Wx::App::Mastermind::Player::Human->new( tries => 10 );

    my $szGames = Wx::BoxSizer->new( wxHORIZONTAL );

    foreach my $player ( $self->human, $self->computer ) {
        my $board = Wx::App::Mastermind::Board->new( $self, $player );

        $board->add_subscriber( 'turn_finished', $self, 'on_turn' );
        $szGames->Add( $board, 1, wxGROW|wxALL, 5 );
    }

    my $file = Wx::Menu->new;
    EVT_MENU( $self, $file->Append( -1, "&New game" ), sub { $self->reset } );
    $file->AppendSeparator;
    EVT_MENU( $self, $file->Append( -1, "E&xit" ), sub { $self->on_exit } );
    EVT_CLOSE( $self, sub { $self->on_close; $_[1]->Skip } );

    my $menubar = Wx::MenuBar->new;
    $menubar->Append( $file, "&File" );

    $self->SetMenuBar( $menubar );

    $self->SetIcon( Wx::GetWxPerlIcon );
    $self->SetSizerAndFit( $szGames );
    $self->Show( 1 );

    return $self;
}

sub reset {
    my( $self ) = @_;

    $self->human->reset;
    $self->computer->reset;
    $self->human->start;
    $self->computer->start;
}

sub on_exit {
    my( $self ) = @_;

    $self->Hide;
    $self->Close;
    $self->Destroy;
}

sub on_close {
    my( $self ) = @_;

    $self->human->terminate;
    $self->computer->terminate;
}

sub stop {
    my( $self ) = @_;

    $self->human->stop;
    $self->computer->stop;
}

sub on_turn {
    my( $self, $item, $event, %params ) = @_;

    my $other = $item == $self->human->board ? $self->computer : $self->human;

    if(    $other == $self->human
        && ( $self->computer->won || $self->human->won ) ) {
        $self->human->board->show_code( 1 );
        $self->stop;
    } else {
        $other->play;
    }
}

1;

__END__

=head1 AUTHOR

Mattia Barbon <mbarbon@cpan.org>

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

