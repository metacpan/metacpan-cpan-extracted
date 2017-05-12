package Tk::GridColumns;

use strict;
use warnings;
use base qw( Tk::Pane );
use vars qw( $VERSION );
use Tk;

$VERSION = '0.15';

Tk::Widget->Construct( 'GridColumns' );

sub ClassInit {
    my( $class, $mw ) = @_;
    
    $class->SUPER::ClassInit( $mw );
} # ClassInit

sub Populate {
    my( $self, $args ) = @_;

    $self->{'_gridded'} = [0,0]; # number of rows/cols grid()ed
    $self->{'_selected'} = [];
    $self->{'_select_mode'} = delete $args->{-selectmode} || 'single row';
    $self->{'_data'} = delete $args->{-data} || [];
    $self->{'_columns'} = delete $args->{-columns} || [];
    $self->{'_col_attr'} = delete $args->{-colattr} || {};
    $self->{'_col_grid'} = delete $args->{-colgrid} || {};
    $self->{'_item_attr'} = delete $args->{-itemattr} || {};
    $self->{'_item_grid'} = delete $args->{-itemgrid} || {};
    $self->{'_item_draw_cmd'} = delete $args->{-item_draw_cmd} || \&_item_draw_cmd;
    $self->{'_select_cmd'} = delete $args->{-select_cmd} || \&_select_cmd;
    $self->{'_deselect_cmd'} = delete $args->{-deselect_cmd} || \&_deselect_cmd;
    $self->{'_item_bindings'} = {
        '<ButtonPress-1>' => \&_button_press,
        '<Control-ButtonPress-1>' => \&_ctrl_button_press,
        '<Shift-ButtonPress-1>' => \&_shift_button_press,
        #TODO: move with the arrow keys
        %{ delete $args->{-item_bindings} || {} },
    };
    
    $args->{'-gridded'} = 'xy';
    $args->{'-sticky'} = 'nsew';
    $args->{'-takefocus'} = 1;
    $self->SUPER::Populate( $args );
    
    $self->ConfigSpecs(
        -selectmode => ['METHOD'],
        -data => ['METHOD'],
        -columns => ['METHOD'],
        -colattr => ['METHOD'],
        -colgrid => ['METHOD'],
        -itemattr => ['METHOD'],
        -itemgrid => ['METHOD'],
        -item_bindings => ['METHOD'],
        -item_draw_cmd => ['METHOD'],
        -select_cmd => ['METHOD'],
        -deselect_cmd => ['METHOD'],
        'DEFAULT' => ['SELF'],
    );
    
    $self->refresh;

    return $self;
} # Populate

sub _button_press {
    my( $self, $w, $row, $col ) = @_;

    $w->focus;
    
    my @mode = $self->selectmode;
    return if $mode[0] eq 'none';
    
    $self->clear_selection;
    
    if ( $mode[1] eq 'row' ) {
        $self->select( $row, $_ ) for 0 .. $#{ $self->columns };
    } # if
    else {
        $self->select( $row, $col );
    } # else
} # _button_press

sub _ctrl_button_press {
    my( $self, $w, $row, $col ) = @_;

    $w->focus;

    my @mode = $self->selectmode;
    return if $mode[0] eq 'none';
    
    my $method = $self->selected->[$row]->[$col] ? 'deselect' : 'select';

    $self->clear_selection if $mode[0] eq 'single';

    if ( $mode[1] eq 'row' ) {
        $self->$method( $row, $_ ) for 0 .. $#{ $self->columns };
    } # if
    else {
        $self->$method( $row, $col );
    } # else
} # _ctrl_button_press

