package Weaving::Tablet::Tk;

use warnings;
use strict;
use Carp;
use Weaving::Tablet;
use Tk;
require Tk::HList;
require Tk::FileSelect;
require Tk::FontDialog;
require Tk::ColorEditor;
use Data::Dumper;
use Moose;
use namespace::autoclean;
use File::Spec::Functions;
use File::Basename;

has 'pattern' =>
  ( isa => 'Weaving::Tablet', is => 'ro', writer => '_set_pattern' );
has 'window' =>
  ( isa => 'Tk::MainWindow', is => 'ro', writer => '_set_window' );
has 'canvas' =>
  ( isa => 'Tk::Frame', is => 'ro', writer => '_set_canvas' );
has 'small_font' => (
    isa     => 'Str',
    is      => 'ro',
    writer  => '_set_small_font',
    default => '-misc-fixed-medium-r-normal--10-100-75-75-c-60-iso8859-1'
);
has 'row_spacing' => (isa => 'Int', is => 'rw', default => 12);
has 'col_spacing' => (isa => 'Int', is => 'rw', default => 9);
sub half_col_size { my $self = shift; return int($self->col_spacing/2); }
has 'current_row' => (isa => 'Int', is => 'rw', default => 0);
has 'current_card' => (isa => 'Int', is => 'rw', default => 0);
has 'smooth' => (isa => 'Bool', is => 'rw', default => 0);
has 'outline' => (isa => 'Bool', is => 'rw', default => 0);
has 'outline_color' => (isa => 'Str', is => 'rw', default => 'black');
has 'overlap' => (isa => 'Bool', is => 'rw', default => 0);
has 'draw_grid'=> (isa => 'Bool', is => 'rw', default => 0);
has 'show_floats' => (isa => 'Bool', is => 'rw', default => 0);
has 'float_length' => (isa => 'Int', is => 'rw', default => 3);
has 'background_color' => (isa => 'Str', is => 'rw', default => 'white');
has 'canvas_tags' => (isa => 'HashRef', is => 'ro', default => sub { {} });

our $VERSION;
use version; $VERSION = qv('0.9.2');

# Preloaded methods go here.
my %_windowlist;

sub new_pattern
{
    my $this = shift;
    my %args = @_;

    my $pattern;

    if ( exists( $args{file} ) )
    {
        $this->window->Busy if ref($this);
        $pattern = Weaving::Tablet->new( file_name => $args{file} );
        $this->window->Unbusy if ref($this);
    }
    else
    {
        $this->window->Busy if ref($this);
        $pattern = Weaving::Tablet->new(
            number_of_cards => $args{cards},
            pattern_length  => $args{rows}
        );
        $this->window->Unbusy if ref($this);
    }
    return unless defined $pattern;

    delete $args{mw} unless defined $args{mw};
    my $win = new MainWindow;
    $_windowlist{MW} = $win unless exists $args{mw};
    $win->iconname('snartemo');
    $win->title( $args{file} || "Untitled" );

    # Make a new ME here!!
    my $self = $this->new( pattern => $pattern, 
        window => $win,
        canvas => $win->Scrolled(
            'Canvas',
            -background => 'white',
            -height     => 250,
            -width      => 200,
            )->pack(qw/-expand yes -fill both/),
        );

    $_windowlist{$win} = $win;

    $self->create_menu;

    $self->draw_pattern;
    return $self;
}

sub close_pattern
{
    my $self = shift;

    if ( $self->pattern->dirty )
    {
        my $button = $self->window->Dialog(
            -text           => "Save pattern?",
            -buttons        => [ 'Save', "Don't Save", 'Cancel' ],
            -default_button => 'Save',
        )->Show;
        return if $button eq 'Cancel';
        if ( $button eq 'Save' )
        {
            defined( $self->file_name )
              ? $self->save_pattern
              : $self->save_pattern_as;
        }
    }

    delete $_windowlist{ $self->window };
    $self->window->destroy;
}

sub create_menu
{
    my $self = shift;
    my $w    = $self->window;

    my $menuitems = [
        [
            Cascade    => '~File',
            -menuitems => [
                [
                    Button   => '~New...',
                    -command => sub { $self->make_new_from_scratch; }
                ],
                [
                    Button   => '~Open...',
                    -command => sub { $self->make_new_from_file; }
                ],
                [
                    Button   => 'Close',
                    -command => sub { $self->close_pattern; },
                ],
                [ Separator => '' ],
                [
                    Button   => '~Save',
                    -command => sub {
                        defined( $self->file_name )
                          ? $self->save_pattern
                          : $self->save_pattern_as;
                      }
                ],
                [
                    Button   => 'Save as...',
                    -command => sub { $self->save_pattern_as; }
                ],
                [ Separator => '' ],
                [
                    Button   => 'Generate Postscript...',
                    -command => sub { $self->print_pattern_as; }
                ],
                [ Separator => '' ],
                [
                    Button   => 'Reload',
                    -command => sub { $self->revert_pattern; }
                ],
                [
                    Button   => 'Quit',
                    -command => sub {
                        exit;
                      }
                ],
            ]
        ],
        [
            Cascade    => '~Edit',
            -menuitems => [
                [
                    Checkbutton => 'Smooth',
                    -variable   => \$self->{smooth},
                    -command    => sub {
                        $self->canvas->itemconfigure( 'turn',
                            -smooth => $self->smooth );
                      }
                ],
                [
                    Checkbutton => 'Grid',
                    -variable   => \$self->{draw_grid},
                    -command    => sub {
                        $self->canvas->itemconfigure( 'grid',
                            -outline => $self->draw_grid
                            ? 'black'
                            : undef );
                      }
                ],
                [
                    Checkbutton => 'Overlap',
                    -variable   => \$self->{overlap},
                    -command    => sub {
                        $self->update_pattern;
                      }
                ],
                [
                    Checkbutton => 'Outline',
                    -variable   => \$self->{outline},
                    -command    => sub {
                        $self->update_pattern;
                      }
                ],
                [ Separator => '' ],
                [
                    Button   => 'Outline Color',
                    -command => sub { $self->set_outline_color; }
                ],
                [
                    Button   => 'black outline',
                    -command => sub { $self->outline_color_black; }
                ],
                [ Separator => '' ],
                [
                    Button   => 'Background Color',
                    -command => sub { $self->bg_color; }
                ],
                [
                    Button   => 'white background',
                    -command => sub { $self->bg_color_white; }
                ],
                [
                    Button   => 'grey background',
                    -command => sub { $self->bg_color_gray; }
                ],
                [ Separator => '' ],
                [
                    Button   => 'Set float length...',
                    -command => sub { $self->set_float_length; }
                ],
                [
                    Checkbutton => 'Show Floats',
                    -variable   => \$self->{show_floats},
                    -command    => sub {
                        $self->pattern->float_pattern;
                        $self->update_pattern;
                      }
                ],
                [ Separator => '' ],
                [
                    Button   => 'Dump Pattern',
                    -command => sub { $self->dump; }
                ],
            ]
        ],
        [
            Cascade    => '~Pattern',
            -menuitems => [
                [
                    Button   => 'Insert row...',
                    -command => sub { $self->insert_row_cmd; }
                ],
                [
                    Button   => 'Delete row...',
                    -command => sub { $self->delete_row_cmd; }
                ],
                [
                    Button   => 'Copy row...',
                    -command => sub { $self->duplicate_row_cmd; }
                ],
                [ Separator => '' ],
                [
                    Button   => 'Insert card...',
                    -command => sub { $self->insert_card_cmd; }
                ],
                [
                    Button   => 'Delete card...',
                    -command => sub { $self->delete_card_cmd; }
                ],
                [
                    Button   => 'Copy card...',
                    -command => sub { $self->duplicate_card_cmd; }
                ],
                [ Separator => '' ],
                [
                    Button   => 'Edit colors',
                    -command => sub { $self->edit_palette; }
                ],
                [
                    Button   => 'Edit threading',
                    -command => sub { $self->edit_threading; }
                ],
                [
                    Button   => 'Show Twist',
                    -command => sub { $self->show_twist; }
                ],
            ]
        ]
    ];

    if ( $Tk::VERSION >= 800 )
    {
        my $menubar = $w->Menu( -menuitems => $menuitems );
        $w->configure( -menu => $menubar );
    }
    else
    {
        $w->Menubutton(
            -text      => 'Pseudo menubar',
            -menuitems => $menuitems,
        )->pack;
    }
}

sub file_name
{
    my $self = shift;
    return $self->pattern->file_name;
}

sub dump
{
    my $self = shift;
    print $self->pattern->dump_pattern;
    foreach my $k ( sort keys %$self )
    {
        next unless ref( $self->{$k} );
        print "self->$k is $self->{$k}\n";
    }
}

sub show_twist
{
    my $self  = shift;
    my $twist = $self->pattern->print_twist;
    print $twist;
}

sub set_outline_color
{
    my $self     = shift;
    my $bg_color = $self->color_dlog->Show(
        -title        => 'Outline Color',
        -initialcolor => $self->outline_color
    );
    return unless defined $bg_color;
    $self->outline_color($bg_color);
    $self->outline(1);
    $self->canvas->itemconfigure( 'turn',  -outline => $self->outline_color );
}

