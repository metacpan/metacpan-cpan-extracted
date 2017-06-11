
use strict;
use warnings;

#See the second half of this file for the Wx::Perl::DbLinker::DBGridTable package
#
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
#
package Wx::Perl::DbLinker::Wxdatasheet;
use Wx::Perl::DbLinker;
our $VERSION = $Wx::Perl::DbLinker::VERSION;
use Carp qw(croak confess carp);
# use Data::Dumper;
use Log::Any;
use Wx qw(:everything);
use base qw(Wx::Grid);
use Gtk2::Ex::DbLinker::DatasheetHelper;
use Wx::Event
    qw( EVT_GRID_CELL_CHANGED EVT_COMBOBOX EVT_GRID_RANGE_SELECT EVT_GRID_SELECT_CELL);

my %signals = ( 'Wx::GridCellChoiceEditor' => \&EVT_COMBOBOX, );

my %render = (
    text    => sub { return Wx::GridCellStringRenderer->new; },
    hidden  => sub { return Wx::GridCellStringRenderer->new; },
    number  => sub { return Wx::GridCellNumberRenderer->new; },
    toggle  => sub { return Wx::GridCellBoolRenderer->new; },
    combo   => sub { return Wx::GridCellChoiceEditor->new(@_); },
    boolean => sub { return Wx::GridCellBoolRenderer->new; },
    time    => sub { return Wx::GridCellDateTimeRenderer->new; },

);

use constant {
    UNCHANGED     => 0,
    CHANGED       => 1,
    INSERTED      => 2,
    DELETED       => 3,
    LOCKED        => 4,
    STATUS_COLUMN => -1,
};

#use constant STATUS_LAB => qw(sync !!! new del lck);
use constant STATUS_LAB => ( ' ', '!', '*', 'x', 'o' );

sub new {

    #my ($class, $frame, $req) = @_;
    my $class = shift;
    my %def   = ( borders_size => [ 20, 20 ], fields => undef );
    my %arg   = ref $_[0] eq "HASH" ? ( %def, %{ $_[0] } ) : ( %def, @_ );
    my $self  = $class->SUPER::new( $arg{parent_widget}, wxID_ANY );

    $self->{dman} = $arg{data_manager};

    #$self->{fields} = $$req{fields}  || undef;
    $self->{fields}     = $arg{fields};
    $self->{on_changed} = $arg{on_changed}
        ;    # Code that runs when a record is changed ( any column )
    $self->{on_row_select} = $arg{on_row_select};
    $self->{after_update}  = $arg{after_update};

#$self->{borders_size} = $$req{borders_size} || [22, 20]; #array ref of row1 height and col1 width
    $self->{borders_size} = $arg{borders_size};

    #$self->{log} = Log::Log4perl->get_logger(__PACKAGE__);
    $self->{log} = Log::Any->get_logger;
    my @cols = $self->{dman}->get_field_names;

    # cols holds the field names from the table. Nothing else !
    $self->{cols} = \@cols;
    my %hcols = map { $_ => 1 } @cols;
    $self->{hcols} = \%hcols;
    $self->{log}->debug( "new called - cols: " . join( " ", @cols ) );

    # $self->_setup_fields;

    #my $table =
    #$table->SetView($self);
    #$self->SetTable($table);

    $self->{ds_helper} = Gtk2::Ex::DbLinker::DatasheetHelper->new(
        cols => $self->{cols},
        dman => $self->{dman},

        #col_number => sub { $self->colnumber_from_name( $_[0] ); }

    );
    ( $self->{fields}, $self->{hiddencols} ) =
        $self->{ds_helper}->setup_fields(
        allfields => $self->{fields},
        cols      => $self->{cols}
        );

    my $table = $self->_setup_gridtable;
    $self->SetTable($table);
    $self->_setup_grid;
    $self->SetSelectionMode(wxGridSelectRows);

    EVT_GRID_CELL_CHANGED( $self,
        sub { my $self = shift; $self->_changed(@_); } );
    EVT_GRID_SELECT_CELL( $self, sub { shift->_cell_clicked(@_); } );
    EVT_GRID_RANGE_SELECT( $self, sub { shift->_row_selected(@_); } );
    $self->{log}->debug( "constructor done: rows: " . $self->GetNumberRows );

    #col_number => \&{ $self->colnumber_from_name }
    $self->{changed} = 0;
    return $self;

}

sub _setup_gridtable {
    my $self = shift;
    return Wx::Perl::DbLinker::DBGridTable->new(
        { dman => $self->{dman}, fields => $self->{fields}, grid => $self } );

}

