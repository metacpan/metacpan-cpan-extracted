###############################################################################
# tetris.pl - tetris using Perl and Tk
#                     ... Sriram
################################################################################

use strict;
use Tk;
my $MAX_COLS         = 10 ;       # 10 cells wide
my $MAX_ROWS         = 15 ;       # 15 cells high
my $TILE_WIDTH       = 20;        # width of each tile in pixels 
my $TILE_HEIGHT      = 20;        # height of each tile in pixels 

my $shoot_row        = int($MAX_ROWS/2);
my @cells = ();
my @tile_ids = ();

# Widgets
my $w_start;                              # start button widget
my $w_top;                                # top level widget
my $w_heap;                               # canvas

my $interval = 500; # in milliseconds
my @heap = ();                            # An element of the heap contains
                                          # a tile-id if that cell is
                                          # filled
$heap[$MAX_COLS * $MAX_ROWS - 1] = undef; # presize
# States
my $START = 0;
my $PAUSED = 1;
my $RUNNING = 2;
my $GAMEOVER = 4;
my $state = $PAUSED;

#----------------------------------------------------------------
# Block manipulation 
#----------------------------------------------------------------
sub tick {
    return if ($state == $PAUSED);

    if (!@cells) {
        if (!create_random_block()) {
            game_over();              # Heap is full:could not place block
            return;                   # at next tick interval
        }
        $w_top->after($interval, \&tick);
        return;
    }
    move_down();                      # move the block down
    $w_top->after($interval, \&tick); # reload timer for nex

}

sub fall {                 # Called when spacebar hit
    return if (!@cells);   # Return if not initialized
    1 while (move_down()); # Move down until it hits the heap or bottom.
}

sub move_left {
    my $cell;
    foreach $cell (@cells) {
        # Check if cell is at the left edge already
        # If not, check whether the cell to its left is already occupied.
        if ((($cell % $MAX_COLS) == 0) ||
            ($heap[$cell-1])){
            return;
        }
    }

    foreach $cell (@cells) {
        $cell--; # This affects the contents of @cells
    }
    
    $w_heap->move('block', - $TILE_WIDTH, 0);
}


sub move_right {
    my $cell;
    
    foreach $cell (@cells) {
        # Check if cell is at the right edge already
        # If not, check whether the cell to its right is already occupied.
        if (((($cell+1) % $MAX_COLS) == 0) ||
            ($heap[$cell+1])){
            return;
        }
    }

    foreach $cell (@cells) {
        $cell++; # This affects the contents of @cells
    }
    
    $w_heap->move('block', $TILE_WIDTH, 0);
}

sub move_down {
    my $cell;

    my $first_cell_last_row = ($MAX_ROWS-1)*$MAX_COLS;
    # if already at the bottom of the heap, or if a move down
    # intersects with the heap, then merge both.
    foreach $cell (@cells) {
        if (($cell >= $first_cell_last_row) ||
            ($heap[$cell+$MAX_COLS])) {
            merge_block_and_heap();
            return 0;
        }
    }

    foreach  $cell (@cells) {
        $cell += $MAX_COLS;
    }

    $w_heap->move('block', 0,  $TILE_HEIGHT);

    return 1;
}

sub rotate {
    # rotates the block counter_clockwise
    return if (!@cells);
    my $cell;
    # Calculate the pivot position around which to turn
    # The pivot is at (average x, average y) of all cells
    my $row_total = 0; my $col_total = 0;
    my ($row, $col);
    my @cols = map {$_ % $MAX_COLS} @cells;
    my @rows = map {int($_ / $MAX_COLS)} @cells;
    foreach (0 .. $#cols) {
        $row_total += $rows[$_];
        $col_total += $cols[$_];
    }
    my $pivot_row = int ($row_total / @cols + 0.5); # pivot row
    my $pivot_col = int ($col_total / @cols + 0.5); # pivot col
    # To position each cell counter_clockwise, we need to do a small
    # transformation. A row offset from the pivot becomes an equivalent 
    # column offset, and a column offset becomes a negative row offset.
    my @new_cells = ();
    my @new_rows = ();
    my @new_cols = ();
    my ($new_row, $new_col);
    while (@rows) {
        $row = shift @rows;
        $col = shift @cols;
        # Calculate new $row and $col
        $new_col = $pivot_col + ($row - $pivot_row);
        $new_row = $pivot_row - ($col - $pivot_col);
        $cell = $new_row * $MAX_COLS + $new_col;
        # Check if the new row and col are invalid (is outside or something
        # is already occupying that  cell)
        # If valid, then no-one should be occupying it.
        if (($new_row < 0) || ($new_row > $MAX_ROWS) ||
            ($new_col < 0) || ($new_col > $MAX_COLS)  ||
            $heap[$cell]) {
            return 0;
        }
        push (@new_rows, $new_row);
        push (@new_cols, $new_col);
        push (@new_cells, $cell);
    }
    # Move the UI tiles to the appropriate coordinates
    my $i= @new_rows-1;
    while ($i >= 0) {
        $new_row = $new_rows[$i];
        $new_col = $new_cols[$i];
        $w_heap->coords($tile_ids[$i],
                        $new_col * $TILE_WIDTH,      #x0
                        $new_row * $TILE_HEIGHT,     #y0
                        ($new_col+1) * $TILE_WIDTH,  #x1
                        ($new_row+1) * $TILE_HEIGHT);
        $i--;
    }
    @cells = @new_cells;
    1; # Success
}