sub outline_color_black
{
    my $self = shift;
    $self->outline_color('black');
    $self->outline(1);
    $self->canvas->itemconfigure( 'turn',  -outline => $self->outline_color );
}

sub bg_color
{
    my $self     = shift;
    my $bg_color = $self->color_dlog->Show(
        -title        => 'Background Color',
        -initialcolor => $self->background_color
    );
    return unless defined $bg_color;
    $self->background_color($bg_color);
    $self->canvas->configure( -background => $self->background_color );
}

sub bg_color_white
{
    my $self = shift;
    $self->background_color('white');
    $self->canvas->configure( -background => $self->background_color );
}

sub bg_color_gray
{
    my $self = shift;
    $self->background_color('gray');
    $self->canvas->configure( -background => $self->background_color );
}

sub set_float_length
{
    my $self         = shift;
    my $float_length = $self->float_length_dlog( $self->float_length );
    return unless defined $float_length;
    $self->float_length($float_length);
    $self->update_pattern if $self->show_floats;
}

sub set_current_row
{
    my $self   = shift;
    my $canvas = $self->canvas;
    my $r      = shift;

    do
    {
        foreach my $t ( $self->gettags('current') )
        {
            $r = unpack( 'x3a*', $t ) if $t =~ /^row\d+$/;
        }
    } unless defined $r;
    return unless defined $r;
    $r %= $self->pattern->number_of_rows;
    $canvas->move( 'currentrow', 0,
        ( $self->current_row - $r ) * $self->row_spacing );
    $self->current_row($r);
}

sub set_current_card
{
    my $self   = shift;
    my $canvas = $self->canvas;
    my $c      = shift;

    do
    {
        foreach my $t ( $self->gettags('current') )
        {
            $c = unpack( 'x4a*', $t ) if $t =~ /^card\d+$/;
        }
    } unless defined $c;
    return unless defined $c;
    $c %= $self->pattern->number_of_cards;
    $canvas->move( 'currentcard',
        ( $c - $self->current_card ) * $self->col_spacing, 0 );
    $self->current_card($c);
}

sub draw_pattern
{
    shift->_draw_pattern( @_, 'draw' );
}

sub update_pattern
{
    my $pattern  = shift;
    my @cardlist = @_;
    @cardlist or @cardlist = ( 0 .. $pattern->pattern->number_of_cards - 1 );
    $pattern->pattern->float_pattern(@cardlist) if $pattern->show_floats;
    $pattern->_draw_pattern( 'update', @cardlist );
}

sub create
{
    my $self = shift;
    my $type = shift;
    my @args;
    while (@_)
    {
        last if $_[0] =~ /^-[a-z]/;
        push @args, shift;
    }
    my %args = @_;
    my $canvas = $self->canvas;
    my $tags = $args{-tags};
    delete $args{-tags};
    my $id = $canvas->create($type, @args, %args);
    my $idtag = "id$id";
    $canvas->addtag($idtag, 'withtag', $id);
    for my $addtag (qw/turn grid SZ start rownumber/)
    {
        for my $tag (@$tags)
        {
            next unless $tag eq $addtag;
            $canvas->addtag($tag, 'withtag', $id);
            last;
        }
    }
    for my $tag ($idtag, @$tags)
    {
        push @{$self->canvas_tags->{$tag}}, $id;
        push @{$self->canvas_tags->{$idtag}}, $tag;
    }
}

sub delete
{
    my $self = shift;
    my @tags = @_;
    my $canvas = $self->canvas;
    for my $tag (@tags)
    {
        next unless exists $self->canvas_tags->{$tag};
        $canvas->delete(@{$self->canvas_tags->{$tag}});
    }
}

sub itemconfigure
{
    my $self = shift;
    my ($tag, %args) = @_;
    my $canvas = $self->canvas;
    return unless exists $self->canvas_tags->{$tag};
    for my $id (@{$self->canvas_tags->{$tag}})
    {
        $canvas->itemconfigure($id, %args);
    }
}

sub _draw_pattern
{
    my $self  = shift;
    my ($action, @cardlist) = @_;
    my $pattern = $self->pattern;
    my $canvas   = $self->canvas;
    @cardlist or @cardlist = ( 0 .. $pattern->number_of_cards - 1 );

    {
        my @cardlist = map { ref($_) ? $_->[0] : $_; } @cardlist;
        $pattern->twist_pattern(@cardlist);
        $pattern->color_pattern(@cardlist);
    }

    my ( $c8, $r8, $offset, $rs );
    do
    {
        $self->delete('rownumber');
        foreach my $row ( 0 .. $pattern->number_of_rows - 1 )
        {
            $r8 = ( -$row ) * $self->row_spacing - 8;
            $self->create(
                'text',
                38, $r8,
                -text   => $row + 1,
                -font   => $self->small_font,
                -anchor => 'e',
                -tags   => [ 'rownumber', "row$row", "rownumber$row" ],
            );
        }
    } if $action eq 'draw';
    $rs = $self->row_spacing;
    my $poly_ht = $self->overlap ? $rs : $rs / 2;
    my $half_col_size = $self->half_col_size;
    foreach my $card (@cardlist)
    {
        my $startrow = 0;
        ( $card, $startrow ) = @$card if ref($card);
        $self->window->update;
        $c8 = $card * $self->col_spacing + 8 + 48;
        foreach my $row ( $startrow .. $pattern->number_of_rows - 1 )
        {
#            $self->_draw_pick($card, $row);
            $r8 = ( -$row ) * $rs - 8;
            $offset =
              ( index( '\|/', $pattern->card_turns($card)->[$row] ) - 1 ) *
              $half_col_size;
            $offset *= $pattern->cards->[$card]->SZ eq 'S' ? 1 : -1;
            $self->delete( "turn$card" . "x$row" );
            $self->create(
                'polygon',
                _poly_coords( $self, $r8, $c8, $offset, $poly_ht ),
                -fill => $pattern->color_table->[
                    $pattern->threading(
                        $card, $pattern->color( $card, $row )
                    )],
                -outline => $self->outline ? $self->outline_color : undef,
                -width => 0.5,
                -tags =>
                  [ 'turn', "row$row", "card$card", "turn$card" . "x$row" ],
            );
            $self->delete( "grid$card" . "x$row" );
            $self->create(
                'rectangle',
                $c8 - $half_col_size - 1, $r8 + $rs / 2,
                $c8 + $half_col_size,     $r8 - $rs / 2,
                -fill    => undef,
                -outline => $self->draw_grid ? 'black' : undef,
                -tags =>
                  [ 'grid', "row$row", "card$card", "grid$card" . "x$row" ],
            );
        }
        $self->delete("float$card");
        if ( $self->show_floats )
        {
            foreach my $float ( @{ $pattern->{floats}[$card] } ) ##FIXME
            {

                # add check against float_length here...
                next
                  unless ( $float->[1] - $float->[0] ) + 1 >=
                  $self->float_length;
                $self->create(
                    'rectangle',
                    $c8 - $half_col_size - 1,
                    ( -$float->[0] ) * $rs - 8 + $rs / 2,
                    $c8 + $half_col_size,
                    ( -$float->[1] ) * $rs - 8 - $rs / 2,
                    -fill    => undef,
                    -width   => 2,
                    -outline => 'black',
                    -tags    => [ 'float', "card$card", "float$card" ],
                );
            }
        }

        if ( $action eq 'draw' )
        {
            $self->delete("SZ$card");
            $self->create(
                'text',
                $c8, 24,
                -anchor => 'center',
                -text   => $pattern->SZ($card),
                -tags   => [ 'SZ', "card$card", "SZ$card" ]
            );
            $self->delete("starthole$card");
            $self->create(
                'text',
                $c8, 36,
                -anchor => 'center',
                -text   => chr( ord('A') + $pattern->start($card) ),
                -tags =>
                  [ 'starthole', 'start', "card$card", "starthole$card" ],
            );
            foreach my $hole ( 0 .. 3 )
            {
                $self->delete( "start$card" . "hole$hole" );
                $self->create(
                    'rectangle',
                    $c8 - 3,
                    42 + 12 * $hole,
                    $c8 + 3,
                    52 + 12 * $hole,
                    -fill => $pattern->color_table->[
                        $pattern->threading( $card, $hole )
                    ],
                    -tags =>
                      [ 'start', "card$card", "start$card" . "hole$hole" ],
                );
            }
        }
        elsif ( $action eq 'update' )
        {
            $self->itemconfigure( "SZ$card", -text => $pattern->SZ($card) );
            $self->itemconfigure( "starthole$card",
                -text => chr( ord('A') + $pattern->start($card) ) );
            foreach my $hole ( 0 .. 3 )
            {
                $self->itemconfigure(
                    "start$card" . "hole$hole",
                    -fill => $pattern->color_table->[
                        $pattern->threading( $card, $hole )
                    ]
                );
            }
        }
    }

    if ( $action eq 'draw' )
    {
        $self->delete('holelabel');
        foreach my $hole ( 0 .. 3 )
        {
            $self->create(
                'text',
                46, 47 + 12 * $hole,
                -text => chr( ord('A') + $hole ),
                -tags => [ 'holelabel', "holelabel$hole" ],
            );
        }
    }

    do
    {
        $canvas->delete('currentrow');
        $canvas->delete('currentcard');
        $canvas->create(
            'rectangle',
            40, -$self->current_row * $self->row_spacing - 10,
            50, -$self->current_row * $self->row_spacing - 6,
            -fill => 'black',
            -tags => ['currentrow'],
        );
        $canvas->create(
            'rectangle',
            $self->current_card * $self->col_spacing + 8 + 48 - 2, 4,
            $self->current_card * $self->col_spacing + 8 + 48 + 2, 16,
            -fill => 'black',
            -tags => ['currentcard'],
        );

        $canvas->bind( 'turn', '<1>',       sub { $self->flip_turn; } );
        $canvas->bind( 'grid', '<1>',       sub { $self->flip_turn; } );
        $canvas->bind( 'turn', '<Shift-1>', sub { $self->null_turn; } );
        $canvas->bind( 'grid', '<Shift-1>', sub { $self->null_turn; } );
        $canvas->bind( 'SZ',   '<1>',       sub { $self->flip_card; } );
        $canvas->bind( 'start', '<1>', sub { $self->rotate_start(1); } );
        $canvas->bind( 'start', '<Shift-1>',
            sub { $self->rotate_start(-1); } );
        $canvas->bind( 'start', '<2>', sub { $self->edit_threading; } );
        $canvas->bind( 'start', '<3>', sub { $self->set_current_card; } );
        $canvas->bind( 'rownumber', '<1>', sub { $self->set_current_row; } );
        $canvas->CanvasBind( '<Delete>', sub { $self->delete_cmd; } );
        $canvas->CanvasBind( '<Insert>', sub { $self->insert_cmd; } );
    } if $action eq 'draw';

    $canvas->configure( -scrollregion => [ $canvas->bbox("all") ] );
}