#combo are backed up with two array ref and a scalar:
#$self->{combo_val}->{ $field_name } : array ref of values diplayed
#self->{combo_id}->{ $field_name } : array ref of corresponding id (that are stored in the table in the $field_name column
#$self->{combo_cur} : an array ref of the id the values currently displayed by the combos in the grid
#
sub _setup_grid {
    my ($self) = @_;

    my @apk     = $self->{dman}->get_autoinc_primarykeys;
    my $lastcol = scalar @{ $self->{fields} };

    for my $field ( @{ $self->{fields} } ) {

        #my $renderer = $render{$field->{renderer}}[0]();
        my $ed;

        if ( $field->{renderer} eq "toggle" ) {
            $field->{editor} = $render{ $field->{renderer} }();
        }
        elsif ( $field->{renderer} eq "combo" ) {

            $field->{editor} = $render{ $field->{renderer} }
                ( $self->_setup_combo( $field->{name} ), 0 );
            $self->{log}->debug(
                "field name with combo renderer: " . $field->{name} );

            my $signal = $signals{ ref $field->{editor} };

            #http://sourceforge.net/p/wxperl/mailman/message/8872987/
            &$signal( $self, -1,
                sub { shift; $self->_combo_edited( $field->{name}, @_ ); } );

            #  $renderer->{col_data} = $lastcol++ ;
            #

            #my $fieldtype = $self->{fieldsType}->{$field->{name}};

=for comment
			#varchar, char, integer,boolean, date, serial, text, smallint, mediumint, timestamp, enum
			 	my $fieldtype = $fieldtype{ $self->{dman}->get_field_type( $field->{name} ) };
			  # $self->{log}->debug("combo field type : " . $fieldtype);
			 	if ( $fieldtype eq "number"  ) { # serial, intege but not boolean ...
				 # $renderer->{data_type} = "numeric";
					$renderer->{comp} = sub {my ($a, $b, $c) = @_; return ($c ? ($a == $b) : ($a != $b)); };
	            		} else {
				# $renderer->{data_type} = "string";
					$renderer->{comp} = sub {my ($a, $b, $c) = @_; return ( $c ? ($a eq $b) : ($a ne $b)); };
            			}
				#$field->{ editor } = $ed;
				#	Gtk2::TreeViewColumn->new_with_attributes($field->{name}, $renderer, 'text' => $renderer->{col_data} );
=cut

        }
        else {
            $self->{log}
                ->debug( "field name with txt renderer: " . $field->{name} );
            $field->{editor} = $render{ $field->{renderer} }()
                if ( $render{ $field->{renderer} } );

            if ( grep /^$field->{name}$/, @apk ) {
                $self->{log}->debug("not editable because it's a pk");

                #$renderer->set( editable => 0 );
                $field->{editor_ro} = 1;
            }

        }
    }    #for $fields
         # die ($self->GetNumberRows);
         # enlever -2 a cause des labels
    for my $r ( 0 .. $self->GetNumberRows() - 1 ) {    # Row Header Text
            #my $rptr = $r+1;
            #$grid->SetRowLabelValue($r, "Row $rptr");
            #$grid->SetRowLabelBackgroundColour($r, wxGREEN);
        $self->SetRowLabelValue( $r, (STATUS_LAB)[UNCHANGED] );

        #$grid->SetReadOnly($r, 0);
        for my $field ( @{ $self->{fields} } ) {

            #my $col = $self->{colname_to_number}->{ $field->{name} };
            my $col =
                $self->{ds_helper}->colnumber_from_name( $field->{name} );
            if ( $r == 0 ) {

                my $label = (
                    defined $field->{header_markup}
                    ? $field->{header_markup}
                    : $field->{name}
                );
                $self->{log}->debug( "col: ", $col, " label: ", $label );
                $self->{log}->debug( "cell editor: " . ref $field->{editor} );
                croak($self->{log}->error("\$col undef")) unless defined $col;
                $self->SetColLabelValue( $col, $label );
                if ( defined $field->{size} ) {
                    $self->SetColSize( $col, $field->{size} );    #if ($r==0);
                }
            }
            my $ed_ref = ref $field->{editor};
            if ( $ed_ref eq "Wx::GridCellChoiceEditor" ) {
                $self->SetCellEditor( $r, $col, $field->{editor} );

# remplacer la valeur de id_credit par le text correspondant dans la combo
# _find_index est appele pour toutes les lignes de la col, si la liste est longue, ce n'est pas efficace
# $id est la valeur affichee dans la grid qui provient de la table
                my $id = $self->GetCellValue( $r, $col );

                # $val est le array ref des id
                my $val = $self->{combo_id}->{ $field->{name} };

                #$pos et l'index de id dans ce vecteur
                my $pos = $self->_find_index( $id, @$val );

               # $text est le text a afficher dans la cellule à la place du id

                my $text;
                if ( $pos > -1 ) {
                    $text = $self->{combo_val}->{ $field->{name} }->[$pos];
                }
                else {
                    $text = "";
                }

# combo_cur contient l'id de la derniere ligne affichee de la grid
# $self->{combo_cur}->{$field->{name}} = $self->{combo_id}->{ $field->{name} }->[$pos];
#$self->{log}->debug( $field->{name}, " id: ", $id, " text: ", $text);
#$self->{combo_cur}->{ $field->{name} } est un array ref des id sous-jacents aux lignes affichees
#my $aref = $self->{combo_cur}->{ $field->{name} };
                my $aref = $self->{combo_cur};
                push @$aref, $id;
                $self->SetCellOverflow( $r, $col, 0 );
                $self->SetCellValue( $r, $col, $text );

                # $self->GetCellEditor($r,$col)->StartingClick;
            }
            else {

                $self->SetCellRenderer( $r, $col, $field->{editor} );
                if ( $field->{renderer_function} ) {
                    my $coderef = $field->{renderer_function};
                    $self->SetCellValue( $r, $col,
                        &$coderef( $r, $col, $self->GetTable ) );
                }

            }

#$self->{log}->debug("set cell renderer ", $ed_ref, " row: ", $r, " col: ", $col);

            if ( $field->{editor_ro} ) {
                $self->SetReadOnly( $r, $col, 1 );
            }

        }
    }                             # for rows...
    $self->EnableGridLines(1);    # Grid lines 1-on, 0-off
    $self->AutoSizeColumns();
    for my $colno ( @{ $self->{hiddencols} } ) {

        $self->SetColSize( $colno, 0 );
    }
    $self->SetColLabelSize( $self->{borders_size}->[0] );
    $self->SetRowLabelSize( $self->{borders_size}->[1] );

}    #setup_grid

