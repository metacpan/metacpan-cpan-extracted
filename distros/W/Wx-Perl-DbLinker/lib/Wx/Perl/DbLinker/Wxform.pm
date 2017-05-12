
package Wx::Perl::DbLinker::Wxform;
use Class::InsideOut qw(public private register id);
use Wx::Perl::DbLinker;
our $VERSION = $Wx::Perl::DbLinker::VERSION;

use strict;
use warnings;
use parent 'Gtk2::Ex::DbLinker::AbForm';

# use Carp qw(croak confess carp);
#use DateTime::Format::Strptime;
#use Data::Dumper;
use Scalar::Util qw( weaken );
use Wx qw[:everything];

#EVT_DATAVIEW_ITEM_VALUE_CHANGED
use Wx::Event
  qw[EVT_TEXT EVT_LIST_ITEM_SELECTED EVT_COMBOBOX EVT_LISTBOX &EVT_CHECKBOX EVT_RADIOBUTTON EVT_SPINCTRL  EVT_TEXT_ENTER];

#my %pos_seen;

my %signals = (

    'Wx::TextEntry'   => \&EVT_TEXT,
    'Wx::ComboBox'    => \&EVT_COMBOBOX,
    'Wx::CheckBox'    => \&EVT_CHECKBOX,
    'Wx::SpinCtrl'    => \&EVT_SPINCTRL,
    'Wx::TextCtrl'    => \&EVT_TEXT,
    'Wx::ListCtrl'    => \&EVT_LIST_ITEM_SELECTED,
    'Wx::ListBox'     => \&EVT_LISTBOX,
    'Wx::RadioButton' => \&EVT_RADIOBUTTON,
);

#
#coderef to place the value of record x in each field, combo, toggle...
#'Wx::DataViewListCtrl' => \&_set_combo,
my %setter = (
    'Wx::TextCtrl'    => \&_set_entry,
    'Wx::RadioButton' => \&_set_check,
    'Wx::ComboBox'    => \&_set_combo,
    'Wx::CheckBox'    => \&_set_check,
    'Wx::SpinButton'  => \&_set_spinbutton,
    'Wx::ListCtrl'    => \&_set_combo,
    'Wx::ListBox'     => \&_set_combo,

);

my %getter = (
    'Wx::TextCtrl' => sub { my ( $self, $w, $id ) = @_; return $w->GetValue; },
    'Wx::ToggleButton' =>
      sub { my ( $self, $w, $id ) = @_; return $w->GetValue; },
    'Wx::ComboBox' => sub {
        my ( $self, $w, $id ) = @_;
        return $self->_get_combobox_selectedvalue($id);
    },
    'Wx::ListBox' => sub {
        my ( $self, $w, $id ) = @_;
        return $self->_get_combobox_selectedvalue($id);
    },
    'Wx::CheckBox' => sub {
        my ( $self, $w, $id ) = @_;
        return $w->IsChecked;
    },
    'Wx::SpinButton' => sub {
        my ( $self, $w, $id ) = @_;
        return $w->IsChecked;
    },
    'Wx::ListCtrl' => sub {
        my ( $self, $w, $id ) = @_;
        $self->_get_combobox_selectedvalue($id);
    },

);

private log => my %log;
private event => my %events;
# private states => my %states;
private widgets => my %widgets;
private fields_with_event => my %ecols;
private is_with_event => my %is_ecols;
private datawidgets_value => my %datawidgets_value;
private datawidgets_pos => my %datawidgets_pos;
private combos => my %combos;

sub new {
    my $class = shift;

    #my $class, $req)=@_;
    my %def = (
        null_string     => "null",
        rec_spinner     => "RecordSpinner",
        status_label    => "lbl_RecordStatus",
        rec_count_label => "lbl_RecordCount",
        locale          => "fr_CH",
        auto_apply      => 1
    );

    my %arg = ( ref $_[0] eq "HASH" ? ( %def, %{ $_[0] } ) : ( %def, @_ ) );
   
    my $self = $class->SUPER::new(
        childclass           => __PACKAGE__,
         data_manager => $arg{data_manager},
        builder => $arg{builder},
        datawidgets => $arg{datawidgets},
        datawidgets_ro => $arg{datawidgets_ro},
        on_current => $arg{on_current},
        date_formatters => $arg{date_formatters},
        datawidgets_ro => $arg{datawidgets_ro},
        time_zone => $arg{time_zone},
        locale => $arg{locale},
        rec_spinner_callback => sub {
            my $self = shift;
             my $id = id $self;
            return unless $widgets{ $id }->{rec_spinner};
            $widgets{ $id }->{rec_spinner}->SetValue( $self->_pos + 1 );
        },
        rec_spinner_insert_callback => sub {
            my ( $self, $new_pos ) = @_;
             my $id = id $self;
            return unless $widgets{ $id }->{rec_spinner};
            my $first = ( $self->_pos < 0 ? 0 : 1 );
            $widgets{ $id }->{rec_spinner}->SetRange( $first, $new_pos + 1 );
            $widgets{ $id }->{rec_spinner}->SetValue( $new_pos + 1 );
        },
    );
    register $self;
     my $ido = id $self;
      delete @arg{ $self->_super_args_needed };
      # @$self{qw(dman cols ecols)} = delete @arg{qw(data_manager datawidgets datawidgets_changed)};
      #@$self{ keys %arg } = values(%arg);
        my $arg_holder_ref = { 
        rec_count_label => \$widgets{ $ido}->{rec_count_label},
        status_label => \$widgets{ $ido}->{status_label},
        rec_spinner => \$widgets{ $ido}->{rec_spinner},
        null_string => \$widgets{ $ido }->{ null_string },
        on_change => \$events{ $ido }->{on_change},
        data_lock => \$events{ $ido }->{data_lock},
        datawidgets_changed => \%ecols,

    } ;
      for my $name (keys %{$arg_holder_ref}){
        next unless defined ($arg{$name});

        if (ref $arg_holder_ref->{$name} eq "HASH"){
           $arg_holder_ref->{$name}->{ $ido } = $arg{$name};

        } 
        #elsif (ref $arg_holder_ref->{$name} eq "ARRAY") {

        #} 
        else {
            ${ $arg_holder_ref->{$name} } =  $arg{$name};
        
        }
    
    }
    # bless $self, $class;

    #$self->{cols} = [];
    $self->_init;
    $self->SUPER::_init;
=for comment
    my @dates;

    # $self->{subform} = [];

    #my %formatters_db;
    #my %formatters_f;
    # $self->{dates_formatted} = \(keys %{$self->{date_formatters}});
    foreach my $v ( keys %{ $self->{date_formatters} } ) {
        $log{ $id }->debug( "** " . $v . " **" );
        push @dates, $v;
    }
    $self->{dates_formatted} = \@dates;
    my %hdates = map { $_ => 1 } @dates;
    $self->{hdates_formatted} = \%hdates;
    $self->{dates_formatters} = {};

    $self->{pos2del}   = [];
    $self->{inserting} = 0;

=cut
        return $self;
}    #new