sub _draw_pick
{
    my $self = shift;
    my ($card, $row) = @_;
    my $pattern = $self->pattern;
    my $canvas = $self->canvas;
    my $rs = $self->row_spacing;
    my $r8 = ( -$row ) * $rs - 8;
    my $c8 = $card * $self->col_spacing + 8 + 48;
    my $poly_ht = $self->overlap ? $rs : $rs / 2;
    my $half_col_size = $self->half_col_size;
    if (!$self->gettags("turn${card}x${row}"))
    {
        for my $pick (-1 .. 1)
        {
            my $offset = $pick * $half_col_size * ($pattern->cards->[$card]->SZ eq 'S' ? 1 : -1);
            my $turn_tag = (qw/null fwd back/)[$pick];
            $self->create(
        'polygon',
        _poly_coords( $self, $r8, $c8, $offset, $poly_ht ),
        -fill => $pattern->color_table->[
            $pattern->threading($card, $pattern->color( $card, $row ))],
        -state => 'hidden',
        -tags =>
          [ 'turn', "row$row", "card$card", "turn$card" . "x$row" , "turn${card}x${row}$turn_tag"],
    );
        }
        $self->create(
            'rectangle',
            $c8 - $half_col_size - 1, $r8 + $rs / 2,
            $c8 + $half_col_size,     $r8 - $rs / 2,
            -fill    => undef,
            -outline => $self->draw_grid ? 'black' : undef,
            -tags =>
              [ 'grid', "row$row", "card$card", "grid$card" . "x$row" ],
        );
    }
    my $pick = index( '\|/', $pattern->card_turns($card)->[$row] ) - 1;
    $pick *= ($pattern->cards->[$card]->SZ eq 'S' ? 1 : -1);
    my $turn_tag = (qw/null fwd back/)[$pick];
    $self->itemconfigure("turn${card}x${row}fwd", -state => 'hidden');
    $self->itemconfigure("turn${card}x${row}back", -state => 'hidden');
    $self->itemconfigure("turn${card}x${row}null", -state => 'hidden');
    $self->itemconfigure("turn${card}x${row}$turn_tag", 
        -state => 'normal',
        -fill => $pattern->color_table->[
            $pattern->threading($card, $pattern->color( $card, $row ))],);
}

sub _poly_coords
{
    my $pattern = shift;
    my ( $r8, $c8, $offset, $poly_ht ) = @_;
    if ( $offset != 0 )
    {
        return $pattern->overlap
          ? (
            $c8 - $offset,
            $r8 + $poly_ht - 1,
            $c8 - $offset,
            $r8,
            $c8 + $offset,
            $r8 - $poly_ht + 1,
            $c8 + $offset,
            $r8,
            $c8 - $offset,
            $r8 + $poly_ht - 1,
            -smooth => $pattern->smooth,
          )
          : (
            $c8 - $offset,
            $r8 + $poly_ht - 1,
            $c8 - $offset,
            $r8 + $poly_ht / 2,
            $c8 + $offset / 2,
            $r8 - $poly_ht + 1,
            $c8 + $offset,
            $r8 - $poly_ht + 1,
            $c8 + $offset,
            $r8 - $poly_ht / 2,
            $c8 - $offset / 2,
            $r8 + $poly_ht - 1,
            $c8 - $offset,
            $r8 + $poly_ht - 1,
            -smooth => $pattern->smooth,
          );
    }
    else
    {
        my $offset = $pattern->half_col_size / 2;
        return (
            $c8 - $offset,
            $r8 + $poly_ht - 1,
            $c8 - $offset,
            $r8 - $poly_ht + 1,
            $c8 + $offset,
            $r8 - $poly_ht + 1,
            $c8 + $offset,
            $r8 + $poly_ht + 1,
            $c8 - $offset,
            $r8 + $poly_ht - 1,
            -smooth => $pattern->smooth,
        );
    }
}

sub delete_cmd
{
    my $self = shift;

    my $action = $self->delete_dlog->Show;

    $action eq 'Row'  and $self->delete_row_cmd;
    $action eq 'Card' and $self->delete_card_cmd;
}

sub insert_cmd
{
    my $self = shift;

    my $action = $self->insert_dlog->Show;

    $action eq 'Row'  and $self->insert_row_cmd;
    $action eq 'Card' and $self->insert_card_cmd;
}

sub make_new_from_scratch
{
    my $self = shift;

    my $d = $self->window->DialogBox(
        -title          => "New pattern...",
        -buttons        => [qw/OK Cancel/],
        -default_button => 'OK'
    );

    my ( $cards, $rows ) = ( 10, 10 );
    my $msg = '';

    $d->add(
        'LabEntry',
        -label        => 'Number of Cards',
        -labelPack    => [qw/-side left -anchor w/],
        -textvariable => \$cards,
    )->pack(qw/-side top -anchor w/);
    $d->add(
        'LabEntry',
        -label        => 'Number of turns',
        -labelPack    => [qw/-side left -anchor w/],
        -textvariable => \$rows,
    )->pack(qw/-side top -anchor w/);
    $d->add(
        'Label',
        -textvariable => \$msg,
        -width        => 50,
        -height       => 2,
        -justify      => 'left',
    )->pack(qw/-side left -anchor w/);

  LOOP:
    {
        return if $d->Show eq 'Cancel';
        $msg = '';
        $msg = 'Number of Cards must be > 0' unless $cards > 0;
        $msg = 'Number of turns must be > 0' unless $rows > 0;
        redo LOOP unless $msg eq '';
    }
    return
      if $self->new_pattern(
        mw    => $self->window,
        cards => $cards,
        rows  => $rows
      );
    $self->window->Dialog( -text => 'Could not create new pattern' )->Show;
    return;
}

sub revert_pattern
{
    my $self = shift;

    return unless defined $self->pattern->file_name;
    return unless -r $self->pattern->file_name;

    return
      if $self->window->Dialog(
        -text           => "Revert to saved version (discard changes)?",
        -buttons        => [qw/OK Cancel/],
        -default_button => 'OK'
      ) eq 'Cancel';
    
    my $new_pattern = $self->pattern->new(file_name => $self->pattern->file_name);
    my $old_canvas = $self->canvas;
    my $new_canvas =  $self->window->Scrolled(
            'Canvas',
            -background => 'white',
            -height     => $old_canvas->height,
            -width      => $old_canvas->width,
            )->pack(qw/-expand yes -fill both/),
    $old_canvas->packForget;
    $old_canvas->destroy;
    $self->_set_canvas($new_canvas);
    $new_pattern->load_pattern;
    $self->draw_pattern;
}

sub make_new_from_file
{
    my $self = shift;
    my $fs =
      $self->fs_dlog( { -filelabel => 'Load pattern from...', -create => 0 } );
    my $file = $fs->Show;
    return if $file eq '';
    return if $self->new_pattern( mw => $self->window, file => $file );
    $self->window->Dialog( -text => "Could not load file $file" )->Show;
    return;
}

sub save_pattern
{
    my $self = shift;
    open my $pat, '>', $self->pattern->file_name or return;
    print $pat $self->pattern->dump_pattern;
    close $pat;
    return 1;
}

sub save_pattern_as
{
    my $self = shift;
    my $fs =
      $self->fs_dlog( { -filelabel => 'Save pattern as...', -create => 1 } );
    my $file = $fs->Show;
    return if ! defined $file;
    return if $file eq '';
    $self->pattern->file_name($file);
    return if $self->save_pattern;
    $self->window->Dialog( -text => "Could not save file as $file" )->Show;
    return;
}

