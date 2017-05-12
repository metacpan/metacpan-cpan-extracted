
use strict;
use warnings;

package Wx_dnav;

use Wx qw[:everything];

#use base qw(Wx::Frame);
use Wx::XRC;

# use Wx::Perl::PubSub qw(:global);
#se Gtk2::Ex::DbLinker::DbiDataManager;
# use Data::Dumper;
use Wx::Perl::DbLinker::Wxdatasheet;
#use Carp qw( carp croak confess );
use Wx::Event qw(EVT_BUTTON EVT_MENU EVT_TEXT EVT_COMBOBOX);

my %refs     = map { $_, 1 } qw(Wx::Perl::DbLinker::Wxdatasheet Wxdatasheet);
my %ref_form = map { $_, 1 } qw(Wx::Perl::DbLinker::Wxform Wxform);

my %signals = (

    'Wx::TextEntry'   => \&EVT_TEXT,
    'Wx::ComboBox'    => \&EVT_COMBOBOX,
    'Wx::CheckBox'    => \&EVT_CHECKBOX,
    'Wx::SpinCtrl'    => \&EVT_SPINCTRL,
    'Wx::TextCtrl'    => \&EVT_TEXT,
    'Wx::ListCtrl'    => \&EVT_LIST_ITEM_SELECTED,
    'Wx::ListBox'     => \&EVT_LISTBOX,
    'Wx::RadioButton' => \&EVT_RADIOBUTTON,
    'Wx::Button'      => \&EVT_BUTTON,
);

sub new {
    my ( $class, $href ) = @_;

#my $self = $class->SUPER::new(undef, -1, "Titre", wxDefaultPosition, $$href{size});
    my $self->{log} = Log::Log4perl->get_logger(__PACKAGE__);
    $self->{w2hide} = [];
    $self->{size}   = $href->{size};
    $self->{ismain} = ( defined $href->{ismain} ? $href->{ismain} : 1 );

    bless $self, $class;

    if ( $self->{ismain} ) {
        my $path = $INC{"Wx_dnav.pm"};
        $path =~ s/\/Wx_dnav.pm//;
        $path = $self->_get_path( $path, $href->{main_file} );

        #$path = $href->{main_file};
        $self->{xrc} = Wx::XmlResource->new();
        $self->{xrc}->InitAllHandlers();
        $self->{xrc}->Load($path) or $self->{log}->logconfess("Can't load $path");
        $self->{frame} = $self->{xrc}->LoadFrame( undef, $href->{main_name} );
        $self->{frame}->SetSize( $self->{size} );

        #die unless (defined $href->{dbh});
        my $dbh;
        if ( defined $href->{schema} ) {
            $dbh = $href->{schema}->storage->dbh;
        }
        elsif ( defined $href->{dbh} ) {
            $dbh = $href->{dbh};
        }
        if ($dbh) {

            #my ($name ) = ($href->{dbh}->{Name}=~/database=(.*);/);

            $self->show_tables(
                sql =>
                    "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%'",
                dbh       => $dbh,
                mibuilder => $href->{mibuilder},
            );

            #$self->show_querries($href->{dbh});
        }

    }
    else {

        $self->{frame} = $href->{frame};
    }

    # my $f = $self->{xrc}->LoadFrame(undef, 'mainwindow');
    # $self->signal_connect();

    $self->{w2disable} = [];
    $self->{w2enable}  = [];

#connect an empty sub to the buttons, so that the functions bind to the buttons of the same name in the
#frames on top do not percolate to the current buttons
    $self->{events_callback} = {
        "b_add"    => \&on_add_clicked,
        "b_delete" => \&on_delete_clicked,
        "b_undo"   => \&on_undo_clicked,
        "b_apply"  => \&on_apply_clicked
    };

    for my $name ( keys %{ $self->{events_callback} } ) {
        my $b = $self->get_object($name);
        last unless ($b);
        my $sub_ref = $self->{events_callback}->{$name};
        EVT_BUTTON( $self->{frame}, $b, sub { } );
    }
    $self->{buttons} = {};
    return $self;
}

sub set_form {
    my ( $self, $form ) = @_;

    # show_all($self);
    $self->{log}->logcroak("No instance found for set_form") unless ($form);

#if ($dataref->isa('Gtk2::Ex::Datasheet::DBI') || $dataref->isa('Linker::Datasheet')){
    $self->{form} = $form;
    my $ref = ref $form;
    if ( $refs{$ref} ) {
        $self->{ismain} = 0;
        push @{ $self->{w2hide} },
            (
            $self->get_object('RecordSpinner'),
            $self->get_object('lbl_RecordCount'),
            $self->get_object('lbl_RecordStatus')
            );
    }
    else {

        $self->{log}->debug("$ref not found with set_form")
            unless ( $ref_form{$ref} );

    }

    #die(Dumper($self));
    $self->signal_connect;

}