sub _setup_combo {
    my ( $self, $fieldname ) = @_;
    my $column_no = $self->colnumber_from_name($fieldname);
    my $fields    = $self->{fields}[$column_no];
    my $col_ref   = $self->{ds_helper}
        ->init_combo_setup( name => $fieldname, fields => $fields );
    my ( $rowsref, $idsref ) = $self->{ds_helper}->setup_combo(
        fields  => $fields,
        name    => $fieldname,
        col_ref => $col_ref
    );

    $self->{combo_id}->{$fieldname}  = $idsref;
    $self->{combo_val}->{$fieldname} = $rowsref;
    $self->{combo_cur}               = [];

    return $rowsref;
}

sub get_column_value {

    # returns the value in the requested column in the currently selected row

    my ( $self, $sql_fieldname ) = @_;

    my $current_row = $self->{current_row};
    $self->{log}->debug( "get_column_value current row : "
            . ( defined $current_row ? $current_row : " undef" ) );

    # my $model = $self->{treeview}->get_model;

    return unless ( defined $current_row );

    my $value;
    my $column_no = $self->colnumber_from_name($sql_fieldname);

    if ( $self->_is_combo($column_no) ) {

        #my $aref = $self->{combo_cur}->{$sql_fieldname};
        my $aref = $self->{combo_cur};
        $value = $aref->[$current_row];
        # $self->{log}->debug( "get_column_value combo_cur : ", Dumper $aref);
        $self->{log}
            ->debug( "get_column_value is combo return  : " . $value );
    }
    else {

        $value = $self->GetCellValue( $current_row, $column_no );
    }

    return $value;
}

sub set_column_value {

    my ( $self, $fieldname, $value ) = @_;

    my $done;

#if ( $self->{mult_select} ) {
#    $self->{log}->debug("set_column_value called with multi_select enabled -> setting value in 1st selected row");
#}

    #my  @selected_rows = $self->GetSelectedRows;
    my $current_row = $self->{current_row};
    $self->{log}->debug( "set_column_value current row : "
            . ( defined $current_row ? $current_row : " undef" ) );

    #if ( ! scalar( @selected_rows ) ) {
    #    return 0;
    #}
    return unless ( defined $current_row );

    my $col = $self->colnumber_from_name($fieldname);

    if ( $self->_is_combo($col) ) {

        $self->{log}->debug( $fieldname . " is a combo : no update done" );
        $done = 0;
    }
    else {

        $self->SetCellValue( $current_row, $col, $value );
        $done = 1;
    }

    return $done;

}

sub get_current_row {
    return shift->{current_row};
}

sub colnumber_from_name {

    my ( $self, $fieldname ) = @_;

    #confess "fieldname undef" unless ( defined $fieldname );
    #return $self->{colname_to_number}->{$fieldname}
    return $self->{ds_helper}->colnumber_from_name($fieldname);

}

sub undo {

    #shift->query;
    #rebuild the whole grid using the data from the table
    shift->update;
}

#called by on-change event for each row of the treeview
#added by query

sub _changed {

    my ( $self, $event ) = @_;
    my $r = $event->GetRow;
    return if ( $self->GetRowLabelValue($r) eq (STATUS_LAB)[INSERTED] );
    $self->{log}->debug( "_changed: ", $r, " : ", $event->GetCol, "\n" );
    $self->SetRowLabelValue( $r, (STATUS_LAB)[CHANGED] );

    $self->{changed} = 1;

    $self->{on_changed}() if ( defined $self->{on_changed} );

}

sub update {
    my ($self) = @_;
    $self->{log}->debug("update");
    my $last = $self->{dman}->row_count;

    $self->ClearGrid;

    #$self->ForceRefresh;
    my $table = $self->_setup_gridtable;

#	Wx::Perl::DbLinker::DBGridTable->new({dman=> $self->{dman}, fields => $self->{fields}, grid=>$self,});
#$self->{log}->debug("update : ",join(" ", @));
    $self->SetTable($table);
    $self->_setup_grid;
    if ( defined $self->{after_update} ) {

        $self->{after_update}();
    }

}