sub _get_setter { my $self = shift; return %setter; }
sub _get_getter { my $self = shift; return %getter; }

sub _init {

    my ($self) = @_;
     my $id = id $self;
    $self->_painting(1);

# get a ref to the Gtk widget used for the record spinner or if the id has been guiven, get the ref via the builder
    $widgets{ $id }->{rec_spinner} = (
        ref $widgets{ $id }->{rec_spinner}
        ? $widgets{ $id }->{rec_spinner}
        : $self->_builder()->get_object( $widgets{ $id }->{rec_spinner} ) );
    $widgets{ $id }->{rec_count_label} = (
        ref $widgets{ $id }->{rec_count_label}
        ? $widgets{ $id }->{rec_count_label}
        : $self->_builder()->get_object( $widgets{ $id }->{rec_count_label} ) );
    $widgets{ $id }->{status_label} = (
        ref $widgets{ $id }->{status_label}
        ? $widgets{ $id }->{status_label}
        : $self->_builder()->get_object( $widgets{ $id }->{status_label} ) );

    $log{ $id } = Log::Log4perl->get_logger(__PACKAGE__);
    $log{ $id }->debug(" ** New Form object ** ");
    $self->_changed(0);
=for comment
    if ( !defined $self->{cols} ) {
        my @col = $self->{dman}->get_field_names;
        $self->{cols} = \@col;
        $log{ $id }->debug( "_init cols: " . join( " ", @col ) );
    }
=cut
    # $self->{hecols} = {};
    #  if ( defined $ecols{ $id } ) {
    if ( $ecols{ $id } ) {
        # my %is_ecol;
        my @fields = keys %{ $ecols{ $id } };
        for (@fields) { 
            ${ $is_ecols{ $id } }{$_}++; 
        }
        #  $self->{hecols} = \%is_ecol;
        $log{ $id }->debug( "datawidgets_changed: " . join( " ", @fields ) );

    }

    $self->_bind_on_changed;
    $self->_set_recordspinner;
    $log{$id }->logcroak("A data manager is required")
      unless ( defined $self->_dman );
    $self->_dman->set_row_pos(0);
}

#dman must contains all the rows
# $self->{datawidgetsValue} contient la valeur selectionnee pour Wx::ListCtrl
# mais pour Wx::ComboBox il contient une ref au hash des id (col 0) et leur position dans le combo
# ClientData ne sert a rien ?
#
#renvoyer un hash de la col 0/index dans tous les cas ?

#add the values contained in the array @$aref in the combo $name
#the combo has to a Wx::ComboBox
#set the hash ref of row# => id in $self->{datawidgetsValue}->{$field}
#set the hash ref of id => row# in $self->{datawidgetsPos}->{$field}

sub add_combo_values {

    my ( $self, $w, $aref, $name ) = @_;
 my $id = id $self;
    # $log{ $id }->debug( "build_list $name\n");
    my $wref       = ref $w;
    my @supp_class = (qw/Wx::ComboBox Wx::ListBox/);
    my %supported  = map { $_ => 1 } @supp_class;
    $log{$id }->logconfess(
        "only " . join( " ", @supp_class ) . " supported by add_combo_values" )
      unless ( $supported{$wref} );

    my $size = 0;
    if   ( defined $aref->[0] ) { $size = scalar( @{ $aref->[0] } ); }
    else                        { $aref = []; }

    # die ($size);
    my ( @row_val, $col_i, %ids, %idpos );

    # my $lst = Gtk2::ListStore->new(@{ $self->{lists}->{$name}->{glib} });
    my $i_pos = 0;
    foreach my $row (@$aref) {

        # push @row_val, $lst->append;
        #  print "Data: $row->[0]\n";
        my $display;

        for ( $col_i = 0 ; $col_i < $size ; $col_i++ ) {
            if ( $col_i == 0 ) {

#push @ids, $row->[$i];
# $log{ $id }->debug("add_combo_values val:" . $row->[$col_i] . " index: " . $i_pos);
                $ids{$i_pos} = $row->[$col_i];
                $idpos{ $row->[$col_i] } = $i_pos;

            } else {

                # push @model, $i, $row->[$i];
                $display .= $row->[$col_i] . " ";
            }
        }

        #push @row_val, $display; # if ($pos == $lastcol);
        $w->Append($display);
        $i_pos++;
    }
    # $self->{datawidgetsValue}->{$name} = \%ids;
    $datawidgets_value{ $id }->{$name} =\%ids;
    #$self->{datawidgetsPos}->{$name}   = \%idpos;
    $datawidgets_pos{ $id }->{$name} = \%idpos;

    #$log{ $id }->debug("dwV: \n" . Dumper(%ids));
    #$log{ $id }->debug("dvP: \n" . Dumper(%idpos));

}