sub signal_connect {
    my ($self) = @_;

#$self->{events_id}={};
#$self->{events_callback}={"b_add" => \&on_add_clicked, "b_delete"=> \&on_delete_clicked, "b_undo"=>\&on_undo_clicked, "b_apply"=>\&on_apply_clicked};
#my $xid = \&Wx::XmlResource::GetXRCID;

    #$self->{m_tables} = &$xid('m_menuTables');
    for my $name ( keys %{ $self->{events_callback} } ) {

# there is no way to disconnect with the macro
#my $id = EVT_BUTTON( $self->{frame}, $self->{$n}, sub{ &$self->{events_callback}->{$n}($self, @_) } );
        my $b       = $self->get_object($name);
        my $sub_ref = $self->{events_callback}->{$name};
        EVT_BUTTON( $self->{frame}, $b, sub { \&$sub_ref( $b, $self ) } );
    }

}

#argument: dans l'ordre
#- panel de destination dans le widget tree
#-chemin du fichier xrc
#-widget au sommet de la hierarchie dans le fichier xrc
#
sub load_panel {
    my ( $self, $where_name, $path, $top_name, $col ) = @_;

    my $where;
    my $xrc = Wx::XmlResource->new;
    $xrc->InitAllHandlers();

    # $path = $self->_get_path($path);
    $xrc->Load($path) or $self->{log}->logconfess("Can't load xrc file from $path");
    my $top_from_xrc;

    $where = Wx::Window::FindWindowByName( $where_name, $self->{frame} );

    #print Dumper($where);

    $self->{log}->logconfess("Can't locate $where_name in wigdets tree") unless ($where);

    #this load top_name ?
    my $p = $xrc->LoadPanel( $where, $top_name )
        ; #  || Wx::Window::FindWindowById( Wx::XmlResource::GetXRCID($top_name) );
    if ( defined $col ) { $where->SetBackgroundColour($col); }

#$p = Wx::Window::FindWindowById( Wx::XmlResource::GetXRCID($top_name) ) unless($p);
#my $p = $top_from_xrc;
    $self->{log}->logconfess("Can't load $top_name") unless ($p);
    my $s = Wx::BoxSizer->new(wxVERTICAL);

    #$s->Layout();
    $s->Add( $p, 1, wxALL | wxEXPAND, 1 );
    $where->SetSizer($s);

    # $self->{top_panel} = $where;
    return $where;

}

#load_grid allow to reuse the same xrc file in one application since dest_name (name of the top panel in the xrc file to be included)
#could already be in set in the hierarchy. top_panel is used to limit the search of dest_name in the hierarchy
#datasheet_param are the parameters to the Wxdatasheet constructor.
#
sub load_grid {
    my ( $self, $argref ) = @_;
    $self->{log}->logconfess(
        "Argument for loa_grid must be a hash with keys top_panel, dest_name, datasheet_param"
        )
        unless ( ref $argref eq "HASH"
        && defined $argref->{top_panel}
        && defined $argref->{dest_name}
        && defined $argref->{datasheet_param} );
    my $top_panel  = $argref->{top_panel};
    my $where_name = $argref->{dest_name};
    my $href       = $argref->{datasheet_param};
    my $where =
        Wx::Window::FindWindowById( Wx::XmlResource::GetXRCID($where_name),
        $top_panel );
    $self->{log}->logconfess( "Can't find any object named ",
        $where_name, " to place the grid into" )
        unless ($where);

    $where->SetBackgroundColour( $$argref{bg} ) if ( $$argref{bg} );

    my $s = $where->GetSizer();
    $s = ( defined $s ? $s : Wx::BoxSizer->new(wxVERTICAL) );
    my $sw = Wx::ScrolledWindow->new( $where, wxID_ANY )
        ; #,    Wx::Point->new(0, 0), Wx::Size->new(400, 400),  wxVSCROLL | wxHSCROLL);
    $sw->SetScrollbars( 1, 1, 1, 1 );
    $self->{log}->logconfess("Can't create sizer or scrolled window") unless ( $s && $sw );
    $s->Add( $sw, 1, wxALL | wxEXPAND, 1 );
    $where->SetSizer($s);
    $s = Wx::BoxSizer->new(wxVERTICAL);
    $sw->SetSizer($s);
    my %arg = ( parent_widget => $sw, (%$href) );
    my $grid = Wx::Perl::DbLinker::Wxdatasheet->new( (%arg) );
    $s->Add( $grid, 1, wxALL | wxEXPAND, 1 );
    $self->{log}->debug("load_grid done");
    return $grid;

}