sub apply {
    my $self  = shift;
    my $pkref = $_[0];
    my $last  = $self->GetNumberRows;

    #$self->{ds_helper}->init_rows($self);
    $self->{ds_helper}->init_apply(
        iter => 0,
        next =>
            sub { my $p = $_[0]; $p++; return ( $p < $last ? $p : undef ); },
        has_more_row => sub {
            my $v = ( $self->{iter} < $last );
            $self->{log}
                ->debug( "has_more_row ", ( $v ? " true" : " false" ) );
            return $v;
        },
        get_val => sub {
            my ( $row, $col, $name ) = @_;
            #$name can be undef in the case of $col = -1
            my $val;
            if ( $col == STATUS_COLUMN ) {
                my $status_lab = $self->GetRowLabelValue($row);

                $val = $self->_find_index( $status_lab, (STATUS_LAB) );
            }
            else {
                # $self->{log}->debug(Dumper $self->{combo_cur}); #->{$name}
                if ( $self->_is_combo($col) ) {
                    #my $aref = $self->{combo_cur}->{$name};
                    my $aref = $self->{combo_cur};
                    $val = $aref->[$row];
                    $self->{log}->debug( " found "
                            . $val
                            . " for grid row "
                            . $row
                            . " for combo "
                            . $name );
                }
                else {
                    $val = $self->GetTable->GetValue( $row, $col );
                    $val = undef unless (defined $val && length($val)); #Wx grid return an empty string -> insert fails with DbiDM
                }
            }
            $self->{log}->debug(
                "get_val found: ",
                ( defined $val ? "*" . $val ."*" : "undef" ),
                " for row : ", $row, " col : ", $col
            );
            return $val;
        },
        set_val => sub {
            my ( $row, $col, $val ) = @_;
            $self->{log}
                ->debug( "set_val : ", ( defined $val ? $val : " undef" ),
                " for row : ", $row, " col : ", $col );
            if ( $col == STATUS_COLUMN ) {
                my $label = (STATUS_LAB)[$val];
                $self->{log}->debug( "label found : ", $label );
                $self->SetRowLabelValue( $row, $label );
            }
            else {
                $self->SetCellValue( $row, $col, $val );
            }
        },
        del_row => sub {
            $self->{log}->debug( "deleting at row ", $_[0] );
            $self->DeleteRows( $_[0] );
        },
        status_col => STATUS_COLUMN,
    );

    #$self->{ds_helper}->{dman} = $self->{dman};
    $self->{ds_helper}->apply($pkref);

    $self->{after_update}() if ( defined $self->{after_update} );

}

sub insert {

    my ( $self, @columns_and_values ) = @_;
    $self->{log}->debug("insert");

    $self->{log}->debug(
        "new rec default values: " . join( " ", @columns_and_values ) );

    $self->AppendRows(1);
    my $last = $self->GetNumberRows - 1;

    # $self->GetNumberRows;
    $self->SetRowLabelValue( $last, (STATUS_LAB)[INSERTED] );
    if (@columns_and_values) {
        my $i = 1;
        my $col_no;
        foreach my $col_no_or_value (@columns_and_values) {

            if ($i) {
                $col_no = $col_no_or_value;
                $i      = 0;
            }
            else {
                $self->{log}->debug( "last: "
                        . $last
                        . " col: "
                        . $col_no
                        . " value: "
                        . $col_no_or_value );
                $self->SetCellValue( $last, $col_no, $col_no_or_value );
                $i = 1;
            }
        }
    }

}

sub delete {

    my $self = shift;
    $self->{log}->debug("delete");
    $self->SetRowLabelValue( $self->{current_row}, (STATUS_LAB)[DELETED] )
        if ( defined $self->{current_row} );

}

sub has_changed {
    my $self = shift;

    #there is no child datasheet or child form in a datasheet (or ?)
    return $self->{changed};
}

sub _cell_clicked {
    my ( $self, $e ) = @_;
    my $pos = $e->GetRow;
    $self->{log}->debug( "_cell_clicked:  row " . $pos );
    $self->{current_row} = $pos;
    $self->{on_row_select}() if ( defined $self->{on_row_select} );

}

sub _row_selected {
    my ( $self, $e ) = @_;
    my $top = $e->GetTopRow;
    my $bot = $e->GetBottomRow;
    $self->{log}
        ->debug( "_row_selected top row: " . $top . " bottom row : " . $bot );
    if ( $top == $bot ) {
        $self->{current_row} = $top;
        $self->{on_row_select}() if ( defined $self->{on_row_select} );
    }    #else {
         #$self->{current_row} = undef;
         #}

}

#called after a change in the combo
# $combo -> $tree
# problem : if the first row in the combo is choosen without a click on it
# the event is not fired and the array combo_cur is not updated
sub _combo_edited {

    #my  ($self, $renderer, $path_string, $new_text) = @_;
    my ( $self, $id, $event ) = @_;

    # return unless ($tree);
    #  treeViewModel[path][columnNumber] = newText
    #  my $model =  $self->{treeview}->get_model;
    my $current_row = $self->GetGridCursorRow;
    $self->{log}->debug( "_combo_edited: current_row : " . $current_row );
    my $new_text = $event->GetString;

    #position dans le combo
    my $i = $event->GetSelection;

    #ensemble des id pour le combo
    my $aref = $self->{combo_id}->{$id};

    # die(Dumper $aref);
    my @a = @{$aref};
    $self->{log}->debug( "id: " . $id );
    $self->{log}->debug( "new value:  "
            . $new_text
            . " index: "
            . $i
            . " corresponding id : "
            . $a[$i] );

    #$self->{combo_cur}->{$id } = $a[$i];
    #update the array backing the combo column in the grid
    #$self->{combo_cur}->{$id}->[$current_row] = $a[$i];
    $self->{combo_cur}->[$current_row] = $a[$i];

    #	$cell->get("model");

}

sub get_data_manager {
    return shift->{dman};
}