#set the hash ref of row# => id in $self->{datawidgetsValue}->{$field}
#set the hash ref of id => row# in $self->{datawidgetsPos}->{$field}
#set the combo's datamanager in $self->{comboDman}->{$field}
sub add_combo {

    #my ($self, $req)=@_;
    my $self = shift;
    my $id = id $self;
    my %def = ( init => 1 );
    my %h;
    my $req = ( ref $_[0] eq "HASH" ) ? $_[0] : ( %h = ( %def, @_ ) ) && \%h;
    my $combo = {
        dman   => $$req{data_manager},
        id     => $$req{id},
        fields => $$req{fields},
        init   => $$req{init} || 1,

    };

    my $column_no = 0;
    my @cols;
    if ( defined $combo->{fields} ) {
        @cols = @{ $combo->{fields} };
    } else {
        @cols = $combo->{dman}->get_field_names;

    }

    #my @list_def;
    if ( $$req{builder} && ( ref $self eq "" ) ) {    #static init

        $self = {};
        $self->_builder($$req{builder});

        $log{ $id } = Log::Log4perl->get_logger(__PACKAGE__);

        my $w = $self->_builder()->get_object( $combo->{id} );
        if ($w) {

            #my $name = $w->get_name;
            my $name = ref $w;

            #$name =~s/::/_/g;
            $log{ $id }
              ->debug( "name: " . $name . "  widget->GetName: " . $w->GetName );
            $self->_datawidgets($combo->{id}, $w);
            $self->_datawidgetsName( $combo->{id}, $name);
        } else {
            $log{ $id }->debug( "cols: " . join( " ", @cols ) );
            $log{$id }->logconfess( "no widget found for combo " . $combo->{id});
        }
    }

    $log{ $id }->debug( "cols: " . join( " ", @cols ) );
    my $w = $self->_datawidgets( $combo->{id} );
    $log{$id }->logconfess( 'no widget found for combo ' . $combo->{id} ) unless ($w);

    $w->Clear;

    #my @col = @{$self->{cols}};
    $log{$id }->logcroak("no fields found for combo $combo->{id}") unless (@cols);
    my $lastfield = @cols;

    #the column to show is either the first (pos 0) if it's the only column or
    #the first ( and the next )

    #my $displayedcol = ($lastfield > 1 ? 1 : 0);
    #$w->set_text_column( $displayedcol );
    #my $model = $w->get_model;

    my $column = 0;
    my $last;

    #Name is the Wx::XXXX kind of object
    my $name = $self->_datawidgetsName($combo->{id});

    #my %idpos;
    my $itemCol;

    my %ids;
    my %idpos;
    my @values;
    foreach my $field (@cols) {

        #$allrows[$i]=[];

        if ( $name eq "Wx::ListCtrl" ) {
            $itemCol = Wx::ListItem->new;
            $itemCol->SetText($field);
            my $size = ( $column == 0 ? 0 : 180 );
            $itemCol->SetWidth($size);

            $w->InsertColumn( $column, $itemCol );

        }    #elsif ($name eq "Wx::DataViewListCtrl") {
             #$w->AppendTextColumn($field);

        #}

        $last = $combo->{dman}->row_count - 1;

        # my $currid;
        #my @allrows;
        # die $last if ($combo->{id} eq "lstDates");
        for ( my $i = 0 ; $i <= $last ; $i++ ) {

            #$row = $d->column_accessor_value_pairs;

            $combo->{dman}->set_row_pos($i);
            my $value = $combo->{dman}->get_field($field);

            #die $value  if ($combo->{id} eq "lstDates");
            #push @{$allrows[$i]}, $value if ($name eq "Wx::DataViewListCtrl");

            if ( $column == 0 ) {
                $ids{$i}       = $value;
                $idpos{$value} = $i;

                if ( $name eq "Wx::ListCtrl" ) {
                    $w->InsertStringItem( $i, $value );
                } elsif (
                    !( $name eq "Wx::ComboBox" || $name eq "Wx::ListBox" ) )
                {
                    $log{$id }->logconfess("add_combo: $name is not supported");
                }

      #else {$log{ $id }->error("add_combo: $name is not supported" ); return;}

            } else {

        #my $e = Wx::TextEntry;
        #$e->AutComplete(Completer);
        #$w->SetItem($index, $column,$value); #ajoute des elements dans la ligne

                if ( $name eq "Wx::ListCtrl" ) {
                    $w->SetItem( $i, $column, $value );
                    push @values, $value;
                } elsif ( $name eq "Wx::ComboBox" || $name eq "Wx::ListBox" ) {

                    #$w->SetString($i, $value);
                    $w->Append($value);

   #$log{ $id }->debug("add_combo col $column index:  $i value: $value");
   #$log{ $id }->debug("add_combo: ". $combo->{id} . " row: $i value: $value");
                }
            }

#$log{ $id }->debug("add combo: column $column index $i value $value cd: ". ($w->GetClientData($i) ? $w->GetClientData($i) : "undef"));
        }    #for rows

        #$column = ($column == 0 ? 1 : 0);
        $column++;
    }    #for each fields

    if ( $name eq "Wx::ComboBox" || $name eq "Wx::ListBox" ) {

        #$w->SetClientData(@idval);
        #$self->{datawidgetsValue}->{ $combo->{id} } = \%idpos;
        #$self->{datawidgetsValue}->{ $combo->{id} } = \%ids;
        $datawidgets_value{$id }->{ $combo->{id} } = \%ids;
        #$self->{datawidgetsPos}->{ $combo->{id} }   = \%idpos;
        $datawidgets_pos{ $id }->{ $combo->{id} }   = \%idpos;
        my $href = { fields => $combo->{fields}, dman => $combo->{dman}, };
        # $self->{combo}->{ $combo->{id} } ={ dman => $combo->{dman}, fields => \@cols };
        $combos{ $id } ={ dman => $combo->{dman}, fields => \@cols };

    }

    $log{ $id }->debug( "add_combo: " . $last . " rows added" );

#écrase le listener mis dans bind_changed
#EVT_LIST_ITEM_SELECTED($self->_builder()->get_object('mainwindow'), $w, sub {$self->_on_selected($combo->{id}, @_)});
    if ( $combo->{init} && $w->GetWindowStyleFlag & wxTE_PROCESS_ENTER ) {
        $log{ $id }->debug( "binding text enter for combo " . $combo->{id} );
        EVT_TEXT_ENTER( $self->_builder()->frame,
            $w, sub { $self->_on_combo_newval( $combo->{id}, @_ ) } );
    }

    #	if ($self->{datawidgetsName}->{$combo->{id}} eq "GtkComboBoxEntry" ){
    if ( $self->_datawidgetsName($combo->{id}) eq "Wx::ListCtrl" ) {

        #if ( ! $self->{combos_set}->{$combo->{id}} ) {
        #$w->set_text_column( 1 );
        #$self->{combos_set}->{ $combo->{id} } = TRUE;
        #}
        # my $entrycompletion = Gtk2::EntryCompletion->new;
        #$entrycompletion->set_minimum_key_length( 1 );
        #$entrycompletion->set_model( $model );
        #$entrycompletion->set_text_column( $displayedcol );
        #$w->get_child->set_completion( $entrycompletion );
        $w->GetEditControl->AutoComplete(@values);

    }

    return \%ids;
}    #sub