sub print_pattern_as
{
    my $self = shift;
    my $fs =
      $self->fs_dlog( { -filelabel => 'Save postscript as...', -create => 1 } );
    my $file = $fs->Show;
    return if ! defined $file;
    return if $file eq '';
    my @bbox = $self->canvas->bbox('all');
    my $width = $bbox[2]-$bbox[0];
    my $height = $bbox[3]-$bbox[1];
    my $pagewidth = $width/90 . 'i';
    my $height_per_page = $height > 850 ? 800 : 850;
    my $page_overlap = $height > 850 ? 50 : 0;
    if ($width > 720)
    {
        $pagewidth = '8i';
        $height_per_page *= $width/720;
        $height_per_page = int($height_per_page);
    }
    my $pages = int($height/$height_per_page)+1;
    # now 
    my $page = 1;
    my $y = $bbox[3] - ($height_per_page + $page_overlap);
    while ($page <= $pages)
    {
        my $y = $bbox[3] - ($height_per_page*$page + $page_overlap);
        $y = $bbox[1] if $y < $bbox[1];
        use autodie;
        my $psfile = _add_page_to_file_name($file, $page);
        print "Printing page $page to $psfile\n";
        $self->canvas->postscript(
            -file => $psfile,
            -colormode => 'color',
            -x => $bbox[0],
            -y => $y,
            -width => $width,
            -height => $height_per_page + $page_overlap,
            -pagewidth => $pagewidth,
            );
        $page++;
    }
    return;
}

sub _add_page_to_file_name
{
    my ($path, $number) = @_;
    my ($volume, $directories, $file) = File::Spec->splitpath( $path );
    my($filename, undef, $suffix) = fileparse($file, qr/\.[^.]*/);
    $filename .= $number;
    return catfile($volume, $directories, $filename.$suffix) if $volume;
    return catfile($directories, $filename.$suffix);
}

sub insert_row_cmd
{
    my $self = shift;
    my $dlog = $self->insert_row_dlog;
    $dlog->{where_row} = $self->current_row + 1;
    $dlog->{dlog}->deiconify;
    $dlog->{dlog}->raise;
}

sub delete_row_cmd
{
    my $self = shift;
    my $dlog = $self->delete_row_dlog;
    $dlog->{where_row} = $self->current_row + 1;
    $dlog->{dlog}->deiconify;
    $dlog->{dlog}->raise;
}

sub duplicate_row_cmd
{
    my $self = shift;
    my $dlog = $self->duplicate_row_dlog;
    $dlog->{from_row}  = $self->current_row + 1;
    $dlog->{after_row} = $self->current_row + 1;
    $dlog->{dlog}->deiconify;
    $dlog->{dlog}->raise;
}

sub insert_card_cmd
{
    my $self = shift;
    my $dlog = $self->insert_card_dlog;
    $dlog->{where_card} = $self->current_card + 1;
    $self->refresh_color_list( $dlog->{palette} );
    $self->refresh_card_threading( $dlog->{card_canvas} );
    $dlog->{threading} = [ $self->threading( $self->current_card ) ];
    $dlog->{turns}->delete( '1.0', 'end' );
    $dlog->{turns}->insert( '1.0',
        join( "", reverse $self->card_turns( $self->current_card ) ) );
    $dlog->{dlog}->deiconify;
    $dlog->{dlog}->raise;
}

sub delete_card_cmd
{
    my $self = shift;
    my $dlog = $self->delete_card_dlog;
    $dlog->{where_card} = $self->current_card + 1;
    $dlog->{dlog}->deiconify;
    $dlog->{dlog}->raise;
}

sub duplicate_card_cmd
{
    my $self = shift;
    my $dlog = $self->duplicate_card_dlog;
    $dlog->{from_card}  = $self->current_card + 1;
    $dlog->{after_card} = $self->current_card + 1;
    $dlog->{dlog}->deiconify;
    $dlog->{dlog}->raise;
}

sub edit_palette
{
    my $pattern = shift;
    my $canvas  = $pattern->canvas;
    my $palette = $pattern->palette_dlog;
    $pattern->refresh_color_list( $palette->{h} );
    $palette->{dlog}->deiconify;
    $palette->{dlog}->raise;
}

sub get_new_color
{
    my $pattern = shift;
    my $h       = shift;

    my $title = "Select new color to add to palette";
    my $color = $pattern->color_dlog->Show( -title => $title, -parent => $h );
    return unless defined $color;
    $pattern->color_table( undef, $color );
    my $c = @{ $pattern->{color_table} } - 1;
    $h->add( $c, -text => $c );
    $h->itemCreate( $c, 1, -text => $color );
}

sub refresh_color_list
{
    my $self = shift;
    my $h    = shift;
    $h->delete('all');
    foreach my $c ( 0 .. @{$self->pattern->color_table} - 1 )
    {
        $h->add( $c, -text => $c );
        $h->itemCreate( $c, 1, -text => $self->pattern->color_table->[$c] );
    }
}

sub refresh_card_threading
{
    my $self     = shift;
    my $pattern = $self->pattern;
    my $card_canvas = shift;
    my $threading   = shift
      || $pattern->threading( $self->current_card );

    foreach my $h ( 0 .. 3 )
    {
        $card_canvas->itemconfigure( "hole$h",
            -fill => $pattern->color_table->[$threading->[$h]], );
    }
}

sub edit_threading
{
    my $self = shift;
    my $pattern = $self->pattern;
    my $canvas  = $self->canvas;
    $self->set_current_card;
    $self->current_card(0) unless $self->current_card;

    my $list        = $self->threading_dlog->{h};
    my $t           = $self->threading_dlog->{dlog};
    my $card_canvas = $self->threading_dlog->{card_canvas};

    $self->threading_dlog->{start} =
      $pattern->start( $self->current_card );
    $self->refresh_color_list($list);
    $self->refresh_card_threading($card_canvas);
    $t->deiconify;
    $t->raise;
}

sub gettags
{
    my $self = shift;
    my $tag = shift;
    if ($tag eq 'current')
    {
        for my $tag ($self->canvas->gettags('current'))
        {
            next unless $tag =~ /^id\d+/;
            return @{$self->canvas_tags->{$tag}};
        }
        return;
    }
}
sub flip_turn
{
    my $pattern = shift;
    my $canvas  = $pattern->canvas;

    my ( $r, $c );
    foreach my $t ( $pattern->gettags('current') )
    {
        $r = unpack( 'x3a*', $t ) if $t =~ /^row\d+$/;
        $c = unpack( 'x4a*', $t ) if $t =~ /^card\d+$/;
    }
    return unless defined $r;
    return unless defined $c;

    $pattern->pattern->turns( $c, $r, $pattern->pattern->turns( $c, $r ) eq '/' ? '\\' : '/' );
    $pattern->set_current_row($r);
    $pattern->set_current_card($c);
    $pattern->update_pattern( [ $c, $r ] );
}

sub null_turn
{
    my $pattern = shift;
    my $canvas  = $pattern->canvas;

    my ( $r, $c );
    foreach my $t ( $pattern->gettags('current') )
    {
        $r = unpack( 'x3a*', $t ) if $t =~ /^row\d+$/;
        $c = unpack( 'x4a*', $t ) if $t =~ /^card\d+$/;
    }
    return unless defined $r;
    return unless defined $c;

    $pattern->pattern->turns( $c, $r, '|' );
    $pattern->set_current_row($r);
    $pattern->set_current_card($c);
    $pattern->update_pattern( [ $c, $r ] );
}

sub flip_card
{
    my $pattern = shift;
    my $canvas  = $pattern->canvas;

    my $c;
    foreach my $t ( $pattern->gettags('current') )
    {
        $c = unpack( 'x4a*', $t ) if $t =~ /^card\d+$/;
    }
    return unless defined $c;
    $pattern->pattern->SZ($c, $pattern->pattern->SZ($c) eq 'S' ? 'Z' : 'S');
    $pattern->set_current_card($c);
    $pattern->update_pattern($c);
}

sub rotate_start
{
    my $pattern = shift;
    my $dir     = shift || 1;
    my $canvas  = $pattern->canvas;

    my $c;
    foreach my $t ( $pattern->gettags('current') )
    {
        $c = unpack( 'x4a*', $t ) if $t =~ /^card\d+$/;
    }
    return unless defined $c;

    $pattern->pattern->start( $c, ( $pattern->pattern->start($c) + $dir ) % 4 );
    $pattern->set_current_card($c);
    $pattern->update_pattern($c);
}

sub palette_dlog
{
    my $self = shift;
    unless ( defined $self->{_palette_dlog} )
    {
        my $palette = $self->window->Toplevel;
        $palette->title('Pattern palette editor');
        $palette->Button(
            -text    => 'Close',
            -command => [ withdraw => $palette ],
        )->pack(qw/-side bottom/);
        my $h =
          $self->_palette(
            $palette->Frame->pack(qw/-side top -fill both -expand y/) );

        $self->{_palette_dlog} = { dlog => $palette, h => $h };
    }
    $self->{_palette_dlog};
}