sub _find_index {
    my ( $self, $what, @array ) = @_;

    #my( $found, $index ) = ( undef, -1 );
    my $index = -1;
    for ( my $i = 0; $i < @array; $i++ ) {
        if ( $array[$i] eq $what ) {

            # $found = $array[$i];
            $index = $i;
            last;
        }
    }
    return $index;

}

sub _is_combo {
    my ( $self, $col_no ) = @_;
    my @field = @{ $self->{fields} };
    my $ed    = $field[$col_no]->{renderer};

    #$self->{log}->debug(" found : " . ( defined $ed ? $ed : " undef"));
    return ( defined $ed && $ed eq "combo" );
}

#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

#
#https://github.com/jmlynesjr/wxPerl-Module-Examples/blob/master/wxGridTable.pl
#http://docs.wxwidgets.org/trunk/classwx_grid.html
#http://wiki.wxperl.it/Wx::GridTableBase
#
package  Wx::Perl::DbLinker::DBGridTable;
use Wx qw(:everything);

use Wx::Grid;
use base qw(Wx::PlGridTable);
#use Carp qw(croak confess carp);
# use Data::Dumper;

#the datamanager holding data from the database populate the grid
#data in the grid are stored in $$self{array}[$row][$col]
#for combo diplaying strings and returning numeric id to the database, the strings displayed are stored
#it's up to the apply method in the grid object to retrieve the correspond numeric id

sub new {
    my ( $class, $args ) = @_;
    my $self = $class->SUPER::new;
    #$self->{log} = Log::Log4perl->get_logger(__PACKAGE__);
    $self->{log} = Log::Any->get_logger;
    $self->{log}->debug("new called");
    $self->{dman}   = $args->{dman};
    $self->{fields} = $args->{fields};
    $self->{grid}   = $args->{grid};
    $self->{cols}   = scalar @{ $self->{fields} }
        ; #here cols holds the number of fields ... in Wxdatasheet it's an ar of the fields names
    $self->{coldata} = [];
    $self->{array}   = [];
    $self->{rows}    = $self->{dman}->row_count();

    #$self->{log}->debug(Dumper($self->{grid}));
    for my $i ( 0 .. $self->{rows} - 1 ) {
        $self->{dman}->set_row_pos($i);
        my $col = 0;
        for my $f ( @{ $self->{fields} } ) {
            my $fname = $f->{name};
            $self->{log}->debug(" row: ", $i , " name : ", $fname); #: ", (defined $v ? $v : " undef"));
            #RdbDataManager crash when looking for a calculated field that does not exists in the table
            my $v     = $self->{dman}->get_field($fname) unless $f->{renderer_function};
            $$self{array}->[$i][ $col++ ] = $v;
        }

    }
    return $self;

}

sub GetNumberCols {
    my ($self) = @_;

    # $self->{log}->debug("GetNumberCols: ", $self->{cols});
    return $self->{cols};
}

sub GetNumberRows {
    my ($self) = @_;

#$$self{log}->debug("GrigTable-GNR called");
#mais il y a la ligne des labels...mais grid->GetNumberRows ne la compte pas non plus
    return $self->{rows};
}

sub IsEmptyCell {
    my ( $self, $row, $col ) = @_;
    return defined $self->GetValue( $row, $col ) ? 1 : 0;
}

#DB -> grid
#previously entered value not yet saved -> grid
sub GetValue {
    my ( $self, $row, $col ) = @_;
    my $result = undef;

    if ( $row < $self->GetNumberRows && $col < $self->GetNumberCols ) {
        my $aref = $$self{array}->[$row];

#$self->{log}->debug("GetValue : " . $row . " " . $col . " array : " . (defined $aref ? " defined " : " undef") );
        if ( defined $$self{array}->[$row] )
        {    #retourner $result s'il a ete attribue par SetValue
            $result = $$self{array}->[$row][$col];
        }
        else {
           confess( $self->{log}->error("array undef"));
        }

        my $fname = $self->{fields}[$col]->{name};

#$self->{log}->debug("GetValue: ", (defined $result? $result: " undef"), " Field: ", $fname, " row: ", $row, " col: ", $col);

    }
    else {
        carp($self->{log}->warn( "Index out of bound in DBGridTable: " . $row . " : " . $col ));
    }

    $result = '' unless defined $result;

    return $result;
}

# user -> grid
sub SetValue {
    my ( $self, $row, $col, $value ) = @_;

#$self->{log}->debug ("SetValue GNR: " . $self->GetNumberRows . " pos to add to is " . $row) ;
    confess($self->{log}->error("Array out of bounds too much rows"))
        unless ( $row < $self->GetNumberRows );
     confess($self->{log}->error("Array out of bounds too much cols"))
        unless ( $col < $self->GetNumberCols );

    my $fname = $self->{fields}->[$col]->{name};

#$self->{log}->debug("SetValue row : ", $row, " col: ", $col, " field: ", $fname , " value: ", (defined $value ? $value : " undef"));

#fait dans apply ... !
#D'autant plus que $value est la valeur affichee par un combo et non l'id correspondant
#$self->{dman}->set_row_pos($row);
#    $self->{dman}->set_field($fname, $value);

    $$self{array}->[$row][$col] = $value;
}