sub b_save_clicked {
    my ( $self, $frame, $event ) = @_;
    $frame->FindWindow( $self->{b_apply} )->SetLabel('Clicked');
}

sub m_tables_clicked {
    my ( $self, $frame, $event ) = @_;
    Wx::MessageBox( "tables clicked", "Info" );

}

sub connect_signal_for {
    my ( $self, $wname, $sub_ref, $data ) = @_;
    my $w = $self->get_object($wname);
    $self->{log}->logcroak(
        "Dnav connect_signal_for failed since no widget instance exists for $wname"
    ) unless ($w);
    my $name   = ref $w;
    my $signal = $signals{$name};
    # print Dumper($name);
    &$signal( $self->{frame}, $w, sub { &$sub_ref( $w, $data, @_ ); } );

}

sub add_widgets2hide {
    my ( $self, @allnames ) = @_;
    foreach my $n (@allnames) {
        $self->{log}->debug("add_w2h:  $n\n");
        push @{ $self->{w2hide} }, $self->get_object($n);
    }
}

sub frame {
    my ( $self, @args ) = @_;
    if (@args) {
        $self->{frame} = $args[0];
    }
    else {
        return $self->{frame};
    }

}

sub list_children {
    my ( $self, $w, $pad ) = @_;
    $w = ( defined $w ? $w : $self->{frame} );
    $self->{log}
        ->debug( $pad . "children: " . $w->GetName . " ref: " . ( ref $w ) );
    my @list = $w->GetChildren;
    $pad .= " ";
    if (@list) {
        for my $v (@list) {
            $self->list_children( $v, $pad );

        }
    }  

}

sub get_object {
    my ( $self, $id, $from_panel ) = @_;
    my $start = ( $from_panel ? $from_panel : $self->{frame} );
    #$self->{log}->debug( "searching from start: ", $start->GetName );
    my $w = Wx::Window::FindWindowByName( $id, $start );
    #$self->{log}->debug("get_object: $id not found") unless ( defined $w );
    return $w;

}

sub on_add_clicked  { my ( $b, $self ) = @_; $self->{form}->insert; }
sub on_undo_clicked { my ( $b, $self ) = @_; $self->{form}->undo; }

sub on_delete_clicked {
    my ( $b, $self ) = @_;
    $self->{log}->debug("in Wx_dnav...\n");
    $self->{form}->delete;
}

sub on_apply_clicked {
    my ( $b, $self ) = @_;
    $self->{log}->debug("in Wx_dnav...\n");
    $self->{form}->apply;
}

sub show_tables {
    my $self = shift;
    my %arg  = @_;
    my $sth = $arg{dbh}->prepare( $arg{sql} );
    $sth->execute;
    my $menubar = $self->{frame}->GetMenuBar;
    my $menu = $menubar->GetMenu( $menubar->FindMenu('Table') );

    while ( my @row = $sth->fetchrow_array() ) {
        $self->{log}->debug( " menu table: " . $row[0] );
        EVT_MENU(
            $self->{frame},
            $menu->Append( -1, $row[0] ),
            sub {
                $self->display_tbl(
                    name      => $row[0],
                    dbh       => $arg{dbh},
                    mibuilder => $arg{mibuilder}
                );
            }
        );
    }

}

sub display_tbl {
    my $self = shift;
    my %arg  = @_;
    my $data;
    if ( $arg{name} ) {
        $data = $arg{mibuilder}->(%arg);
    }
    my $f = Wx_dnav->new(
        {   ismain    => 1,
            size      => $self->{size},
            main_name => 'mainwindow',
            main_file => '../xrc/main.xrc'
        }
    );
    $f->load_panel( 'mainwindow', 'xrc/nav.xrc', 'm_dnav_panel' );

    my $param = {
        top_panel       => $f->{frame},
        dest_name       => "m_panel_for_content",
        datasheet_param => { data_manager => $data, }
    };

    my $grid = $f->load_grid($param);
    $f->show_all_except(
        [qw(m_menubar1 lbl_RecordCount RecordSpinner lbl_RecordStatus)] );
    $f->set_form($grid);

}

sub show_querries {
    my ( $self, $dbh ) = @_;
    my $q    = Config::YAML::Tiny->new( config => "querries.txt" );
    my $i    = $q->{items};
    my $mb   = $self->{frame}->GetMenuBar;
    my $menu = $mb->GetMenu( $mb->FindMenu('Querries') );
    die unless ($menu);
    foreach my $n (@$i) {
        my $href;
        if ( $n->{pk} ) {
            $self->{log}->debug( "pk ", $n->{pk} );
            chomp( $n->{sql} );
            $self->{log}->debug( "sql ", $n->{sql} );
            $href = {
                dbh             => $dbh,
                ai_primary_keys => [ $n->{pk} ],
                sql             => {
                    select   => $n->{sql},
                    from     => $n->{tbl},
                    order_by => $n->{oby}
                }
            };
        }
        else {
            $href = { dbh => $dbh, sql => { pass_through => $n->{sql} } };
        }

        EVT_MENU(
            $self->{frame},
            $menu->Append( -1, $n->{menu} ),
            sub { display_tbl( $self, $href ); }
        );
    }

}