sub set_state {
    $state = $_[0];
    if ($state == $PAUSED) {
        $w_start->configure ('-text' => 'Resume');
    } elsif ($state == $RUNNING) {
        $w_start->configure ('-text' => 'Pause');
    } elsif ($state == $GAMEOVER) {
        $w_heap->itemconfigure ('all',
                                '-stipple' => 'gray25');
        $w_heap->create ('text',
                         $MAX_COLS  * $TILE_WIDTH  /2 ,
                         $MAX_ROWS * $TILE_HEIGHT /2 ,
                         '-anchor' => 'center',
                         '-text' => "Game\nOver",
                         '-width' => $MAX_COLS * $TILE_WIDTH);
        $w_start->configure ('-text' => 'Start');
    } elsif ($state == $START) {
        $w_start->configure ('-text' => 'Start');
    }
}
sub start_pause {
    if ($state == $RUNNING) {
        set_state($PAUSED);
    } else {
        if ($state == $GAMEOVER) {
            new_game();
        }
        set_state($RUNNING);
        tick();
    }
}

sub new_game() {
    $w_heap->delete('all');
    @heap = ();
    @cells = ();
    my $y = ($shoot_row + 0.5)*$TILE_HEIGHT;
    my $arrow_width = $TILE_WIDTH/2;
    $w_heap->create('line',
                    0,
                    $y,
                    $arrow_width,
                    $y,
                    '-fill' => 'red',
                    '-arrow' => 'last',
                    '-arrowshape' => [$arrow_width,$arrow_width,$arrow_width/2]
                    );
    show_heap();
}

sub bind_key {
    my ($keychar, $callback) = @_;
    if ($keychar eq ' ') {
        $keychar = "KeyPress-space";
    }
    $w_top->bind("<${keychar}>", $callback);
}