sub _palette    # (frame, card_canvas, \current_hole, \threading, update)

  # frame only required
{
    my $self         = shift;
    my $palette      = shift;
    my $card_canvas  = shift;
    my $current_hole = shift;
    my $threading    = shift;
    my $update       = shift || 0;

    my $h = $palette->Scrolled(
        'HList',
        -width      => 40,
        -height     => 10,
        -header     => 1,
        -drawbranch => 0,
        -columns    => 2,
        -scrollbars => 'osoe',
    )->pack(qw/-side top -fill both -expand y/);
    $palette->Button(
        -text    => 'Add from picker',
        -command => sub {
            my $title = "Select new color to add to palette";
            my $color = $self->color_dlog->Show( -title => $title );
            return unless defined $color;
            $self->pattern->color_table( undef, $color );
            $self->refresh_color_list($h);
        },
    )->pack(qw/-side top/);
    $palette->Button(
        -text    => 'Add name',
        -command => sub {
            my $d = $palette->DialogBox(
                -title          => 'Add Color by Name',
                -buttons        => [qw/OK Cancel/],
                -default_button => 'OK',
            );
            my $cname;
            $d->add(
                'LabEntry',
                -label        => 'Color',
                -labelPack    => [qw/-side left/],
                -width        => 30,
                -textvariable => \$cname,
            )->pack;
            return if $d->Show eq 'Cancel';
            return if $cname   eq '';
            $self->pattern->color_table( undef, $cname );
            $self->refresh_color_list($h);
        },
    )->pack(qw/-side top/);

    $h->header( create => 0, -text => 'Number' );
    $h->header( create => 1, -text => 'Color' );
    $h->columnWidth( 0, -char => 7 );
    $h->columnWidth( 1, -char => 33 );

    $h->configure(
        -command => sub {
            my $s     = shift;
            my $title = "Old color $s (" . $self->color_table($s) . ")";
            my $color = $self->color_dlog->Show(
                -title        => $title,
                -initialcolor => $self->color_table($s),
            );
            return unless defined $color;
            $self->pattern->color_table( $s, $color );
            $h->itemConfigure( $s, 1, -text => $color );
            $self->update_pattern;
            $self->refresh_card_threading($card_canvas) if $update;
        },
    );
    $h->configure(
        -browsecmd => sub {
            $self->pattern->threading( $self->current_card, $$current_hole, shift );
            $card_canvas->itemconfigure(
                "hole$$current_hole",
                -fill => $self->pattern->color_table->[
                    $self->pattern->threading( $self->current_card, $$current_hole)],
            );
            $card_canvas->update;
            $self->pattern->color_pattern( $self->current_card );
            $self->update_pattern( $self->current_card );
        },
    ) if $update eq 'old';
    $h->configure(
        -browsecmd => sub {
            $$threading[$$current_hole] = shift;
            $card_canvas->itemconfigure( "hole$$current_hole",
                -fill => $self->pattern->color_table( $$threading[$$current_hole] ) );

        },
    ) if $update eq 'new';
    $h->bind(
        "<3>",
        sub {
            my $w = shift;
            my $d = $h->DialogBox(
                -title          => "Edit Color Name",
                -buttons        => [qw/OK Cancel/],
                -default_button => 'OK',
            );
            my $old;
            my $new;
            $d->add(
                'LabEntry',
                -textvariable => \$old,
                -label        => 'Old name',
                -labelPack    => [qw/-side left -anchor w/],
                -state        => 'disabled',
                -width        => 30,
            )->pack(qw/-side top -anchor w/);
            $d->add(
                'LabEntry',
                -textvariable => \$new,
                -label        => 'New name',
                -labelPack    => [qw/-side left -anchor w/],
                -width        => 30,
            )->pack(qw/-side top -anchor w/);
            my $y = $w->XEvent->y;
            my $s = $h->nearest($y);
            $old = $new = $self->color_table($s);
            return if $d->Show eq 'Cancel';
            print "change $old ($s at $y) to $new\n";
            return if $old eq $new;
            return if $new eq '';
            $self->pattern->color_table( $s, $new );
            $h->itemConfigure( $s, 1, -text => $new );
            $self->update_pattern;
            $self->refresh_card_threading($card_canvas) if $update;
        }
    );
    $h;
}

sub threading_dlog
{
    my $self = shift;
    unless ( defined $self->{_threading_dlog} )
    {
        my $t_info = {
            current_hole => 0,
            start        => 0
        };

        my $t = $self->window->Toplevel;
        $t->title('Edit card threading');
        $t->Button(
            -text    => 'Close',
            -command => [ withdraw => $t ],
        )->pack(qw/-side bottom/);
        my $f1 = $t->Frame->pack(qw/-side left/);
        $f1->Label( -textvariable => \$self->{current_card} )
          ->pack(qw/-side top/);
        my $f2 =
          $t->Frame( -label => "Palette", )
          ->pack(qw/-side right -expand y -fill both/);
        my $card_canvas = $self->_card_canvas( $f1, \$t_info->{current_hole},
            \$t_info->{start}, 1, )->pack(qw/-side top/);

        # put up the palette
        my $h = $self->_palette( $f2, $card_canvas, \$t_info->{current_hole},
            undef, 'old' );

        $f1->Button(
            -text    => 'Prev',
            -command => sub {
                $self->set_current_card( $self->current_card - 1 );
                $t_info->{start} = $self->pattern->start( $self->current_card );
                $self->refresh_card_threading($card_canvas);
            },
        )->pack(qw/-side left/);
        $f1->Button(
            -text    => 'Next',
            -command => sub {
                $self->set_current_card( $self->current_card + 1 );
                $t_info->{start} = $self->pattern->start( $self->current_card );
                $self->refresh_card_threading($card_canvas);
            },
        )->pack(qw/-side right/);
        $t_info->{dlog}          = $t;
        $t_info->{h}             = $h;
        $t_info->{card_canvas}   = $card_canvas;
        $self->{_threading_dlog} = $t_info;
    }
    $self->{_threading_dlog};
}

sub fs_dlog
{
    my $self    = shift;
    my $configs = shift;
    unless ( defined $self->{_fs_dlog} )
    {
        $self->{_fs_dlog} = $self->window->FileSelect;
    }
    $self->{_fs_dlog}->configure(%$configs);
    $self->{_fs_dlog};
}

sub color_dlog
{
    my $self = shift;
    unless ( defined $self->{_color_dlog} )
    {
        $self->{_color_dlog} = $self->window->ColorDialog;
    }
    $self->{_color_dlog};
}

sub font_dlog
{
    my $self = shift;
    unless ( defined $self->{_font_dlog} )
    {
        $self->{_font_dlog} = $self->window->FontDialog(
            -nicefont  => 0,
            -fixedfont => 1,
        );
    }
    $self->{_font_dlog};
}