sub show_all_except {
    my ( $self, $ar_ref ) = @_;
    my $w = $self->{frame};

    $w->Show;
    foreach my $name (@$ar_ref) {
        my $w = $self->get_object($name);
        if ( !defined $w ) {
            if ( ref $self->{frame} eq "Wx::Frame" ) {
                $w = $self->{frame}->GetMenuBar;
                if ( ref $w eq "Wx::MenuBar" ) {    #masque les menu
                    my $count = $w->GetMenuCount();
                    for ( my $i = 0; $i < $count; $i++ ) {
                        $w->SetMenuLabel( $i, '' );
                    }
                }
            }
        }
        $self->{log}->debug(
            "hiding "
                . (
                $w ? $name : " but can't cause undefined object with $name"
                )
        );
        $w->Hide if ( defined $w );
    }
    foreach my $w ( @{ $self->{w2hide} } ) {
        $self->{log}->debug( "hiding : ", $w->GetName, "\n" );
        $w->Hide if ($w);
    }

}

sub widgets_set_sensitivity {

    my ( $self, $val ) = @_;
    for my $w ( @{ $self->{w2disable} } ) {

    }
    $self->{log}
        ->debug( "set_sensitivity " . ( defined $val ? $val : " undef" ) );
    for my $w ( @{ $self->{w2disable} } ) {
        $w->Enable($val);
        $self->{log}->debug( ( $val ? " en" : " dis" ). "abling ". $w->GetName);
    }

}

sub set_sensitivity_for {
    my ( $self, $id ) = @_;
    my %buttons = %{ $self->{buttons} };
    #$self->{log}->debug( "buttons ", Dumper(%buttons) );
    my $w;
    if ( $buttons{$id} ) {
        $w = $buttons{$id};
    }
    else {
        $w = $self->get_object($id);
    }
    $w->Enable(1);

}

sub list_parent {
    my ( $self, $w ) = @_;
    return unless $w;
    $self->{log}
        ->debug( "list_parent ", $w->GetName, " is_enabled ", $w->IsEnabled );
    $self->list_parent( $w->GetParent );

}

#the array ref of control to disable is stored here and not in the calling module
#$keepit is a array ref of widgets name not to disable
#
#

sub populate_widgets {
    my ( $self, $w, $keepit, $no_warn ) = @_;
    $self->{log}->debug( "populate widgtets "
            . $w->GetName
            . " ref: "
            . ( ref $w )
            . " isa control "
            . ( UNIVERSAL::isa( $w, 'Wx::Window' ) ? " true" : " false" ) )
        ; #, " ", ( $w->isa('Gtk2::Container') ? " is a container" : " is not a container"), "\n";
    $self->{log}->logcroak("widget undefined") unless $w;

    my %widgets_enabled = map { $_, 1 } @{$keepit};
    my %class           = map { $_, 1 }
        qw(Wx::TextCtrl Wx::ComboBox Wx::ListBox Wx::Button Wx::SpinCtrl Wx::Static::Text Wx::CheckBox Wx::SpinButton);

    return unless ( UNIVERSAL::isa( $w, 'Wx::Window' ) );
    my @c = $w->GetChildren;
    if ( !defined $no_warn && scalar @c == 0 ) {
        $self->{log}->logcarp(
            "populate_widgets received a container widget without any children");
    }
    for my $c ( $w->GetChildren ) {
        my $id   = $c->GetName;
        my $name = ref $c;

        if ( $c->IsEnabled() && $name ne "Wx::BoxSizer" && $id ne "" ) {
            unless ( $widgets_enabled{$id} ) {

                if ( $name eq 'Wx::SpinButton' || $name eq 'Wx::Button' ) {
                    $self->{buttons}->{$id} = $c;
                    $self->{log}->debug( "Added to buttons href ", $id );

                }
                push @{ $self->{w2disable} }, $c if ( $class{$name} );
            }
        }
        $self->populate_widgets( $c, $keepit, 1 );
    }
}

sub _get_path {
    my ( $self, $path, $file_name ) = @_;

    if ( $ENV{PAR_TEMP} ) {
        $path = $ENV{PAR_TEMP} . "/inc/lib/" . $file_name;

        #$path = $ENV{PAR_TEMP}. "/inc/" ."glade/dnav.bld";
    }
    else {
        $path = $path . "\\" . $file_name;

        #$path = "dnav.xrc";
    }

    return $path;
}

1;