=for comment
sub GetPlData_todel {
    my ( $self, $row, $col ) = @_;
    return undef
      unless ( $row < $self->GetNumberRows
        && $col < $self->GetNumberCols
        && defined $$self{array}->[$row][$col] );
    return $$self{array}->[$row][$col]->GetPlData;
}

sub SetPlData_todel {
    my ( $self, $row, $col, $data ) = @_;

    $self->{log}->logcroak("Array out of bounds")
      unless ( $row < $self->GetNumberRows && $col < $self->GetNumberCols );
    $$self{array}->[$row][$col]->SetPlData($data);
}

sub CanSetValueAs_todel {
    my ( $self, $row, $col, $type ) = @_;
    $self->{log}->debug("CanSetValueAs called with type $type");
    return 1 if ( $row < $self->GetNumberRows && $col < $self->GetNumberCols );
    return 0;
}

sub CanGetValueAs_todel {
    my $self = shift;
    return $self->CanSetValueAs(@_);
}
=cut

sub SetColLabelValue {
    my ( $self, $col, $value ) = @_;
    $col = $self->_checkCol($col);
    return unless defined $col;
    $$self{coldata}->[$col]->{label} = $value;
}

sub _checkCol {
    my ( $self, $col ) = @_;
    my $cols = $self->GetNumberCols;

    #return undef unless defined $col && abs($col) < $cols;
    return unless defined $col && abs($col) < $cols;
    return $cols + $col if $col < 0;
    return $col;
}

sub GetColLabelValue {
    my ( $self, $col ) = @_;
    $col = $self->_checkCol($col);

    #return undef unless defined $col;
    return unless defined $col;
    return $$self{coldata}->[$col]->{label};
}

sub SetRowLabelValue {    # Modeled after the wiki for custom labels
    my ( $grid, $row, $value ) = @_;
    $row = $grid->_checkRow($row);
    return unless defined $row;
    $$grid{rowdata}->[$row]->{label} = $value;
}

sub GetRowLabelValue {    # Modeled after the wiki for custom labels
    my ( $grid, $row ) = @_;
    $row = $grid->_checkRow($row);

    #return undef unless defined $row;
    return unless defined $row;
    return $$grid{rowdata}->[$row]->{label};
}

sub _checkRow {           # Modeled after the wiki for custom labels
    my ( $grid, $row ) = @_;
    my $rows = $grid->GetNumberRows;

    #return undef unless defined $row && abs($row) < $rows;
    return unless defined $row && abs($row) < $rows;
    return $rows + $row if $row < 0;
    return $row;
}

sub GetColLabelWidth {
    my ( $self, $col ) = @_;
    $col = $self->_checkCol($col);

    #return undef unless defined $col;
    return unless defined $col;
    return $$self{coldata}->[$col]->{width};
}

sub SetColLabelWidth {
    my ( $self, $col, $width ) = @_;
    $col = $self->_checkCol($col);
    return unless defined $col;
    $$self{coldata}->[$col]->{width} = $width;
}

=for comment
# this makes perl crash ...
sub SetView {
	my ($self, $grid) = @_;
	$self->{grid} = $grid;
} 
=cut

sub GetView {
    my $self = shift;

    #$self->{log}->debug("GetView: " . Dumper($self->{grid}));
    return $self->{grid};
}

=for comment
sub SetAttr_todel {
    my ( $self, $attr, $row, $col ) = @_;
    $row = $self->_checkRow($row);
    $col = $self->_checkCol($col);
    return unless ( defined $row && defined $col );
    $$self{array}->[$row][$col]->SetAttr($attr);
    return;
}
=cut

sub SetColAttr {
    my ( $self, $attr, $col ) = @_;
    $col = $self->_checkCol($col);
    return unless defined $col;
    $$self{coldata}->[$col]->{attr} = $attr;
    return;
}

=for comment
sub GetAttr_todel {
    my ( $self, $row, $col ) = @_;
    $row = $self->_checkRow($row);
    $col = $self->_checkCol($col);
    return undef unless ( defined $row && defined $col );
    my $attr = $$self{array}->[$row][$col]->GetAttr;
    return defined $attr ? $attr : $self->GetColAttr($col);
}
=cut

sub GetColAttr {
    my ( $self, $col ) = @_;
    $col = $self->_checkCol($col);
    return undef unless defined $col;
    return $$self{coldata}->[$col]->{attr};
}

#Appends one or more new rows to the bottom of the grid.
sub AppendRows {
    my ( $self, $rows_add ) = @_;
    $rows_add = 1 unless defined $rows_add && $rows_add >= 0;
    return 0 if $rows_add == 0;
    eval {
        my $pos = $self->GetNumberRows;

        #pour toutes les x positions a ajouter
        # en partant de la premiere
        my $last = $pos + $rows_add;

        for ( my $row = $pos; $row < $last; $row++ ) {

            #  creer des cellules vides
            $$self{array}->[$row] = $self->_newRow($row);
        }
        $$self{rows} += $rows_add;

        if ( my $grid = $self->GetView ) {
            $self->{log}->debug("AppendRows");
            my $msg =
                Wx::GridTableMessage->new( $self,
                wxGRIDTABLE_NOTIFY_ROWS_APPENDED, $rows_add );
            $grid->ProcessTableMessage($msg);
        }
    };
    if ($@) {
        $self->{log}->error("DBGridTable::AppendRows Exception: $@");
        return 0;
    }
    return 1;
}