sub add_radio_button {
    my ( $self, $w, $coderef, $caller ) = @_;
    my $name   = ref $w;
    my $signal = $signals{$name};
    &$signal( $w, $w, sub { &$coderef( $caller, $w ); } );

}

#bind an onchanged sub with each modification of the datafields
sub _bind_on_changed {
    my $self = shift;
 my $ido = id $self;
    # my @cols = $self->{dman}->get_field_names;
    foreach my $id ( @{ $self->_cols } ) {
        my $w = $self->_builder()->get_object($id);
        $log{ $ido }->debug( "bind_on_changed looking for widget " . $id );
        if ($w) {

            # my $name = $w->GetName;
            my $name = ref $w;

            #$name =~s/::/_/g;
            $self->_datawidgets( $id, $w);
            $self->_datawidgetsName($id, $name);

            if ( ref( $signals{$name} ) eq "CODE" ) {

                my $coderef = $signals{$name};

#&$coderef($self->_builder()->get_object('mainwindow'), $w, sub{$self->_changed($id, $w, @_)});
                &$coderef( $self->_builder()->frame,
                    $w, sub { $self->_change_values( $id, $w, @_ ) } );

#mettre le widget lui meme comme premier arg entraine que la fonction est toujours executee
#meme si une autre fonction est attachee apres. Si le premier arg est toujours le meme, c'est la derniere
#fonction attachee qui est executee
#&$coderef($w, $w, sub{$self->_changed($id, $w, @_)});

            }
            $log{ $ido }->debug("bind  $name $id with self->changed");

    #$w->signal_connect_after( $signals{$name} => sub{ $self->_changed( $id )});
            die("signal undef for $name") unless ( $signals{$name} );

        } else {
            $log{ $ido }->debug(" ... not found ");
        }
    }

}