sub _shift_button_press {
    my( $self, $w, $row, $col ) = @_;

    $w->focus;

    my @mode = $self->selectmode;
    return if $mode[0] eq 'none';
    
    my @cur_sel = @{ $self->curselection };
    
    if ( $mode[0] eq 'single' or ! @cur_sel ) {
        $self->item_bindings->{'<ButtonPress-1>'}->(@_);
    } # if
    else {
        my $fst_sel = $cur_sel[ 0]->[0];
        my $lst_sel = $cur_sel[-1]->[0];
    
        my $orient = $row < $fst_sel ? $fst_sel
                   : $row > $lst_sel ? $lst_sel : -1;
        
        if ( $orient != -1 ) {
            for my $y ( $row > $orient ? ( $orient+1 .. $row ) : ( $row .. $orient-1 ) ) {
                for my $x ( $mode[1] eq 'row' ? ( 0 .. $#{ $self->columns } ) : $col ) {
                    $self->select( $y, $x );
                } # for
            } # for
        } # if
        else {
            $orient = abs($row - $lst_sel) > abs($row - $fst_sel) ? $fst_sel : $lst_sel;
        
            for my $y ( $row > $orient ? ( $orient .. $row ) : ( $row .. $orient ) ) {
                for my $x ( $mode[1] eq 'row' ? ( 0 .. $#{ $self->columns } ) : $col ) {
                    $self->deselect( $y, $x );
                } # for
            } # for
        } # else
    } # else
} # _shift_button_press

sub _item_draw_cmd {
    my( $self, $text, $attr, $row, $col ) = @_;
    
    my $w = $self->Label( -bg => $self->cget(-bg) );
    $w->configure( %$attr );
    $w->configure( -text => $text );
    
    return $w;
} # _item_draw_cmd

sub _select_cmd {
    my( $self, $w, $row, $col ) = @_;
    
    $w->configure(
        -background => 'blue',
        -foreground => 'white',
    );
} # _select_cmd

sub _deselect_cmd {
    my( $self, $w, $row, $col ) = @_;
    
    $w->configure(
        -background => $self->cget(-background),
        -foreground => 'black',
    );
    $w->configure( %{ $self->itemattr } );
} # _deselect_cmd

sub selectmode {
    my( $self, $value ) = @_;
    
    if ( @_ > 1 ) {
        $self->{'_select_mode'} = $value;
        return $self;
    } # if
    
    return wantarray ? split( ' ', $self->{'_select_mode'} )
                     : $self->{'_select_mode'};
} # selectmode

sub data {
    my( $self, $value ) = @_;
    
    if ( @_ > 1 ) {
        $self->{'_data'} = $value;
        return $self;
    } # if
    
    return $self->{'_data'};
} # data

sub columns {
    my( $self, $value ) = @_;
    
    if ( @_ > 1 ) {
        $self->{'_columns'} = $value;
        return $self;
    } # if
    
    return $self->{'_columns'};
} # columns

sub colattr {
    my( $self, $value ) = @_;
    
    if ( @_ > 1 ) {
        $self->{'_col_attr'} = $value;
        return $self;
    } # if
    
    return $self->{'_col_attr'};
} # colattr

sub colgrid {
    my( $self, $value ) = @_;
    
    if ( @_ > 1 ) {
        $self->{'_col_grid'} = $value;
        return $self;
    } # if
    
    return $self->{'_col_grid'};
} # colgrid

sub itemattr {
    my( $self, $value ) = @_;
    
    if ( @_ > 1 ) {
        $self->{'_item_attr'} = $value;
        return $self;
    } # if
    
    return $self->{'_item_attr'};
} # itemattr

sub itemgrid {
    my( $self, $value ) = @_;
    
    if ( @_ > 1 ) {
        $self->{'_item_grid'} = $value;
        return $self;
    } # if
    
    return $self->{'_item_grid'};
} # itemgrid

sub selected {
    my( $self, $value ) = @_;
    
    if ( @_ > 1 ) {
        $self->{'_selected'} = $value;
        return $self;
    } # if
    
    return $self->{'_selected'};
} # selected

sub item_draw_cmd {
    my( $self, $value ) = @_;
    
    if ( @_ > 1 ) {
        $self->{'_item_draw_cmd'} = $value;
        return $self;
    } # if
    
    return $self->{'_item_draw_cmd'};
} # item_draw_cmd

sub select_cmd {
    my( $self, $value ) = @_;
    
    if ( @_ > 1 ) {
        $self->{'_select_cmd'} = $value;
        return $self;
    } # if
    
    return $self->{'_select_cmd'};
} # select_cmd

sub deselect_cmd {
    my( $self, $value ) = @_;
    
    if ( @_ > 1 ) {
        $self->{'_deselect_cmd'} = $value;
        return $self;
    } # if
    
    return $self->{'_deselect_cmd'};
} # deselect_cmd

sub item_bindings {
    my( $self, $value ) = @_;
    
    if ( @_ > 1 ) {
        $self->{'_item_bindings'} = $value;
        return $self;
    } # if
    
    return $self->{'_item_bindings'};
} # item_bindings

sub select {
    my( $self, $row, $col ) = @_;
    
    $self->{'_selected'}->[$row]->[$col] = 1;
    $self->{'_select_cmd'}->( $self, $self->gridSlaves(-row=>$row+1,-column=>$col), $row, $col );
    
    return $self;
} # select

sub deselect {
    my( $self, $row, $col ) = @_;
    
    $self->{'_selected'}->[$row]->[$col] = 0;
    $self->{'_deselect_cmd'}->( $self, $self->gridSlaves(-row=>$row+1,-column=>$col), $row, $col );
    
    return $self;
} # deselect

sub curselection {
    my( $self ) = @_;
    
    my @selection;
    
    for my $row ( 0 .. $#{ $self->{'_data'} } ) {
        for my $col ( 0 .. $#{ $self->{'_data'}->[$row] } ) {
            push @selection, [ $row, $col ] if $self->{'_selected'}->[$row]->[$col];
        } # for
    } # for
    
    splice( @{ $self->{'_selected'} }, 1 + $#{ $self->{'_data'} } );
    
    #MAYBE: return different things depending on the -selectmode
    return \@selection;
} # curselection

sub clear_selection {
    my( $self ) = @_;
    
    $self->deselect( @$_ ) for @{ $self->curselection };
    
    return $self;
} # clear_selection

sub refresh_selection {
    my( $self ) = @_;
    
    $self->select( @$_ ) for @{ $self->curselection };
    
    return $self;
} # refresh_selection

sub add_column {
    my( $self, %attr ) = @_;
    
    push @{ $self->{'_columns'} }, \%attr;
    
    return $self;
} # add_column

sub add_row {
    my( $self, @row ) = @_;
    
    push @{ $self->{'_data'} }, \@row;
    
    return $self;
} # add_row

sub sort_col {
    my( $self, $col, $sort, $rev ) = @_;
    
    my @sorted = sort {
        $sort->(
            $rev ? ( $self->{'_data'}->[$b]->[$col],
                     $self->{'_data'}->[$a]->[$col], )
                 : ( $self->{'_data'}->[$a]->[$col],
                     $self->{'_data'}->[$b]->[$col], )
        );
    } 0 .. $#{ $self->{'_data'} };
    
    @{ $self->{'_data'} } = map { $self->{'_data'}->[$_] } @sorted;
    @{ $self->{'_selected'} } = map { $self->{'_selected'}->[$_] } @sorted;
    
    return $self;
} # sort_col

sub sort_cmd {
    my( $self, $col, $sort ) = @_;
    
    my $rev = 0;
    return sub {
        $self->sort_col(
            $col,
            ref $sort ? $sort
                      : $sort eq 'num' ? sub {    $_[0]  <=>    $_[1]  }
                                       : sub { lc($_[0]) cmp lc($_[1]) },
            $rev,
        )->refresh_items;
        
        $rev = !$rev;
    };
} # sort_cmd

sub draw_header {
    my( $self ) = @_;
    
    $self->{'_gridded'}->[1] = $#{ $self->{'_columns'} };
    
    my @weight = map {
        exists $self->{'_columns'}->[$_]->{'-weight'}
            ? [ $_, delete $self->{'_columns'}->[$_]->{'-weight'} ]
            : ()
    } 0 .. $#{ $self->{'_columns'} };
    
    for my $col ( 0 .. $#{ $self->{'_columns'} } ) {
        my $w = $self->Button( %{ $self->{'_col_attr'} } )->grid(
            %{ $self->{'_col_grid'} },
            -row => 0,
            -column => $col,
            -sticky => 'ew',
        );
        $w->configure( %{ $self->{'_columns'}->[$col] } );
    } # for
    
    for my $w ( @weight ) {
        $self->gridColumnconfigure( $w->[0], -weight => $w->[1] );
        $self->{'_columns'}->[$w->[0]]->{-weight} = $w->[1];
    } # for
    
    return $self;
} # draw_header

sub draw_items {
    my( $self ) = @_;
    
    $self->{'_gridded'}->[0] = @{ $self->{'_data'} };
    
    for my $row ( 0 .. $#{ $self->{'_data'} } ) {
        for my $col ( 0 .. $#{ $self->{'_columns'} } ) {
            my $w = $self->{'_item_draw_cmd'}->(
                $self,
                $self->{'_data'}->[$row]->[$col],
                $self->{'_item_attr'},
                $row, $col,
            )->grid(
                %{ $self->{'_item_grid'} },
                -row => $row+1,
                -column => $col,
                -sticky => 'nsew',
            );
            
            for my $seq ( keys %{ $self->{'_item_bindings'} } ) {
                $w->bind( $seq, sub { $self->{'_item_bindings'}->{$seq}->( $self, $w, $row, $col ) } );
            } # for
        } # for
    } # for
    
    return $self;
} # draw_items

sub set_filler {
    my( $self ) = @_;
    
	$self->gridRowconfigure( 1 + $self->{'_gridded'}->[0], -weight => 1 );
	
	return $self;
} # set_filler

sub remove_filler {
    my( $self ) = @_;

    $self->gridRowconfigure( 1 + $self->{'_gridded'}->[0], -weight => 0 );
    
    return $self;
} # remove_filler

sub destroy_all {
    my( $self ) = @_;

    $_->destroy for $self->gridSlaves;
    $self->remove_filler;
    $self->gridColumnconfigure( $_, -weight => 0 ) for 0 .. $self->{'_gridded'}->[1];
    
    return $self;
} # destroy_all

sub refresh {
    my( $self ) = @_;

    $self->destroy_all->draw_header->draw_items->set_filler->refresh_selection;
    
    return $self;
} # refresh

sub refresh_header {
    my( $self ) = @_;
    
    $_->destroy for $self->gridSlaves( -row => 0 );
    $self->gridColumnconfigure( $_, -weight => 0 ) for 0 .. $self->{'_gridded'}->[1];
    $self->draw_header;
    
    return $self;
} # refresh_header

sub refresh_items {
    my( $self ) = @_;
    
    for my $row ( 1 .. $self->{'_gridded'}->[0] ) {
        $_->destroy for $self->gridSlaves( -row => $row );
    } # for
    $self->remove_filler->draw_items->set_filler->refresh_selection;
    
    return $self;
} # refresh_items

1;

#TODO: select() and deselect() that react on the -selectmode
#TODO: delete_row()
#TODO: select_row(), select_col() and the deselect() ones
#TODO: refresh_row(), refresh_col()
#TODO: ROText example
#TODO: easier code for the _button_press() and so on...

__END__

=head1 NAME

Tk::GridColumns - Columns widget for Tk using Tk::grid

=head1 SYNOPSIS

  use Tk::GridColumns;

  my $gc = $top->GridColumns( ... );
  ...
  $gc->refresh;

=head1 DESCRIPTION

A Tk::GridColumns is similar to a Tk::HList but its implementation gives you
more freedom: The header and data information is stored in two array refs,
so that you just have to adjust these and then ->refresh() the widget to make
the changes visible. You can define how much space each column will take (grid:
-weight). You can change almost everything: define your own item bindings (
Example: Editable), change the appearance of the widget very easily using
default attributes for the column buttons and the data items (Example:
Appearance), add scrollbars to the widget (Example: Scrolled), ...

Take a look at the example code to discover if this module is an appropriate
solution for your tasks.

=head2 EXPORT

Nothing

=head1 EXAMPLES

=head2 Simple

    #!/usr/bin/perl

    use strict;
    use warnings;
    use Tk;
    use Tk::GridColumns;

    my $mw = tkinit( -title => 'Tk::GridColumns example -- Simple' );

    my $gc = $mw->GridColumns(
        -data => [ map { [ $_, chr 97 + rand $_*2 ] } 1 .. 10 ], # some data
        -columns => \my @columns, # need to define columns after creating the
                                  # object, because of the sort '-command'
    )->pack(
        -fill => 'both',
        -expand => 1,
    );

    @columns = (
        {
            -text => 'Number',
            -command => $gc->sort_cmd( 0, 'num' ),
        },
        {
            -text => 'String',
            -command => $gc->sort_cmd( 1, 'abc' ),
            -weight => 1, # this columns gets the remaining space
        },
    );

    $gc->refresh;

    MainLoop;
    
=head2 Scrolled

    #!/usr/bin/perl

    use strict;
    use warnings;
    use Tk;
    use Tk::GridColumns;

    my $mw = tkinit( -title => 'Tk::GridColumns example -- Scrolled' );
    $mw->geometry( "=300x200+100+100" );

    my $gc = $mw->Scrolled(
        'GridColumns' =>
        -scrollbars => 'ose',
        -data => [ map { [ $_, chr 97 + rand $_+5 ] } 1 .. 20 ],
        -columns => \my @columns,
    )->pack(
        -fill => 'both',
        -expand => 1,
    )->Subwidget( 'scrolled' ); # do not forget this one ;)

    @columns = (
        {
            -text => 'Number',
            -command => $gc->sort_cmd( 0, 'num' ),
        },
        {
            -text => 'String',
            -command => $gc->sort_cmd( 1, 'abc' ),
            -weight => 1,
        },
    );

    $gc->refresh;

    MainLoop;

=head2 Editable

    #!/usr/bin/perl

    use strict;
    use warnings;
    use Tk;
    use Tk::GridColumns;

    my $mw = tkinit( -title => 'Tk::GridColumns example -- Editable' );

    my $gc = $mw->GridColumns(
        -data => \my @data, # ease the data access
        -columns => \my @columns,
        -item_bindings => { '<Double-ButtonPress-1>' => \&edit_item },
    )->pack(
        -fill => 'both',
        -expand => 1,
    );

    @columns = (
        {
            -text => 'Number',
            -command => $gc->sort_cmd( 0, 'num' ),
        },
        {
            -text => 'String',
            -command => $gc->sort_cmd( 1, 'abc' ),
            -weight => 1,
        },
    );

    @data = map { [ $_, chr 97 + rand $_*2 ] } 1 .. 10;

    $gc->refresh;

    MainLoop;

    sub edit_item {
        my( $self, $w, $row, $col ) = @_;
        
        $w->destroy; # destroy the widget that currently displays the data
        
        my $entry = $self->Entry(
            -textvariable => \$data[$row][$col],
            -width => 0,
        )->grid(
            -row => $row+1,
            -column => $col,
            -sticky => 'nsew',
        );
        
        $entry->selectionRange( 0, 'end' );
        $entry->focus; # so the user can instantly start editing

        $entry->bind( '<Return>' => sub { $self->refresh_items } );
        $entry->bind( '<FocusOut>' => sub { $self->refresh_items } );
    } # edit_item

=head2 Appearance

    #!/usr/bin/perl

    use strict;
    use warnings;
    use Tk;
    use Tk::GridColumns;

    my $mw = tkinit( -title => 'Tk::GridColumns example -- Appearance' );

    my $gc = $mw->GridColumns(
        -data => [ map { [ $_, chr 97 + rand $_*2 ] } 1 .. 10 ],
        -columns => \my @columns,
        -bg => 'black',
        -colattr => {
            -fg => 'green', -bg => 'black',
            -activeforeground => 'green',
            -activebackground => 'black',
        },
        -itemattr => { -fg => 'green', -bg => 'black' },
    )->pack(
        -fill => 'both',
        -expand => 1,
    );

    @columns = (
        {
            -text => 'Number',
            -command => $gc->sort_cmd( 0, 'num' ),
        },
        {
            -text => 'String',
            -command => $gc->sort_cmd( 1, 'abc' ),
            -weight => 1,
        },
    );

    $gc->refresh;

    MainLoop;

=head1 TODO

There is much work to do and now I found some time to update the module. And
hopefully I will update it more often in the next months :)

    * Selection:
        - select() and deselect() that react on the -selectmode
        - select_item(), select_row(), select_col() and the deselect() ones
        - 'from' and 'to' parameters for the select() and deselect() routines
    * Refreshing:
        - refresh_item(), refresh_row(), refresh_col() so that you can refresh
          only the parts that need to get refreshed
    * more documentation

=head1 SEE ALSO

Tk, Tk::grid, Tk::Pane, Tk::Scrolled, Tk::HList, Tk::Columns, Tk::MListbox, Tk::Table, Tk::TableMatrix

=head1 AUTHOR

Matthias Wienand, E<lt>matthias.wienand@googlemail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Matthias Wienand

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