sub _newRow {
    my ( $self, $pos ) = @_;
    $self->{log}->debug("_newRow");
    my $row = [];
    for ( my $col = 0; $col < $$self{cols}; $col++ ) {

        #    $$row[$col] = DBGridCell->new;
        $$row[$col] = undef;
        $self->{log}->debug( "_new_row: set to undef " . $row . " " . $col );
        $self->setup_empty_row($pos);
    }
    return $row;

}

sub DeleteRows {
    my ( $self, $pos, $rows ) = @_;
    return 0
        unless defined $rows
        && $rows >= 0
        && defined $pos
        && $pos >= 0
        && $pos < $$self{rows};
    if ( $pos + $rows < $$self{rows} ) {
        for ( my $row = $pos; $row < $pos + $rows; $row++ ) {
            delete $$self{array}->[$row];

            $$self{array}->[$row] = $$self{array}->[ $row + $pos ];
        }
        $$self{rows} -= $rows;
    }
    else {
        $rows = $$self{rows} - $pos if $$self{rows} < $pos + $rows;
        delete @{ $$self{array} }[ $pos .. $rows ];
        $$self{rows} -= $rows;
    }
    if ( my $grid = $self->GetView ) {
        my $msg =
            Wx::GridTableMessage->new( $self, wxGRIDTABLE_NOTIFY_ROWS_DELETED,
            $pos, $rows );
        $grid->ProcessTableMessage($msg);
    }
    return 1;
}

sub setup_empty_row {
    my ( $self, $r ) = @_;
    my $grid = $self->GetView;
    for my $field ( @{ $grid->{fields} } ) {
        my $col = $grid->{colname_to_number}->{ $field->{name} };

        if ( ref $field->{editor} eq "Wx::GridCellChoiceEditor" ) {
            $grid->SetCellEditor( $r, $col, $field->{editor} );

#my $id = $grid->GetCellValue($r, $col);
# $val est le array ref des id
#my $val = $grid->{combo_id}->{ $field->{name} };
#$pos et l'index de id dans ce vecteur
#my $pos = $self->_find_index($id, @$val);
# $text est le text a afficher dans la cellule à la place du id
#my $text = $self->{combo_val}->{$field->{name} }->[$pos];
# combo_cur contient l'id de la derniere ligne affichee de la grid
# $self->{combo_cur}->{$field->{name}} = $self->{combo_id}->{ $field->{name} }->[$pos];
# $self->{log}->debug( $field->{name}, " id: ", $id, " text: ", $text);
#$self->{combo_cur}->{ $field->{name} } est un array ref des id sous-jacents aux lignes affichees
#my $aref = $self->{combo_cur}->{ $field->{name} };
#push @$aref, $id;
            $grid->SetCellOverflow( $r, $col, 0 );

            #  $self->SetCellValue($r, $col, $text);
        }
        else {
            $grid->SetCellRenderer( $r, $col, $field->{editor} );
            $self->{log}->debug(
                "set cell renderer ",
                ref $field->{editor},
                " row: ", $r, " col: ", $col
            );

        }
        if ( $field->{editor_ro} ) {
            $grid->SetReadOnly( $r, $col, 1 );
        }

    }    #for fields

}

1;
__END__

=pod

=head1 NAME

Wx::Perl::DbLinker::Wxdatasheet -  a module that display data from a database in a tabular format using a WxGrid object

=head1 VERSION

See Version in 
L<Wx::Perl::DbLinker>

=head1 SYNOPSIS

The code build a table having 6 columns: 3 text entries, 2 combo, 1 toogle. A dataManager object is needed for each combo, and a dataManager for the table itself. The example here use Rose::DB::Object to access the tables.

This gets the RdbDataManager that will populate the datasheet 

    	my $datasheet_rows = Gtk2::Ex::DbLinker::DbcDataManager->new(
		rs => $self->{schema}->resultset('Speak')->search_rs(
			{langid => $self->{langid}, countryid => {'!=' => $self->{countryid} }}
								)
				); 


If the grid hold combo(s), the RdbDataManagers for those combo rows are created:

		 $combodata = Gtk2::Ex::DbLinker::DbcDataManager->new(
				rs => $self->{schema}->resultset('Country')->search_rs(undef, { order_by => 'country'} ),
			);
They will be passed as parameters when C< Wx::Perl::DbLinker::Wxdatasheet->new()> is called.

The Wxdatasheet object with the columns description is created:

	my $grid = Wx::Perl::DbLinker::Wxdatasheet->new( 
		parent_widget=>$scrolledwindow, 
		fields => [
				{name=>"countryid",
					renderer => "combo",	header_markup => "Country", data_manager=> $combodata, fieldnames => ["countryid", "country"],
					},	
				   {name=>"langid", renderer=>"hidden"},

		        	],
			after_update => => sub{ on_after_update($self, $self->{sf_list}->{dnav}, $list, "grid"); },
		borders_size => [20, 25], #horizontal: row_1: heigth, vertical : col_1: witdh

	    );