# Associe une fonction sur value_changed du record_spinner qui appelle move avec abs: valeur lue dans l'etiquette du recordspinner
# Place
sub _set_recordspinner {
    my $self = shift;
     my $id = id $self;
    $log{ $id }->debug("set_recordspinner");

    # die unless($widgets{ $id }->{rec_spinner});
    my $coderef;
    if ( $widgets{ $id }->{rec_spinner} ) {
        $coderef = sub {
            
            my $pos = $widgets{ $id }->{rec_spinner}->GetValue - 1;
            $log{ $id }->debug( "rs_value changed will move to " . $pos );

            #widgets{ $id }->{rec_spinner}->signal_handler_block( $coderef );
            #$self->move( undef, $pos);

            #confess ( $pos, " already seen") if ($pos_seen{$pos});
            # $pos_seen{$pos}++;

            if ( $self->_auto_apply && $self->has_changed ) { $self->apply; }

            # done in display data
            #$self->{dman}->set_row_pos($pos);
            $self->_display_data($pos);

            #$widgets{ $id }->{rec_spinner}->signal_handler_unblock( $coderef );
            # return 1;
        };

        EVT_SPINCTRL( $widgets{ $id }->{rec_spinner}, $widgets{ $id }->{rec_spinner}, $coderef );

# With this EVT_TEXT marcro, a change done with ->insert calls the code above
# EVT_TEXT($widgets{ $id }->{rec_spinner}, $widgets{ $id }->{rec_spinner}, $coderef);
# from http://docs.wxwidgets.org/trunk/classwx_spin_ctrl.html
# if the user modifies the text in the edit part of the spin control directly, the EVT_TEXT is generated,
# like for the wxTextCtrl. When the use enters text into the text area, the text is not validated until the control loses
# focus (e.g. by using the TAB key). The value is then adjusted to the range and a wxSpinEvent sent
# then if the value is different from the last value sent.
        #$self->{rs_value_changed_signal} = $coderef;
        $events{ $id }->{rs_value_changed_signal} = $coderef;
        weaken  $events{ $id }->{rs_value_changed_signal};
        $log{ $id }->debug("recordspinner set");
    }

}

sub _set_rs_range {
    my ( $self, $first, $last ) = @_;
 my $id = id $self;
    $log{ $id }->debug( "set_rs_range  first : " . $first );
    my $rowcount = $self->_dman->row_count;
    if ( $widgets{ $id }->{rec_spinner} ) {
        $widgets{ $id }->{rec_spinner}->SetRange( $first, $last );
    }

#Note that this function will not generate the wxEVT_COMMAND_TEXT_UPDATED event.
#$widgets{ $id }->{rec_count_label}->ChangeValue(" / " . $self->{dman}->row_count);
    $widgets{ $id }->{rec_count_label}->SetLabel( " / " . $rowcount );
    return 1;

}

sub _set_entry {
    my ( $self, $w, $x, $id ) = @_;
     my $ido = id $self;
    if ( defined $x ) {
        $log{ $ido }->debug( "set_entry: " . $x );

#$w->set_text( $x ) ;
# SetValue generates a wxEVT_TEXT event. To avoid this you can use ChangeValue() instead.
#$self->{hecols}->{$id} ? $w->SetValue($x) && $log{ $id }->debug("SetValue called") : $w->ChangeValue($x);
        $log{$id }->logconfess("id undef") unless ( defined $id );
        #if ( $self->{hecols}->{$id} ) {
        if ( $is_ecols{ $ido }->{$id} ) {
            $w->SetValue($x);

            #$log{ $id }->debug("SetValue called");
        } else {
            $w->ChangeValue($x);

            #$log{ $id }->debug("ChangeValue called");
        }
    } else {
        $log{ $ido }->debug( "set_entry: text entry undef " . $w->GetName );

        #$w->set_text("");
        #$self->{hecols}->{$id} ? $w->Clear : $w->ChangeValue("");
        $is_ecols{ $ido }->{$id} ? $w->Clear : $w->ChangeValue("");

        #$w->ChangeValue("");
    }

#$log{ $id }->debug("hecols : ". ($self->{hecols}->{$id} ? $self->{hecols}->{$id} : "undef") . " for " . $id );

}

sub _set_textentry {
    my ( $self, $w, $x, $id ) = @_;
    $log{ id $self }->debug("set_textentry text entry undef") if ( !defined $x );
    $w->WriteText( $x || "" );

}

# DB -> combo
# $x : $value received from the DB
# $id corresponding index
sub _set_combo {
    my ( $self, $w, $x, $id ) = @_;
 my $ido = id $self;
#return unless (defined $x); the combo must be unselect from the preceding value
    my $name = $self->_datawidgetsName($id);
    $log{ $ido }->debug( "set_combo value "
          . ( defined $x ? $x : " undef" )
          . " widget: "
          . $name . " id: "
          . $w->GetName );
    if ( $name eq "Wx::ListCtrl" ) {

        #print "value: $x selected : ", $w->GetSelectedItemCount, "\n";

        my $item = $w->FindItem( -1, $x );

        $w->SetItemState( $item, wxLIST_STATE_SELECTED, wxLIST_STATE_SELECTED );
    } elsif ( $name eq "Wx::ComboBox" || $name eq "Wx::ListBox" ) {
        $log{$id }->logconfess( "undef datawidgetsPos  for ", $id )
        unless ( $datawidgets_pos{ $ido }->{$id} );
        #unless ( $self->{datawidgetsPos}->{$id} );
        #my %idpos = %{ $self->{datawidgetsPos}->{$id} };
        my %idpos = %{ $datawidgets_pos{ $ido }->{$id} };

        my $i = $idpos{$x} if ( defined $x );
        $log{ $ido }
          ->debug( "_set_combo pos is " . ( defined $i ? $i : " undef" ) );

        # $w->SetSelection(wxNOT_FOUND);
        if ( defined $i ) {
            $w->SetSelection($i);
        } else {
            $w->SetSelection(wxNOT_FOUND);
        }

        # $log{ $id }->debug($w->GetStringSelection);

    }
}

sub _set_check {
    my ( $self, $w, $x, $id ) = @_;
    $w->SetValue($x);
}