sub shoot {
    my ($dir) = @_;
    my $first_cell_shoot_row = $shoot_row*$MAX_COLS;
    my $last_cell_shoot_row = $first_cell_shoot_row + $MAX_COLS;
    my $cell;
    my (@indices) = 
        sort {
            $dir eq 'left' ? 
                $cells[$a] <=> $cells[$b] :
                    $cells[$b] <=> $cells[$a]
                    } (0 .. $#cells);

    my $found = -1;
    my $i;
    foreach $i (@indices) {
        $cell = $cells[$i];
        if (($cell >= $first_cell_shoot_row) &&
            ($cell < $last_cell_shoot_row)) {
            $found = $i;
            last;
        }
    }
    if ($found != -1) {
        my $shot_tile = $tile_ids[$found];
        ($cell) = splice (@cells, $found, 1);
        splice (@tile_ids, $found, 1);
        my $y = ($shoot_row + 0.5)*$TILE_HEIGHT;
        my $arrow = $w_heap->create(
                                    'line',
                                    0,
                                    $y,
                                    (($cell % $MAX_COLS) + 0.5) * $TILE_WIDTH,
                                    $y,
                                    '-fill' => 'white',
                                    '-arrow' => 'last',
                                    '-arrowshape' => [7,7,3]
                                    );
        
        $w_heap->itemconfigure($shot_tile,
                               '-stipple' => 'gray25');
        $w_top->after (200,sub {
            $w_heap->delete($shot_tile); 
            $w_heap->delete($arrow); 
        });
    }

}


sub merge_block_and_heap {
    my $cell;
    # merge block
    foreach $cell (@cells) {
        $heap[$cell] = shift @tile_ids;
    }
    $w_heap->dtag('block'); # Forget about the block - it is now merged 

    # check for full rows, and get rid of them
    # All rows above them need to be moved down, both in @heap and 
    # the canvas, $w_heap
    my $last_cell = $MAX_ROWS * $MAX_COLS;

    my $filled_cell_count;
    my $rows_to_be_deleted = 0;
    my $i;

    for ($cell = 0; $cell < $last_cell; ) {
        $filled_cell_count = 0;
        my $first_cell_in_row = $cell;
        for ($i = 0; $i < $MAX_COLS; $i++) {
            $filled_cell_count++ if ($heap[$cell++]);
        }
        if ($filled_cell_count == $MAX_COLS) {
            # this row is full
            for ($i = $first_cell_in_row; $i < $cell; $i++) {
                $w_heap->addtag('delete', 'withtag' => $heap[$i]);
            }
            splice(@heap, $first_cell_in_row, $MAX_COLS);
            unshift (@heap, (undef) x $MAX_COLS);
            $rows_to_be_deleted = 1;
        }
    }

    @cells = ();
    @tile_ids = ();
    if ($rows_to_be_deleted) {
        $w_heap->itemconfigure('delete', 
                               '-fill'=> 'white');
        $w_top->after (300, 
                       sub {
                           $w_heap->delete('delete');
                           my ($i);
                           my $last = $MAX_COLS * $MAX_ROWS;
                           for ($i = 0; $i < $last; $i++) {
                               next if !$heap[$i];
                               # get where they are
                               my $col = $i % $MAX_COLS;
                               my $row = int($i / $MAX_COLS);
                               $w_heap->coords(
                                    $heap[$i],
                                    $col * $TILE_WIDTH,       #x0
                                    $row * $TILE_HEIGHT,      #y0
                                    ($col+1) * $TILE_WIDTH,   #x1
                                    ($row+1) * $TILE_HEIGHT); #y1

                           }
                       });
    }
}

sub show_heap {
    my $i;
    foreach $i (1 .. $MAX_ROWS) {
        $w_heap->create('line',
                        0,
                        $i*$TILE_HEIGHT,
                        $MAX_COLS*$TILE_WIDTH,
                        $i*$TILE_HEIGHT,
                        '-fill' => 'white'
                        );
    }
    foreach $i (1 .. $MAX_COLS) {
        $w_heap->create('line',
                        $i*$TILE_WIDTH,
                        0,
                        $i*$TILE_WIDTH,
                        $MAX_ROWS * $TILE_HEIGHT,
                        '-fill' => 'white'
                        );
    }

}

my @patterns = (
                [
                 "*  ",
                 "***"
                 ],
                [
                 "***",
                 "* *"
                 ],
                [
                 " * ",
                 "***"
                 ],
                [
                 "****"
                 ],
                [
                 "  *",
                 "***"
                 ],
                [
                 "*  ",
                 "***"
                 ],
                [
                 " **",
                 "** "
                 ],
                [
                 "**",
                 "**"
                 ]
                );
my @colors = (
              '#FF0000', '#00FF00', '#0000FF', 
              '#FFFF00', '#FF00FF', '#00FFFF'
              );


sub game_over {
    set_state($GAMEOVER);
}

sub create_random_block {
    # choose a random pattern, a random color, and position the 
    # block at the top of the heap.
    my $pattern_index = int(rand (scalar(@patterns)));
    my $color   = $colors[int(rand (scalar (@colors)))];
    my $pattern = $patterns[$pattern_index];
    my $pattern_width = length($pattern->[0]);
    my $pattern_height = scalar(@{$pattern});
    my $row = 0;  my $col = 0;
    my $base_col = int(($MAX_COLS - $pattern_width) / 2);
    while (1) {
        if ($col == $pattern_width) {
            $row++; $col = 0;
        }
        last if ($row == $pattern_height);
        if (substr($pattern->[$row], $col, 1) ne ' ') {
            push (@cells, $row * $MAX_COLS + $col + $base_col);
        }
        $col++;
    }
    $col = 0;
    my $cell;
    foreach $cell (@cells) {
        # If something already exists where the block is supposed
        # to be, return false
        return 0 if ($heap[$cell]);
    }

    $col = 0;
    foreach $cell (@cells) {
        create_tile($cell, $color);
    }
    return 1;
}

sub create_tile {
    my ($cell, $color) = @_;
    my ($row, $col);
    $col = $cell % $MAX_COLS;
    $row = int($cell / $MAX_COLS);
    push (@tile_ids, 
          $w_heap->create('rectangle',
                          $col * $TILE_WIDTH,      #x0
                          $row * $TILE_HEIGHT,     #y0
                          ($col+1) * $TILE_WIDTH,  #x1
                          ($row+1) * $TILE_HEIGHT, #y1
                          '-fill' => $color,
                          '-tags' => 'block'
                          )
          );
}

sub init {
    create_screen();
    bind_key('j', \&move_left);
    bind_key('l', \&move_right);
    bind_key(' ', \&fall);
    bind_key('k', \&rotate);
    bind_key('a', sub {shoot('left')});
    bind_key('s', sub {shoot('right')});
    srand();
    set_state($START);
    new_game();
}

sub create_screen {
    $w_top = MainWindow->new('Tetris - Perl/Tk');

    $w_heap = $w_top->Canvas('-width'  => $MAX_COLS * $TILE_WIDTH,
                             '-height' => $MAX_ROWS  * $TILE_HEIGHT,
                             '-border' => 1,
                             '-relief' => 'ridge');
    $w_start = $w_top->Button('-text' => 'Start',
                              '-command' => \&start_pause,
                              );
    my $w_quit = $w_top->Button('-text' => 'Quit',
#               '-command' => sub {$w_top->withdraw();exit(0)}
                                '-command' => sub {exit(0)}
                                );
    $w_heap->pack();
    $w_start->pack('-side'=> 'left', '-fill' => 'y', '-expand' => 'y');
    $w_quit->pack('-side'=> 'right', '-fill' => 'y', '-expand' => 'y');
}

init();
MainLoop();