C<$scrolledwindow> is the widget that will received the grid. It is created before the grid creation:

       #$where_name is the name of the panel that will receive the grid
	my $where = Wx::Window::FindWindowById( Wx::XmlResource::GetXRCID($where_name), $top_panel );
	my $s = $where->GetSizer();
	$s = ( defined $s ? $s :  Wx::BoxSizer->new(wxVERTICAL));
	my $scrolledwindow = Wx::ScrolledWindow->new($where, wxID_ANY); #,    Wx::Point->new(0, 0), Wx::Size->new(400, 400),  wxVSCROLL | wxHSCROLL); 
	$scrolledwindow->SetScrollbars(1,1,1,1);
	$s->Add($scrolledwindow, 1, wxALL|wxEXPAND, 1);
	$where->SetSizer($s);

Once the grid has been created, it is added to C<$scrolledwindow>:

        $s = Wx::BoxSizer->new(wxVERTICAL);
	$scrolledwindow->SetSizer($s);
	$s->Add($grid, 1, wxALL|wxEXPAND, 1);

To change the rows displayed in the table, the new set of rows is fetched.  An object derived from Rose::DB::Object::Manager is passed to the Gt2::Ex::DbLinker::RdbDatamanager object using the query method:

	$grid->get_data_manager->query( $self->{schema}->resultset('Speak')->search_rs({langid => $new_value, countryid => {'!=' => $self->{countryid}} })  );
	$grid->update;

=head1 DESCRIPTION

This module automates the process of setting up a WxGrid based on field definitions you pass it. The first column show the state of the reccord : 
 - blank : unchanged
- ! : changed and not saved to the database
- x : mark for deletion
- o : locked


Steps for use:

=over

=item * 

Instanciate a xxxDataManager that will fetch a set of rows.

=item * 

Get a reference to the Wx::Pane that will received the grid, add a Wx::ScrolledWindow using sizer.

=item *

Create a xxxDataManager holding the rows to display, if the datasheet has combo box, create the corresponding DataManager that hold the combo box content.

=item * 

Create a Wxdatasheet object and pass it the following parameters: the scrolledwindow and a hash reference. The constructor return the Wx::Grid object that. Add the grid to the scrolledwindow using a sizer.

You would then typically connect some buttons to methods such as inserting, deleting, etc.

=back

=head1 METHODS

=head2 constructor

The C<new()> method expects a list of parameters name and value or a hash reference of  parameters name (keys) / value pairs.

The parameters are:

=over

=item *

C<parent_widget> a Wx::window object

=item * 

C<data_manager> a instance of a xxxDataManager object to populate the grid.

=item *

C<on_changed> a code ref that will be called when a value is changed in the grid

=item *

C<on_row_select> a code ref that will be called when a row is selected 

=item *

C<border_size> an array ref that holds the height of the field labels row and the width of the left column that displays the records state

=item *

C<fields> a reference to an array of hash. Each hash defined a field, and has the following key / value pairs:

=over

=item *

C<name> / name of the field to display.

=item *

C<renderer> / one of "text combo toggle hidden".

=item *

C<renderer_function> for text render, a coderef can be pass to set the cell value. The function will received the row and column number and the base table object.
For example, this method

		sub display_url {
			my ($self, $row, $col, $table) =@_;
	 		my $column_no = $self->{foo}->colnumber_from_name( "fooid" ); # the column where a value is taken from
			my $key_value = $table->GetValue($row, $column_no );
			my $result="";
			if ($key_value) {
				$result = "http://somewhere/on_the_internet/record.cgi?&fooid=" . $key_value;
			} 
	 		return $result;
		}

It can be passed to the Wxdatasheet constructor with

 		{ fields =>  [{name=>"bar", renderer=>"text"},
			{name=>"fooid"}, 
			{name=>"url", renderer=>"text", renderer_function => sub {display_url ($self, @_);}},
		             ], 
		  data_manager =>  ...
		  }


=back

if the renderer is a combo (Wx::ComboBox or Wx::ListBox) the following key / values are needed in the same hash reference:

=over

=item *

C<data_manager> / an instance holding the rows of the combo.

=item *

C<fieldnames> / a reference to an array of the fields that populate the combo. The first one is the return value that correspond to the field given in C<name>.

=back

=back

=head2 C<update();>

Reflect in the user interface the changes made after the data manager has been queried, or on the datasheet creation.

=head2 C<get_data_manager();>

Returns the data manager to be queried.

=head2 C<set_column_value($field_name, $value);>

Set $value in $field_name for the grid current row (where the cursor is).

=head2 C<get_column_value($field_name);>

Return the content of $field_name for the grid current row.

=head2 Methods applied to a row of data:

=over 

=item *

C<insert();>

Displays an empty rows.

=item *

C<delete();>

Marks the current row to be deleted. The delele itself will be done on apply.

=item *

C<apply();>

Create a new row in the DataManager and fetchs the values from the grid, and add this row to the database. Save changes on an existing row, or delete the row(s) marked for deletion. An array ref of fields name can be given to prevent these from being saved. This is usefull to change the row flag from modified to unmodif when the change are saved directly with the DataManager.

=item *

C<undo();>

Revert the row to the original state in displaying the values fetch from the database.

=back

=head1 SUPPORT

Any Wx::Perl::DbLinker questions or problems can be posted to me (rappazf) on my gmail account. 

The current state of the source can be extract using Mercurial from
L<http://sourceforge.net/projects/wx-perl-dblinker/>.

=head1 AUTHOR

FranE<ccedil>ois Rappaz <rappazf@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2016-2017 by FranE<ccedil>ois Rappaz.  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