#$comboid is the combo id and the field name in the table that received the value selected in the combo
# $field[1] is the name of the field that is displayed in the combo
# $field[0] is the field name of the values returned from the combo
sub _on_combo_newval {
    my ( $self, $comboid, $frame, $event ) = @_;
     my $id = id $self;
    my $value = $event->GetString;
    $log{ $id }->debug( "combo_newval: " . $value );
    $value = ( $value eq "" ? undef : $value );
    return unless ( defined $value );
    my $href   = $combos{ $id }->{$comboid};
    my $dman   = $href->{dman};
    my @fields = @{ $href->{fields} };
    $dman->new_row;
    $dman->set_field( $fields[1], $value );
    $dman->save;
    $self->add_combo(
        {
            data_manager => $dman,
            fields       => $href->{fields},
            id           => $comboid,
            init         => 0
        }
    );
}

sub _get_combobox_selectedvalue {
    my ( $self, $id ) = @_;
     my $ido = id $self;
    $log{$id }->logconfess("id undef") unless ( defined $id );
   
    my $w    = $self->_datawidgets( $id );
    my $name = $self->_datawidgetsName( $id );
    my $x;

    if ( $name eq "Wx::ListCtrl" ) {
        $x =
          (   $datawidgets_value{ $ido }->{$id}
            ? $datawidgets_value{ $ido }->{$id}
            : undef );
    } elsif ( $name eq "Wx::ComboBox" || $name eq "Wx::ListBox" ) {

        my $pos = $w->GetSelection();

        #die ((($pos == wxNOT_FOUND) ? "not": "") . " found");
        #$log{ $id }->debug ("id : ", $id, " pos ", $pos);
        #$log{ $id }->debug(  $self->{datawidgetsValue}->{$id}->{$pos});

        $x =
          ( $pos == wxNOT_FOUND )
          ? undef
          : $datawidgets_value{ $ido }->{$id}->{$pos};

    }
    $log{ $ido }->debug( "_get_combobox_selectedvalue: found "
          . ( defined $x ? $x : " undef" ) );
    return $x;
}

sub _set_spinbutton {
    my ( $self, $w, $x ) = @_;
     my $id = id $self;
=for comment
    if ( $self->getID($w) eq $self->getID( $widgets{ $id }->{rec_spinner} ) ) {
        $log{ $id }->debug("Found record_spinner... leaving");
        return;
    }
=cut
    $w->SetValue( $x || 0 );

}

sub _change_values {
    my ( $self, $fieldname, $w, $frame, $event ) = @_;
 my $id = id $self;
    #my $name = ref $w;
    my $name = $self->_datawidgetsName($fieldname);
    $log{ $id }->debug("self->changed for $fieldname ($name)");
    die ("$fieldname without type") unless defined $name;
    if ( $name eq "Wx::ListCtrl" ) {
        print "text: ", $event->GetText, "Index: ", $event->GetIndex, "Data: ",
          $event->GetData, "\n";
        $datawidgets_value{ $id }->{$fieldname} = $event->GetText;

    }
    if ( $is_ecols{ $id }->{$fieldname} ) {
        my $coderef = $ecols{ $id }->{$fieldname};
        &$coderef( $w, $event );
    }
    if ( !$self->_painting ) {
        $self->_changed(1);
        if ( $events{$id}->{on_change} ) {
            $events{$id}->{on_change}();
        }
        $self->_set_record_status_label;
    }
    return 0;

}

sub _on_selected {
    my ( $self, $id, $list, $event ) = @_;
 my $ido = id $self;
#print Dumper $self;
#print "_on_selected: name: ", ref $list, "\n";
#print "text: " , $event->GetText, "Index: ", $event->GetIndex, "Data: ", $event->GetData, "\n";
    if ( $self->_datawidgetsName( $id  ) eq "Wx::ListCtrl" ) {
        $datawidgets_value{ $ido }->{$id} = $event->GetText;
    } else {
        $log{$id }->logcroak(  "_on_selected not implemented for $id ("
              . $self->_datawidgetsName($id)
              . ")" );
    }

}

sub _set_record_status_label {

    my $self = shift;
 my $id = id $self;
 # $log{ $id }->debug("set_record_satus_label changed is " . $self->_changed);

    if ( $widgets{ $id }->{status_label} ) {
        if ( $events{ $id }->{data_lock} ) {
            $widgets{ $id }->{status_label}->SetLabel("Locked");
        } elsif ( $self->_changed ) {

            $widgets{ $id }->{status_label}->SetLabel("Changed");

        } else {
            $widgets{ $id }->{status_label}->SetLabel("Synchronized");
        }
    }
}

#return an hashref of line number => first column value
sub get_combo_ids{
    my $self = shift;
    my $id = id $self;
    my $combo_id = shift;
    return $datawidgets_value{ $id }->{$combo_id};
}

1;

__END__

=head1 NAME

Wx::Perl::DbLinker::Wxform - a module that display data from a database in a Wx widgets user interface described in a xrc file.

=head1 VERSION

See Version in L<Wx::Perl::DbLinker>

=head1 SYNOPSIS

	use Rdb::Coll::Manager;
	use Rdb::Biblio::Manager;

	use Gtk2::Ex::DbLinker::RdbDataManager;
	use Wx::Perl::DbLinker::Wxform;

	use Wx qw[:everything];
	use Wx::XRC;

	 $self->{xrc} = Wx::XmlResource->new();
	 $self->{xrc}->InitAllHandlers();
         $self->{xrc}->Load($path_to_xrc_file) or die(....);

	 $self->{frame} = $self->{xrc}->LoadFrame(undef, 'mainwindow'});



