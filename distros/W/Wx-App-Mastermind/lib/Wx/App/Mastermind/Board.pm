package Wx::App::Mastermind::Board;

use strict;
use warnings;
use base qw(Wx::Panel Class::Accessor::Fast Class::Publisher);

use Wx qw(:sizer :textctrl);
use Wx::Event qw(EVT_TEXT_ENTER EVT_PAINT EVT_LEFT_UP EVT_BUTTON);

use Wx::App::Mastermind::Board::PegStrip;
use Wx::App::Mastermind::Board::Editor;

__PACKAGE__->mk_accessors( qw(position) );
__PACKAGE__->mk_ro_accessors( qw(player editor button_go) );

use constant
  { PEG_WIDTH   => 20,
    PEG_HEIGHT  => 20,
    PEG_PADDING => 5,
    };

sub reset {
    my( $self ) = @_;

    $self->{moves} = [];
    $self->{answers} = [];
    $self->{position} = 0;
    $self->show_code( 0 );
    $self->Refresh;
}

sub new {
    my( $class, $parent, $player ) = @_;
    my $self = $class->SUPER::new( $parent );

    $self->{player} = $player;

    $player->board( $self );

    if( $self->player->moves_editable ) {
        my $editor_top = ( PEG_HEIGHT + PEG_PADDING ) * ( $self->tries + 1 )
                           + 3 * PEG_PADDING;
        $self->{editor} = Wx::App::Mastermind::Board::Editor->new
          ( { position  => [ PEG_PADDING, $editor_top ],
              board     => $self,
              } );

        my $go_top = $editor_top + PEG_HEIGHT + PEG_PADDING;
        my $go = Wx::Button->new( $self, -1, 'Go!',
                                  [ PEG_PADDING, $go_top ] );
        $self->{button_go} = $go;
        $self->start;

        EVT_LEFT_UP( $self, sub { $self->editor->on_click( $_[1] ) } );
        EVT_BUTTON( $self, $self->button_go, sub { $self->editor->on_move } );
    }
    $self->add_subscriber( 'move', $player->listener, 'on_move' );
    $self->add_subscriber( 'answer', $player->listener, 'on_answer' );

    EVT_PAINT( $self, \&on_paint );

    $self->SetSize( $self->get_size );
    $self->reset;

    return $self;
}

sub _create_strip {
    my $strip = Wx::App::Mastermind::Board::PegStrip->new
      ( { peg_width   => PEG_WIDTH,
          peg_height  => PEG_HEIGHT,
          peg_padding => PEG_PADDING,
          } );

    return $strip;
}

sub on_paint {
    my( $self, $event ) = @_;
    my $dc = Wx::PaintDC->new( $self );

    my( $x, $y ) = ( PEG_PADDING, PEG_PADDING );
    my $strip = $self->_create_strip;
    my( $sx, $sy ) = $strip->get_size( $self->holes );

    if( $self->show_code ) {
        $strip->draw( $dc, $x, $y, $self->player->listener->game->code );
    }
    $y += PEG_HEIGHT + PEG_PADDING;

    foreach my $i ( 1 .. $self->tries ) {
        my $current =    $self->editor
                      && $i == $self->position + 1
                      && !$self->show_code;
        $strip->draw( $dc, $x, $y, $self->moves( $i - 1 ), undef, $current );
        $strip->draw( $dc, $x + $sx + 2 * PEG_PADDING,
                      $y, $self->answers( $i - 1 ) );

        $y += PEG_HEIGHT + PEG_PADDING;
    }

    $self->editor->draw( $dc ) if $self->editor;
}

sub add_move {
    my( $self, $move ) = @_;

    $self->moves->[ $self->position ] = $move;
    $self->Refresh;
    $self->notify_subscribers( 'move',
                               position => $self->position,
                               move     => $move,
                               );
}

sub add_answer {
    my( $self, $answer ) = @_;
    my @ans = ( ( 'K' ) x $answer->[0],
                ( 'W' ) x $answer->[1],
                ( ' ' ) x ( $self->holes - $answer->[0] - $answer->[1] ) );

    $self->answers->[ $self->position ] = \@ans;
    $self->Refresh;
    $self->notify_subscribers( 'answer',
                               position => $self->position,
                               answer   => $answer,
                               );
    $self->position( $self->position + 1 );
}

sub turn_finished {
    my( $self ) = @_;

    $self->notify_subscribers( 'turn_finished' );
}

sub start {
    my( $self ) = @_;

    return unless $self->editor;

    $self->editor->enabled( 1 );
    $self->button_go->Enable;
}

sub stop {
    my( $self ) = @_;

    return unless $self->editor;

    $self->editor->enabled( 0 );
    $self->button_go->Disable;
}

sub get_size {
    my( $self ) = @_;
    my $strip = $self->_create_strip;
    my( $w, $h ) = $strip->get_size( $self->holes );
    my( $ew ) = 0;

    return ( 2 * $w + 5 * PEG_PADDING,
             ( $h + PEG_PADDING ) * ( $self->tries + 1 ) + 50 );
}

sub hit_test {
    my( $self, $mx, $my ) = @_;
    my $strip = $self->_create_strip;
    my( $x, $y ) = ( PEG_PADDING, 2 * PEG_PADDING + PEG_HEIGHT );
    foreach my $i ( 1 .. $self->tries ) {
        my $hit = $strip->hit_test( $x, $y, $self->holes, $mx, $my );
        return [ 'move', $i - 1, $hit ] if $hit != -1;

        $y += PEG_HEIGHT + PEG_PADDING;
    }

    if( $self->editor ) {
        my $hit = $self->editor->hit_test( $mx, $my );
        return [ 'editor', $hit ] if $hit != -1;
    }

    return undef;
}

sub set_peg {
    my( $self, $x, $y, $peg ) = @_;
    my $move = $self->{moves}[$x] ||= [ ( ' ' ) x $self->holes ];
    $move->[$y] = $peg;
    $self->Refresh;
}

sub show_code {
    my( $self, $show ) = @_;

    return $self->{show_code} if @_ == 1;
    $self->{show_code} = $show;
    $self->Refresh;
}

sub _get {
    return $_[1] if @_ == 2;
    if( $_[2] >= @{$_[1]} ) {
        return [ ( ' ' ) x $_[0]->holes ];
    } else {
        return $_[1][$_[2]];
    }
}

sub moves   { my $self = shift; $self->_get( $self->{moves}, @_ ) }
sub answers { my $self = shift; $self->_get( $self->{answers}, @_ ) }
sub pegs    { $_[0]->player->pegs }
sub holes   { $_[0]->player->holes }
sub tries   { $_[0]->player->tries }

1;