sub insert_row_dlog
{
    my $self = shift;
    unless ( defined $self->{_insert_row_dlog} )
    {
        my $d_info = {
            dlog      => undef,
            where     => 'current',
            where_row => undef,
            turns     => undef,
        };
        my $d = $self->window->Toplevel;
        $d->title('Insert Row of Turns');
        $d->Radiobutton(
            -text     => 'Beginning (bottom)',
            -variable => \$d_info->{where},
            -value    => 'bottom',
        )->pack(qw/-side top -anchor w/);
        my $f1 = $d->Frame->pack(qw/-side top -anchor w/);
        $f1->Radiobutton(
            -text     => 'After row',
            -variable => \$d_info->{where},
            -value    => 'current',
        )->pack(qw/-side left/);
        $f1->Entry(
            -textvariable => \$d_info->{where_row},
            -width        => 10,
        )->pack(qw/-side left/);
        $d->Radiobutton(
            -text     => 'End (top)',
            -variable => \$d_info->{where},
            -value    => 'end',
        )->pack(qw/-side top -anchor w/);

        my $f2 = $d->Frame->pack(qw/-side top -anchor w/);
        $f2->Label( -text => 'Turns', )->pack(qw/-side left -anchor n/);
        $f2->Scrolled(
            'Entry',
            -scrollbars   => 's',
            -width        => 50,
            -textvariable => \$d_info->{turns},
        )->pack(qw/-side left -anchor n/);

        $d->Button(
            -text    => 'Done',
            -command => sub {
                my $after_row =
                    $d_info->{where} eq 'bottom'  ? 0
                  : $d_info->{where} eq 'current' ? $d_info->{where_row}
                  :                                 $self->pattern->number_of_rows;
                if ( $d_info->{where} eq 'current'
                    and ( $after_row < 0 or $after_row > $self->pattern->number_of_rows )
                  )
                {
                    $d->Dialog( -text =>
                          'After must be between 0 and the number of turns' )
                      ->Show;
                    return;
                }
                my @turns = split( //, $d_info->{turns} );
                if ( grep !/^[\/\\|]$/, @turns )
                {
                    $d->Dialog( -text => 'Turns may only be /, | or \\' )->Show;
                    return;
                }
                print "insert_row(", $after_row, ", '",
                  $d_info->{turns} || '', "')\n";
                $self->pattern->insert_pick( [$after_row-1, $d_info->{turns} || ''] );
                $self->draw_pattern;
                $d->withdraw;
            },
        )->pack(qw/-side left/);
        $d->Button(
            -text    => 'Stay',
            -command => sub {
                my $after_row =
                    $d_info->{where} eq 'bottom'  ? 0
                  : $d_info->{where} eq 'current' ? $d_info->{where_row}
                  :                                 $self->pattern->number_of_rows;
                if ( $d_info->{where} eq 'current'
                    and ( $after_row < 0 or $after_row > $self->pattern->number_of_rows )
                  )
                {
                    $d->Dialog( -text =>
                          'After must be between 0 and the number of turns' )
                      ->Show;
                    return;
                }
                my @turns = split( //, $d_info->{turns} );
                if ( grep !/^[\/\\|]$/, @turns )
                {
                    $d->Dialog( -text => 'Turns may only be /, | or \\' )->Show;
                    return;
                }
                print "insert_row(", $after_row, ", '",
                  $d_info->{turns} || '', "')\n";
                $self->pattern->insert_pick( [$after_row-1, $d_info->{turns} || ''] );
                $self->draw_pattern;
            },
        )->pack(qw/-side left/);

        $d->Button(
            -text    => 'Cancel',
            -command => sub {
                $d->withdraw;
            },
        )->pack(qw/-side right/);

        $d_info->{dlog}           = $d;
        $self->{_insert_row_dlog} = $d_info;
    }

    $self->{_insert_row_dlog};
}

sub float_length_dlog
{
    my $self             = shift;
    my $old_float_length = shift;
    unless ( defined $self->{_float_length_dlog} )
    {
        my $d_info = {
            dlog         => undef,
            float_length => '',
        };
        my $d = $self->window->DialogBox(
            -title   => 'Shortest float to mark',
            -buttons => [qw/OK Cancel/],
        );
        $d->add( 'Entry', -textvariable => \$d_info->{float_length} )->pack;
        $d_info->{dlog}             = $d;
        $self->{_float_length_dlog} = $d_info;
    }
    $self->{_float_length_dlog}->{float_length} = $old_float_length;
    my $action = $self->{_float_length_dlog}->{dlog}->Show;
    return $action eq 'OK'
      ? $self->{_float_length_dlog}->{float_length}
      : $old_float_length;
}

sub delete_row_dlog
{
    my $self = shift;
    unless ( defined $self->{_delete_row_dlog} )
    {
        my $d_info = {
            dlog      => undef,
            where     => 'current',
            where_row => undef,
        };
        my $d = $self->window->Toplevel;
        $d->title('delete Row of Turns');
        $d->Radiobutton(
            -text     => 'Beginning (bottom)',
            -variable => \$d_info->{where},
            -value    => 'bottom',
        )->pack(qw/-side top -anchor w/);
        my $f1 = $d->Frame->pack(qw/-side top -anchor w/);
        $f1->Radiobutton(
            -text     => 'Row',
            -variable => \$d_info->{where},
            -value    => 'current',
        )->pack(qw/-side left/);
        $f1->Entry(
            -textvariable => \$d_info->{where_row},
            -width        => 10,
        )->pack(qw/-side left/);
        $d->Radiobutton(
            -text     => 'End (top)',
            -variable => \$d_info->{where},
            -value    => 'end',
        )->pack(qw/-side top -anchor w/);

        $d->Button(
            -text    => 'OK',
            -command => sub {
                my $after_row =
                    $d_info->{where} eq 'bottom'  ? 1
                  : $d_info->{where} eq 'current' ? $d_info->{where_row}
                  :                                 $self->pattern->number_of_rows;
                if ( $d_info->{where} eq 'current'
                    and ( $after_row < 0 or $after_row > $self->pattern->number_of_rows )
                  )
                {
                    $d->Dialog( -text =>
                          'Row must be between 1 and the number of turns' )
                      ->Show;
                    return;
                }
                print "delete_row($after_row-1)\n";
                $self->canvas->delete( "row" . ( $self->pattern->number_of_rows - 1 ) );
                $self->pattern->delete_row( $after_row - 1 );
                $self->current_row( $self->pattern->number_of_rows - 1 )
                  if $self->current_row >= $self->pattern->number_of_rows;
                $self->draw_pattern;
                $d->withdraw;
            },
        )->pack(qw/-side left/);

        $d->Button(
            -text    => 'Cancel',
            -command => sub {
                $d->withdraw;
            },
        )->pack(qw/-side right/);

        $d_info->{dlog}           = $d;
        $self->{_delete_row_dlog} = $d_info;
    }

    $self->{_delete_row_dlog};
}

sub duplicate_row_dlog
{
    my $self = shift;
    unless ( defined $self->{_duplicate_row_dlog} )
    {
        my $d_info = {
            dlog      => undef,
            from      => 'current',
            from_row  => undef,
            after     => 'current',
            after_row => undef,
        };
        my $d = $self->window->Toplevel;
        $d->title('duplicate a Row of Turns');
        my $f_bottom = $d->Frame->pack(qw/-side bottom -fill x -expand y/);
        my $f_left   = $d->Frame( -label => 'From' )->pack(qw/-side left/);
        my $f_right  = $d->Frame( -label => 'After' )->pack(qw/-side right/);
        $f_left->Radiobutton(
            -text     => 'Beginning (bottom)',
            -variable => \$d_info->{from},
            -value    => 'bottom',
        )->pack(qw/-side top -anchor w/);
        my $f1 = $f_left->Frame->pack(qw/-side top -anchor w/);
        $f1->Radiobutton(
            -text     => 'Row',
            -variable => \$d_info->{from},
            -value    => 'current',
        )->pack(qw/-side left/);
        $f1->Entry(
            -textvariable => \$d_info->{from_row},
            -width        => 10,
        )->pack(qw/-side left/);
        $f_left->Radiobutton(
            -text     => 'End (top)',
            -variable => \$d_info->{from},
            -value    => 'end',
        )->pack(qw/-side top -anchor w/);

        $f_right->Radiobutton(
            -text     => 'Beginning (bottom)',
            -variable => \$d_info->{from},
            -value    => 'bottom',
        )->pack(qw/-side top -anchor w/);
        my $f2 = $f_right->Frame->pack(qw/-side top -anchor w/);
        $f2->Radiobutton(
            -text     => 'Row',
            -variable => \$d_info->{from},
            -value    => 'current',
        )->pack(qw/-side left/);
        $f2->Entry(
            -textvariable => \$d_info->{from_row},
            -width        => 10,
        )->pack(qw/-side left/);
        $f_right->Radiobutton(
            -text     => 'End (top)',
            -variable => \$d_info->{from},
            -value    => 'end',
        )->pack(qw/-side top -anchor w/);

        $f_bottom->Button(
            -text    => 'Done',
            -command => sub {
                my $from_row =
                    $d_info->{from} eq 'bottom'  ? 1
                  : $d_info->{from} eq 'current' ? $d_info->{from_row}
                  :                                $self->pattern->number_of_rows;
                if ( $d_info->{from} eq 'current'
                    and ( $from_row < 0 or $from_row > $self->pattern->number_of_rows ) )
                {
                    $d->Dialog( -text =>
                          '"From" row must be between 1 and the number of turns'
                    )->Show;
                    return;
                }
                my $after_row =
                    $d_info->{after} eq 'bottom'  ? 0
                  : $d_info->{after} eq 'current' ? $d_info->{after_row}
                  :                                 $self->pattern->number_of_rows;
                if ( $d_info->{after} eq 'current'
                    and ( $after_row < 0 or $after_row > $self->pattern->number_of_rows )
                  )
                {
                    $d->Dialog( -text =>
                          '"To" row must be between 0 and the number of turns' )
                      ->Show;
                    return;
                }
                print "duplicate_row($from_row-1, $after_row)\n";
                $self->duplicate_row( $from_row - 1, $after_row );
                $self->draw_pattern;
                $d->withdraw;
            },
        )->pack(qw/-side left/);
        $f_bottom->Button(
            -text    => 'Stay',
            -command => sub {
                my $from_row =
                    $d_info->{from} eq 'bottom'  ? 1
                  : $d_info->{from} eq 'current' ? $d_info->{from_row}
                  :                                $self->pattern->number_of_rows;
                if ( $d_info->{from} eq 'current'
                    and ( $from_row < 0 or $from_row > $self->pattern->number_of_rows ) )
                {
                    $d->Dialog( -text =>
                          '"From" row must be between 1 and the number of turns'
                    )->Show;
                    return;
                }
                my $after_row =
                    $d_info->{after} eq 'bottom'  ? 0
                  : $d_info->{after} eq 'current' ? $d_info->{after_row}
                  :                                 $self->pattern->number_of_rows;
                if ( $d_info->{after} eq 'current'
                    and ( $after_row < 0 or $after_row > $self->pattern->number_of_rows )
                  )
                {
                    $d->Dialog( -text =>
                          '"To" row must be between 0 and the number of turns' )
                      ->Show;
                    return;
                }
                print "duplicate_row($from_row-1, $after_row)\n";
                $self->duplicate_row( $from_row - 1, $after_row );
                $self->draw_pattern;
            },
        )->pack(qw/-side left/);

        $f_bottom->Button(
            -text    => 'Cancel',
            -command => sub {
                $d->withdraw;
            },
        )->pack(qw/-side right/);

        $d_info->{dlog}              = $d;
        $self->{_duplicate_row_dlog} = $d_info;
    }

    $self->{_duplicate_row_dlog};
}

sub insert_dlog
{
    my $self = shift;
    unless ( defined $self->{_insert_dlog} )
    {
        $self->{_insert_dlog} = $self->window->Dialog(
            -text           => 'Insert new card or row?',
            -default_button => 'Row',
            -buttons        => [qw/Row Card Cancel/],
        );
    }
    $self->{_insert_dlog};
}

sub delete_dlog
{
    my $self = shift;
    unless ( defined $self->{_delete_dlog} )
    {
        $self->{_delete_dlog} = $self->window->Dialog(
            -text           => 'Delete card or row?',
            -default_button => 'Row',
            -buttons        => [qw/Row Card Cancel/],
        );
    }
    $self->{_delete_dlog};
}

sub insert_card_dlog
{
    my $self = shift;
    unless ( defined $self->{_insert_card_dlog} )
    {
        my $d_info = {
            dlog         => $self->window->Toplevel,
            palette      => undef,
            card_canvas  => undef,
            where        => 'current',
            where_card   => $self->current_card,
            SZ           => 'S',
            start        => 0,
            turns        => undef,
            threading    => [ 0, 1, 2, 3 ],
            current_hole => 0,
        };
        my $d = $d_info->{dlog};
        $d->title('Insert New Card');
        my $f3 = $d->Frame->pack(qw/-side bottom -fill x -expand y/);
        $f3->Button(
            -text    => 'Insert and Close',
            -command => sub {
                my $after_card =
                    $d_info->{where} eq 'bottom'  ? 0
                  : $d_info->{where} eq 'current' ? $d_info->{where_card}
                  :                                 $self->pattern->number_of_cards;
                if (
                    $d_info->{where} eq 'current'
                    and (  $after_card < 0
                        or $after_card > $self->pattern->number_of_cards )
                  )
                {
                    $d->Dialog( -text =>
                          '"To" card must be between 0 and the number of turns'
                    )->Show;
                    return;
                }

                my $turns = $d_info->{turns}->get( '1.0', 'end' );
                chomp $turns;
                print "unreversed turns is :$turns:\n";

                # any other data checks, like turns...
                # FIXME 
                $self->insert_card( $after_card,
                    join( "", reverse split( //, $turns ) ) );
                $self->SZ( $after_card, $d_info->{SZ} );
                $self->threading( $after_card, $d_info->{threading} );
                $self->start( $after_card, $d_info->{start} );
                $self->draw_pattern;
                $d->withdraw;
            },
        )->pack(qw/-side left/);
        $f3->Button(
            -text    => 'Insert and Stay',
            -command => sub {
                my $after_card =
                    $d_info->{where} eq 'bottom'  ? 0
                  : $d_info->{where} eq 'current' ? $d_info->{where_card}
                  :                                 $self->pattern->number_of_cards;
                if (
                    $d_info->{where} eq 'current'
                    and (  $after_card < 0
                        or $after_card > $self->pattern->number_of_cards )
                  )
                {
                    $d->Dialog( -text =>
                          '"To" card must be between 0 and the number of turns'
                    )->Show;
                    return;
                }

                my $turns = $d_info->{turns}->get( '1.0', 'end' );
                chomp $turns;
                print "unreversed turns is :$turns:\n";

                # any other data checks, like turns...
                # FIXME
                $self->insert_card( $after_card,
                    join( "", reverse split( //, $turns ) ) );
                $self->SZ( $after_card, $d_info->{SZ} );
                $self->threading( $after_card, $d_info->{threading} );
                $self->start( $after_card, $d_info->{start} );
                $self->draw_pattern;
            },
        )->pack(qw/-side left/);
        $f3->Button(
            -text    => 'Cancel',
            -command => sub {
                $d->withdraw;
            },
        )->pack(qw/-side right/);
        my $f1r =
          $d->Frame( -label => 'Turns' )
          ->pack(qw/-side right -fill y -expand y/);
        my $turns = $f1r->Scrolled(
            'Text',
            -scrollbars => 'e',
            -height     => 40,
            -width      => 1,
            -wrap       => 'char',
        )->pack(qw/-side top -expand 0 -fill none/);
        $turns->delete( '1.0', 'end' );
        $turns->insert( '1.0',
            join( "", reverse $self->card_turns( $self->current_card ) ) );
        my $f1l = $d->Frame( -borderwidth => 1 )->pack(qw/-side top -anchor w/);
        my $f2l = $d->Frame( -borderwidth => 1 )->pack(qw/-side top -anchor w/);
        my $f3l = $d->Frame( -borderwidth => 1 )->pack(qw/-side top -anchor w/);
        my $f4l = $d->Frame->pack(qw/-side top -anchor w/);

        # where to insert - in f1r
        $f1l->Radiobutton(
            -text     => 'Beginning (left)',
            -variable => \$d_info->{where},
            -value    => 'bottom',
        )->pack(qw/-side top -anchor w/);
        my $f1l1 = $f1l->Frame->pack(qw/-side top -anchor w/);
        $f1l1->Radiobutton(
            -text     => 'After card',
            -variable => \$d_info->{where},
            -value    => 'current',
        )->pack(qw/-side left/);
        $f1l1->Entry(
            -textvariable => \$d_info->{where_card},
            -width        => 10,
        )->pack(qw/-side left/);
        $f1l->Radiobutton(
            -text     => 'End (right)',
            -variable => \$d_info->{where},
            -value    => 'end',
        )->pack(qw/-side top -anchor w/);

        # threading direction - f2l
        $f2l->Radiobutton(
            -text     => 'Threaded S',
            -variable => \$d_info->{SZ},
            -value    => 'S',
        )->pack(qw/-side top -anchor w/);
        $f2l->Radiobutton(
            -text     => 'Threaded Z',
            -variable => \$d_info->{SZ},
            -value    => 'Z',
        )->pack(qw/-side top -anchor w/);

        # start hole and threading - f3l
        my $card_canvas = $self->_card_canvas( $f3l, \$d_info->{current_hole},
            \$d_info->{start}, 0 )->pack(qw/-side top/);

        # put up the palette - f4l
        my $h = $self->_palette( $f4l, $card_canvas, \$d_info->{current_hole},
            $d_info->{threading}, 'new' );

        $d_info->{turns}           = $turns;
        $d_info->{card_canvas}     = $card_canvas;
        $d_info->{palette}         = $h;
        $self->{_insert_card_dlog} = $d_info;
    }
    $self->{_insert_card_dlog};
}

sub _card_canvas    # (window, \current_hole, \start_hole, update_pattern?)
{
    my $self         = shift;
    my $win          = shift;
    my $current_hole = shift;
    my $start        = shift;
    my $update       = shift || 0;

    my $card_canvas = $win->Canvas(
        -height     => 200,
        -width      => 200,
        -background => 'white',
    );

    # focus areas
    $card_canvas->createRectangle(
        10, 10, 90, 90,
        -fill    => 'white',
        -outline => 'white',
        -tags    => [ 'frect', 'focusrect0', 'A' ],
    );
    $card_canvas->createRectangle(
        110, 10, 190, 90,
        -fill    => 'white',
        -outline => 'white',
        -tags    => [ 'frect', 'focusrect1', 'B' ],
    );
    $card_canvas->createRectangle(
        110, 110, 190, 190,
        -fill    => 'white',
        -outline => 'white',
        -tags    => [ 'frect', 'focusrect2', 'C' ],
    );
    $card_canvas->createRectangle(
        10, 110, 90, 190,
        -fill    => 'white',
        -outline => 'white',
        -tags    => [ 'frect', 'focusrect3', 'D' ],
    );

    # the hole labels
    $card_canvas->createText(
        45, 30,
        -text   => 'A',
        -anchor => 's',
        -tags   => ['A'],
    );
    $card_canvas->createText(
        155, 30,
        -text   => 'B',
        -anchor => 's',
        -tags   => ['B'],
    );
    $card_canvas->createText(
        155, 140,
        -text   => 'C',
        -anchor => 's',
        -tags   => ['C'],
    );
    $card_canvas->createText(
        45, 140,
        -text   => 'D',
        -anchor => 's',
        -tags   => ['D'],
    );

    # the holes
    $card_canvas->createOval(
        30, 30, 60, 60,
        -fill    => 'white',
        -outline => 'black',
        -tags    => [ 'hole', 'A', 'hole0' ],
    );
    $card_canvas->createOval(
        140, 30, 170, 60,
        -fill    => 'white',
        -outline => 'black',
        -tags    => [ 'hole', 'B', 'hole1' ],
    );
    $card_canvas->createOval(
        140, 140, 170, 170,
        -fill    => 'white',
        -outline => 'black',
        -tags    => [ 'hole', 'C', 'hole2' ],
    );
    $card_canvas->createOval(
        30, 140, 60, 170,
        -fill    => 'white',
        -outline => 'black',
        -tags    => [ 'hole', 'D', 'hole3' ],
    );

    # current hole indicator
    my $change_focus = sub {
        foreach my $h ( 0 .. 3 )
        {
            $card_canvas->itemconfigure(
                "focusrect$h",
                -fill    => 'white',
                -outline => 'white'
            );
        }
        $card_canvas->itemconfigure(
            "focusrect$$current_hole",
            -fill    => 'gold',
            -outline => 'black'
        );
    };

    # show the current hole
    &$change_focus;

    foreach my $h ( 0 .. 3 )
    {
        $card_canvas->bind(
            chr( ord('A') + $h ),
            '<1>',
            sub {
                $$current_hole = $h;
                &$change_focus;
            }
        );
    }

    # start hole indicators
    $card_canvas->createText(
        100, 100,
        -text   => 'Start hole',
        -anchor => 'center',
    );
    my $start_sub = $update
      ? sub {
        $self->start( $self->current_card, $$start );
        $self->update_pattern( $self->current_card );
      }
      : sub { };

    foreach my $coords ( [ 0, 80, 80 ], [ 1, 120, 80 ], [ 2, 120, 120 ],
        [ 3, 80, 120 ] )
    {
        $card_canvas->createWindow(
            $$coords[1],
            $$coords[2],
            -anchor => 'center',
            -window => $card_canvas->Radiobutton(
                -text     => '',
                -value    => $$coords[0],
                -command  => $start_sub,
                -variable => $start,
            ),
        );
    }

    $card_canvas;
}

sub delete_card_dlog
{
    my $self = shift;
    unless ( defined $self->{_delete_card_dlog} )
    {
        my $d_info = {
            dlog       => undef,
            where      => 'current',
            where_card => undef,
        };
        my $d = $self->window->Toplevel;
        $d->title('delete Card');
        $d->Radiobutton(
            -text     => 'Beginning (left)',
            -variable => \$d_info->{where},
            -value    => 'bottom',
        )->pack(qw/-side top -anchor w/);
        my $f1 = $d->Frame->pack(qw/-side top -anchor w/);
        $f1->Radiobutton(
            -text     => 'card',
            -variable => \$d_info->{where},
            -value    => 'current',
        )->pack(qw/-side left/);
        $f1->Entry(
            -textvariable => \$d_info->{where_card},
            -width        => 10,
        )->pack(qw/-side left/);
        $d->Radiobutton(
            -text     => 'End (right)',
            -variable => \$d_info->{where},
            -value    => 'end',
        )->pack(qw/-side top -anchor w/);

        $d->Button(
            -text    => 'OK',
            -command => sub {
                my $after_card =
                    $d_info->{where} eq 'bottom'  ? 1
                  : $d_info->{where} eq 'current' ? $d_info->{where_card}
                  :                                 $self->pattern->number_of_cards;
                if (
                    $d_info->{where} eq 'current'
                    and (  $after_card < 0
                        or $after_card > $self->pattern->number_of_cards )
                  )
                {
                    $d->Dialog( -text =>
                          'card must be between 1 and the number of turns' )
                      ->Show;
                    return;
                }
                print "delete_card($after_card-1)\n";
                $self->canvas->delete(
                    "card" . ( $self->pattern->number_of_cards - 1 ) );
                $self->pattern->delete_card( $after_card - 1 );
                $self->current_card( $self->pattern->number_of_cards - 1 )
                  if $self->current_card >= $self->pattern->number_of_cards;
                $self->draw_pattern;
                $d->withdraw;
            },
        )->pack(qw/-side left/);

        $d->Button(
            -text    => 'Cancel',
            -command => sub {
                $d->withdraw;
            },
        )->pack(qw/-side right/);

        $d_info->{dlog}            = $d;
        $self->{_delete_card_dlog} = $d_info;
    }

    $self->{_delete_card_dlog};
}

sub duplicate_card_dlog
{
    my $self = shift;
    unless ( defined $self->{_duplicate_card_dlog} )
    {
        my $d_info = {
            dlog       => undef,
            from       => 'current',
            from_card  => undef,
            after      => 'current',
            after_card => undef,
        };
        my $d = $self->window->Toplevel;
        $d->title('duplicate a card');
        my $f_bottom = $d->Frame->pack(qw/-side bottom -fill x -expand y/);
        my $f_left   = $d->Frame( -label => 'From' )->pack(qw/-side left/);
        my $f_right  = $d->Frame( -label => 'After' )->pack(qw/-side right/);
        $f_left->Radiobutton(
            -text     => 'Beginning (left)',
            -variable => \$d_info->{from},
            -value    => 'bottom',
        )->pack(qw/-side top -anchor w/);
        my $f1 = $f_left->Frame->pack(qw/-side top -anchor w/);
        $f1->Radiobutton(
            -text     => 'card',
            -variable => \$d_info->{from},
            -value    => 'current',
        )->pack(qw/-side left/);
        $f1->Entry(
            -textvariable => \$d_info->{from_card},
            -width        => 10,
        )->pack(qw/-side left/);
        $f_left->Radiobutton(
            -text     => 'End (right)',
            -variable => \$d_info->{from},
            -value    => 'end',
        )->pack(qw/-side top -anchor w/);

        $f_right->Radiobutton(
            -text     => 'Beginning (left)',
            -variable => \$d_info->{from},
            -value    => 'bottom',
        )->pack(qw/-side top -anchor w/);
        my $f2 = $f_right->Frame->pack(qw/-side top -anchor w/);
        $f2->Radiobutton(
            -text     => 'card',
            -variable => \$d_info->{from},
            -value    => 'current',
        )->pack(qw/-side left/);
        $f2->Entry(
            -textvariable => \$d_info->{from_card},
            -width        => 10,
        )->pack(qw/-side left/);
        $f_right->Radiobutton(
            -text     => 'End (right)',
            -variable => \$d_info->{from},
            -value    => 'end',
        )->pack(qw/-side top -anchor w/);

        $f_bottom->Button(
            -text    => 'Done',
            -command => sub {
                my $from_card =
                    $d_info->{from} eq 'bottom'  ? 1
                  : $d_info->{from} eq 'current' ? $d_info->{from_card}
                  :                                $self->pattern->number_of_cards;
                if ( $d_info->{from} eq 'current'
                    and
                    ( $from_card < 0 or $from_card > $self->pattern->number_of_cards ) )
                {
                    $d->Dialog( -text =>
'"From" card must be between 1 and the number of turns'
                    )->Show;
                    return;
                }
                my $after_card =
                    $d_info->{after} eq 'bottom'  ? 0
                  : $d_info->{after} eq 'current' ? $d_info->{after_card}
                  :                                 $self->pattern->number_of_cards;
                if (
                    $d_info->{after} eq 'current'
                    and (  $after_card < 0
                        or $after_card > $self->pattern->number_of_cards )
                  )
                {
                    $d->Dialog( -text =>
                          '"To" card must be between 0 and the number of turns'
                    )->Show;
                    return;
                }
                print "duplicate_card($from_card-1, $after_card)\n";
                $self->duplicate_card( $from_card - 1, $after_card );
                $self->draw_pattern;
                $d->withdraw;
            },
        )->pack(qw/-side left/);
        $f_bottom->Button(
            -text    => 'Stay',
            -command => sub {
                my $from_card =
                    $d_info->{from} eq 'bottom'  ? 1
                  : $d_info->{from} eq 'current' ? $d_info->{from_card}
                  :                                $self->pattern->number_of_cards;
                if ( $d_info->{from} eq 'current'
                    and
                    ( $from_card < 0 or $from_card > $self->pattern->number_of_cards ) )
                {
                    $d->Dialog( -text =>
'"From" card must be between 1 and the number of turns'
                    )->Show;
                    return;
                }
                my $after_card =
                    $d_info->{after} eq 'bottom'  ? 0
                  : $d_info->{after} eq 'current' ? $d_info->{after_card}
                  :                                 $self->pattern->number_of_cards;
                if (
                    $d_info->{after} eq 'current'
                    and (  $after_card < 0
                        or $after_card > $self->pattern->number_of_cards )
                  )
                {
                    $d->Dialog( -text =>
                          '"To" card must be between 0 and the number of turns'
                    )->Show;
                    return;
                }
                print "duplicate_card($from_card-1, $after_card)\n";
                $self->duplicate_card( $from_card - 1, $after_card );
                $self->draw_pattern;
            },
        )->pack(qw/-side left/);

        $f_bottom->Button(
            -text    => 'Cancel',
            -command => sub {
                $d->withdraw;
            },
        )->pack(qw/-side right/);

        $d_info->{dlog}               = $d;
        $self->{_duplicate_card_dlog} = $d_info;
    }

    $self->{_duplicate_card_dlog};
}

#sub AUTOLOAD
#{
#	print "AUTOLOAD: ", join("\n", $AUTOLOAD, @_, '');
#}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Weaving::Tablet::Tk - Tk user interface to Weaving::Tablet designer

=head1 SYNOPSIS

  use Weaving::Tablet::Tk;
  use Tk;
  my $pattern = Weaving::Tablet::Tk->new_pattern(mw => $mw, file => $file);
  my $pattern2 = Weaving::Tablet::Tk->new_pattern(mw => $mw, cards => $cards, rows => $rows);
  
  $pattern->canvas # get the drawing area
  $pattern->window # get the toplevel window
  
  MainLoop;

=head1 DESCRIPTION

Weaving::Tablet::Tk wraps a Tk user interface around the core routines in Weaving::Tablet.

Weaving::Tablet::Tk is a subclass of Weaving::Tablet.

=head2 new

The new function expects arguments as key/value pairs. 

The key "mw" is always expected. If not present, a new MainWindow is created.
If present, it is the parent for a new Toplevel window.

The key "file" identifies a pattern file to be loaded. If a pattern cannot
be loaded from that file, undef is returned.

The keys "cards" and "rows" specify the size of a new, blank pattern.

If the "file" key is not provided, a blank pattern is created, with a default
size of 1 row by 1 card.

The window and the drawing canvas are available via member functions. 

=head2 Member Functions

You can retrieve the Toplevel window via the "window" member.
You can retrieve the drawing canvas via the "canvas" member.

=head1 AUTHOR

Michael Houghton

=head1 SEE ALSO

perl(1).

=cut