This gets the Rose::DB::Object::Manager (we could have use plain sql command, or DBIx::Class object instead), and the DataManager object we pass to the form constructor.

	my $data = Rdb::Mytable::Manager->get_mytable(query => [pk_field => {eq => $value]);

	my $dman = Gtk2::Ex::DbLinker::RdbDataManager->new(data=> $data, meta => Rdb::Mytable->meta );

This create the form.

		$self->{form_coll} = Wx::Perl::DbLinker::Wxform->new(
			data_manager => $dman,
			builder => 	$builder,
		  	rec_spinner => $self->{dnav}->get_object('RecordSpinner'),
	    		status_label=>  $self->{dnav}->get_object('lbl_RecordStatus'),
			rec_count_label => $self->{dnav}->get_object("lbl_recordCount"),
			on_current =>  sub {on_current($self)},
			date_formatters => {
				field_id1 => ["%Y-%m-%d", "%d-%m-%Y"], 
				field_id2 => ["%Y-%m-%d", "%d-%m-%Y"], },
			time_zone => 'Europe/Zurich',
			locale => 'fr_CH',
	    );

C<$builder> is an object that has a C<get_object($name)> method described below and frame method that return the main frame.

C<rec_spinner>, C<status_label>, C<rec_count_label> are Gtk2 widget used to display the position of the current record. See one of the example 2 files in the examples folder for more details. 
C<date_formatters> receives a hash of id for the Gtk2::Entries in the Glade file (keys) and an arrays (values) of formating strings.

In this array

=over

=item *

pos 0 is the date format of the database.

=item * 

pos 1 is the format to display the date in the form. 

=back

C<time_zone> and C<locale> are needed by Date::Time::Strptime.



To display new rows on a bound subform, connect the on_change event to the field of the primary key in the main form.
In this sub, call a sub to synchonize the form:

In the main form:

    sub on_nofm_changed {
        my $widget = shift;
	my $self = shift;
	my $pk_value = $widget->get_text();
	$self->{subform_a}->synchronize_with($pk_value);
	...
	}

In the subform_a module

    sub synchronize_with {
	my ($self,$value) = @_;
	my $data = Rdb::Product::Manager->get_product(with_objects => ['seller_product'], query => ['seller_product.no_seller' => {eq => $value}]);
	$self->{subform_a}->get_data_manager->query($data);	
	$self->{subform_a}->update;
     }

=head2 Dealing with many to many relationship 

It's the sellers and products situation where a seller sells many products and a product is selled by many sellers.
One way is to have a insert statement that insert a new row in the linking table (named transaction for example) each time a new row is added in the product table.

An other way is to create a data manager for the transaction table

With DBI

	$dman = Gtk2::Ex::DbLinker::DbiDataManager->new( dbh => $self->{dbh}, sql =>{select =>"no_seller, no_product", from => "transaction", where => ""});

With Rose::DB::Object

	$data = Rdb::Transaction::Manager->get_transaction(query=> [no_seller => {eq => $current_seller }]);

	$dman = Gtk2::Ex::DbLinker::RdbDataManager->new(data => $data, meta=> Rdb::Transaction->meta);

And keep a reference of this for latter

      $self->{linking_data} = $dman;

If you want to link a new row in the table product with the current seller, create a method that is passed and array of primary key values for the current seller and the new product.

	sub update_linking_table {
	   	my ( $self, $keysref) = @_;
   		my @keys = keys %{$keysref};
		my $f =  $self->{main_form};
		my $dman = $self->{main_abo}->{linking_data};
		$dman->new_row;
		foreach my $k (@keys){
			my $value = ${$keysref}{$k};
			$dman->set_field($k, $value );
		}
		$dman->save;
	}

This method is to be called when a new row has been added to the product table:

	sub on_newproduct_applied_clicked {
		my $button = shift;
	 	my $self = shift;
    		my $main = $f->{main_form};
    		$self->{product}->apply;
		my %h;
		$h{no_seller}= $main->{no_seller};
		$h{no_product}= $self->{abo}->get_widget_value("no_product");
    		$self->update_linking_table(\%h);
	}

You may use the same method to delete a row from the linking table

	my $data = Rdb::Transaction::Manager->get_transaction(query=> [no_seller => {eq => $seller }, no_product=>{eq => $product } ] );
	$f->{linking_data}->query($data);
	$f->{linking_data}->delete;

=head1 DESCRIPTION

This module automates the process of tying data from a database to Wx widgets form described by a xrc file.
Name the widgets in the xrc file using the fields in your data source.

Steps for use:

=over

=item * 

Create a xxxDataManager object that contains the rows to display

=item * 

Create a builder object with a get_object($name) method

=item * 

Create a Wx::Perl::DbLinker::Wxform object that links the data and your form

=item *

You would then typically connect the buttons to the methods below to handle common actions
such as inserting, moving, deleting, etc.

=back

=head1 METHODS

=head2 constructor

The C<new();> method expects a list of parameter name => value or a hash reference of parameter name (key) / value pairs

The parameters are:

=over

=item * 

C<data_manager> a instance of a xxxDataManager object

=item *

C<builder> 

C<$builder> is an object that must have a C<get_object($object_name)> which is a wrapper around C<Wx::Window::FindWindowByName> and C<frame()> method that return the application main window (holds in C<$self->{frame}> below:

   sub get_object {
	my ($self, $id) = @_;
	my $w = Wx::Window::FindWindowByName($id, $self->{frame});
	$log{ $id }->debug("get_object: $id not found") unless (defined $w);
	return $w;
    }

=back

The following parameters are optional

=over

=item *

C<datawidgets> a reference to an array of id in the glade file that will display the fields

=item * 

C<rec_spinner> the name of a GtkSpinButton to use as the record spinner or a reference to this widget. The default is to use a
widget called RecordSpinner.

=item *

C<rec_count_label>  name (default to "lbl_RecordCount") or a reference to a label that indicate the position of the current row in the rowset

=item *  

C<status_label> name (default to "lbl_RecordStatus") or a reference to a label that indicate the changed or syncronized flag of the current row

=item *

C<on_current> a reference to sub that will be called when moving to a new record

=item * 

C<date_formatters> a reference to an hash of Gtk2Entries id (keys), and format strings  that follow Rose::DateTime::Util (value) to display formatted Date

=item * 

C<auto_apply> defaults to 1, meaning that apply will be called if a changed has been made in a widget before moving to another record. Set this to 0 if you don't want this feature

=item *

C<datawidgets_changed> is a hash ref having the field's name as keys and a code ref that will be called when the field content is changed.

		$self->{sform} = Wx::Perl::DbLinker::Wxform->new(
			...
			datawidgets_changed => {langid=> sub{ on_langid_changed(@_, $self) } },

		);

		sub on_langid_changed {
			my ($widget, $event, $self) = @_;
			my $value = $widget->GetLineText(0);
			if ($value) {
				$self->{langid} = $value;
				$self->{sf_list}->get_data_manager->query( $self->{schema}->resultset('Speak')->search_rs({langid => $value, countryid => {'!=' => $self->{countryid}} })  );
				$self->{sf_list}->update;
			}
		}

=item *

C<datawidgets_ro> is an array ref that gives the field's name that will be read-only.

=back

=head2 C<add_combo( data_manager =E<gt> $dman, 	id =E<gt> 'noed',  fields =E<gt> ["id", "nom"] ); >

Once the constructor has been called, combo designed in the xrc file received their rows with this method. 
Two Wx objects are supported Wx::ListCtrl and Wx::Combo.

C<return value> an array ref of the first field values is returned since in you have to retrieve the index of the selected row (holding nom values) to access the corresponding id

C<parameters> is a list of paramater name => value or a hash reference of key (parameter name) and value, and the parameters are:

=over

=item * 

C<data_manager> a dataManager instance that holds  the rows of the combo

=item *

C<id> the id of the widget in the xrc file

=item *

C<fields> an array reference holdings the names of fields in the combo (this parameter is needed with RdbDataManager only)

=back

=head2 C< Wx::Perl::DbLinker::Wxform-E<gt>add_combo( data_manager =E<gt> $combodata, id =E<gt> 'countryid',	builder =E<gt> $builder ); >

This method can also be called as a class method, when the underlying form is not bound to any table. You need to pass the builder object (described above) as a supplemental parameter.

=head2 C<get_combo_ids( $combo_name ); >

Return an hash ref of { line number =>  first column value } for combo_name. First line is 0.

=head2 C<update();> 

See L<Gtk2::Ex::DbLinker::AbForm/update()>

=head2 C<get_data_manager();>  

See L<Gtk2::Ex::DbLinker::AbForm/get_data_manager()>

=head2 C<set_data_manager( $dman ) > 

See L<Gtk2::Ex::DbLinker::AbForm/set_data_manager( $dman )>

=head2 C<get_widget_value ( $widget_id );>

Returns the value of a data widget from its id

=head2 C<set_widget_value ( $widget_id, $value )>;

Sets the value of a data widget from its id

=head2 Methods applied to a row of data

=over

=item C<insert()> See L<Gtk2::Ex::DbLinker::AbForm/insert()>

=item C<delete()> See L<Gtk2::Ex::DbLinker::AbForm/delete()>

=item C<apply()> See L<Gtk2::Ex::DbLinker::AbForm/apply()>

=item C<undo()> See L<Gtk2::Ex::DbLinker::AbForm/undo()>

=item C<next()>  See L<Gtk2::Ex::DbLinker::AbForm/Moving between rows>

=item C<previous()>  See L<Gtk2::Ex::DbLinker::AbForm/Moving between rows>

=item C<first()>  See L<Gtk2::Ex::DbLinker::AbForm/Moving between rows>

=item C<last()>  See L<Gtk2::Ex::DbLinker::AbForm/Moving between rows>

=item C<add_childform( $childform )> See L<Gtk2::Ex::DbLinker::AbForm/add_childform( $childform )>

=item C<has_changed()>  See L<Gtk2::Ex::DbLinker::AbForm/has_changed()>

=back

=head1 SUPPORT

Any Wx::Perl::DbLinker::Wxform questions or problems can be posted to me (rappazf) on my gmail account.  

The current state of the source can be extract using Mercurial from
L<http://sourceforge.net/projects/wx-perl-dblinker/>.

=head1 AUTHOR

FranE<ccedil>ois Rappaz <rappazf@gmail.com>

=head1 COPYRIGHT

Copyright (c) 2015-2017 by F. Rappaz.  All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

L<Gtk2::Ex::DbLinker> L<Gtk2::Ex::DbLinker::DbTools>.

=cut

1;


