package Forms::Sflang;

use strict;
use warnings;

use Wx::Perl::DbLinker::Wxform;

#use Gtk2::Ex::DbLinker::SqlADataManager;
use Data::Dumper;
use Wx_dnav;

=for comment
The value comming from langid is used to display a combo and is also stored in a text field named langid1 in the xrc file.
The text field trigger a change event when records are navigate in the subform, but the combo does not.
The event is used to update the grid
=cut

use Wx qw[:everything];

sub new {
    my $class = shift;

    # , $href ) = @_;

    my %arg = ref $_[0] eq "HASH" ? %{ $_[0] } : (@_);
    my $self;
    @$self{qw(dnav_top)} = delete @arg{qw(dnav)};
    @$self{ keys %arg } = values(%arg);

    $self->{log} = Log::Log4perl->get_logger(__PACKAGE__);
    $self->{log}->debug(" new form ");

    my $top_panel = $self->{dnav_top}->load_panel( $self->{panel_to}, 'xrc/nav.xrc', 'm_dnav_panel' );

    my $path = $self->{xrcfolder} . "\\subform.xrc";
    $self->{dnav} = Wx_dnav->new( { ismain => 0, frame => $top_panel } );

    $self->{dnav}->load_panel( "m_panel_for_content", $path, "m_panel1" );
    $self->{dnav}->frame->SetBackgroundColour(wxLIGHT_GREY);

    $self->{dnav}->populate_widgets( $top_panel, [qw(b_add)] );
    # $self->{dnav}->list_children($top_panel);

    bless $self, $class;
    my $dman =
        $self->{data_broker}->get_DM_for( 'subform_data', [ $self->{countryid} ] );

    $self->{sform} = Wx::Perl::DbLinker::Wxform->new(
        data_manager        => $dman,
        builder             => $self->{dnav},
        auto_apply          => 0,
        datawidgets         => [qw(countryid langid langid1)],
        rec_spinner         => $self->{dnav}->get_object('RecordSpinner'),
        status_label        => $self->{dnav}->get_object('lbl_RecordStatus'),
        rec_count_label     => $self->{dnav}->get_object("lbl_RecordCount"),
        datawidgets_ro      => [qw(langid1)],
        datawidgets_changed => {
            langid1 => sub { on_langid1_changed( @_, $self ) }
        },
        on_current => sub { $self->{log}->debug("on_current from Subform");
            $self->update_widgets_sensitivity( $self->{dnav}, $dman );
        },
    );

    # on_after_update( $self, $self->{dnav}, $dman, "form" );
    my $combodata = $self->{data_broker}->get_DM_for('langue');
    $self->{sform}->add_combo(
        data_manager => $combodata,
        id           => 'langid',
        builder      => $self->{dnav},
    );

    #fields => [qw(langid langue)],

    $self->{sform}->get_data_manager->set_row_pos(0);
    $self->{langid} = $self->{sform}->get_data_manager->get_field('langid1');

    my $list = $self->{data_broker}
        ->get_DM_for( 'grid_data', [ $self->{langid}, $self->{countryid} ] );

#set up the datasheet
#$top_panel = $self->{dnav}->load_panel('m_panel_for_grid', 'xrc/nav.xrc', 'm_dnav_panel');
    $top_panel = $self->{dnav}->load_panel( 'm_panel_for_grid', 'xrc/nav.xrc', 'm_dnav_panel', wxCYAN );

    $self->{sf_list}->{dnav} =
        Wx_dnav->new( { ismain => 0, frame => $top_panel } );
    $self->{sf_list}->{dnav}->populate_widgets( $top_panel, [qw(b_add)] );

    $combodata = $self->{data_broker}->get_DM_for('mainform_data');
    my $dsparam = {
        data_manager => $list,
        fields       => [
           
            {   name          => "countryid",
                renderer      => "combo",
                header_markup => "Country",
                data_manager  => $combodata,
                fieldnames    => [ "countryid", "country" ],
            },
            { name => "langid", renderer => "hidden" },

        ],
        after_update => =>
            sub { $self->{log}->debug("after_update from grid");
                $self->update_widgets_sensitivity( $self->{sf_list}->{dnav}, $list ); },

    };

    #  on_after_update( $self, $self->{sf_list}->{dnav}, $list, "grid" );
    $self->{grid} = $self->{dnav}->load_grid(
        {   bg              => wxCYAN,
            top_panel       => $top_panel,
            dest_name       => "m_panel_for_content",
            datasheet_param => $dsparam
        }
    );
    # this connect the undo function form Wxform to the undo button
    # in the subform (and the apply, delete, add from Wxform, but these
    # will be writen over with the connect_signal_for calls below )
    #
    $self->{dnav}->set_form( $self->{sform});
 
    $self->{deleting} = 0;
    $self->{lst_deleting} = 0;
    $self->{grid}->update;
    $self->{sform}->add_childform( $self->{grid} );

    #  die ref $self->{data_broker};
    #     
    my %connect_for = (
        'DataAccess::Sqla::Service' => {
            b_add    => \&on_add_clicked,
            b_delete => \&on_delete_clicked,
            b_apply  => \&on_apply_clicked,
         
        },
        'DataAccess::Dbi::Service' => {
            b_add    => \&on_add_clicked,
            b_delete => \&on_delete_clicked,
            b_apply  => \&on_apply_clicked,
        },
        'DataAccess::Rdb::Service' => {
            b_add    => \&on_add_clicked,
            b_delete => \&on_delete_clicked,
            b_apply  => \&on_apply_2_clicked,
        },
        'DataAccess::Dbc::Service' => {
            b_add    => \&on_add_clicked,
            b_apply  => \&on_apply_2_clicked,
        },
    );
    #Dbc:  b_delete => \&on_delete_clicked,
    my $sign_ref = $connect_for{ ref $self->{data_broker} };

    for my $button ( keys %{$sign_ref} ) {
        $self->{dnav}
            ->connect_signal_for( $button, $sign_ref->{$button}, $self );
    }

    # this connect the undo function form Wxdatasheet to the undo button
    # in the dnav grid (and the apply, delete, add from Wxdatasheet, but these
    # will be writen over with the connect_signal_for calls below )
    #
    
    $self->{sf_list}->{dnav}->set_form( $self->{grid} );
    %connect_for = (
        'DataAccess::Sqla::Service' => { b_add => \&on_add_lst_clicked },
        'DataAccess::Sqla::Service' => { b_apply => \&on_apply_lst_clicked },
        'DataAccess::Dbi::Service'  => { b_add => \&on_add_lst_clicked },
        'DataAccess::Rdb::Service' => { b_add => \&on_add_lst_clicked },
        'DataAccess::Dbc::Service'  => { b_add => \&on_add_lst_clicked },
    );

    $sign_ref = $connect_for{ ref $self->{data_broker} };
    for my $button ( keys %{$sign_ref} ) {
         $self->{sf_list}->{dnav}
            ->connect_signal_for( $button, $sign_ref->{$button}, $self );
    }
    $self->{dnav}->show_all_except( [qw(langid1 countryid)] );
    $self->{sform}->update;
    return $self;

}

sub on_countryid_changed {
    my ( $self, $value ) = @_;
    my $dman;
    if ( !defined $value || $value eq "" ) {
        $self->{langid} = undef;
        $self->{dnav}->widgets_set_sensitivity( $self->{widgets}, 0 );

    }
    else {
        return if ( $value == $$self{countryid} );
        $self->{log}->debug("countryid_changed countryid : $value");
        $self->{countryid} = $value;
        $dman = $self->{sform}->get_data_manager;
        $self->{data_broker}->query_DM( $dman, 'subform_data', [$value] );
        $self->{data_broker}
            ->query_DM( $dman, 'subform_data', [$value] );

        #$self->{log}->debug("query in subform returned : " . $test);
        $self->{sform}->update;
        $value = $self->{sform}->get_widget_value("langid");
        $self->{log}
            ->debug( "langid: " . ( defined $value ? $value : " undef" ) );
        if ( $value != $self->{langid} ) {

            $self->{log}->debug("countryid_changed langid $value");

            $self->{data_broker}->query_DM( $self->{grid}->get_data_manager,
                'grid_data', [ $value, $self->{countryid} ] );
            $self->{grid}->update;
        }

        if ($dman) {
            $self->{log}->debug( "row count ", $dman->row_count );
            $self->update_widgets_sensitivity( $self->{dnav}, $dman );
        }
        else {
            $self->{log}->debug("dman undef");
        }

    }

}


sub on_langid1_changed {
    my ( $b, $e, $self ) = @_;
    $self->{log}->debug( "langid1_changed current values  countryid: "
            . ( defined $self->{countryid} ? $self->{countryid} : " undef" )
            . " langid: "
            . ( defined $self->{langid} ? $self->{langid} : " undef" ) );

    #print Dumper($b);
    my $value = $b->GetLineText(0);
    $value = ( defined $value && $value eq "" ? undef : $value );
    if ( defined $value && $value != $self->{langid} )
    {    #query and update are called only when langid changes
        $self->{log}->debug("langid : $value");
        $self->{langid} = $value;

        $self->{data_broker}->query_DM( $self->{grid}->get_data_manager,
            'grid_data', [ $value, $self->{countryid} ] );
        $self->{grid}->update;

    }
    elsif ( !defined $value ) {
        $self->{log}->debug("setting langid to undef");
        $self->{langid} = undef;

        $self->{data_broker}->query_DM( $self->{grid}->get_data_manager,
            'grid_data', [ $value, $self->{countryid} ] );
        $self->{grid}->update;
    }

}

sub on_delete_clicked {
    my ( $b, $self ) = @_;
    $self->{sform}->delete;
    $self->{deleting} = 1;
}

sub on_add_clicked {
    my ( $b, $self ) = @_;
    $self->{sform}->insert;
    $self->{sform}->set_widget_value( "countryid", $self->{countryid} );
    $self->{adding} = 1;
    $self->{dnav}->set_sensitivity_for("langid");
    $self->{dnav}->set_sensitivity_for("b_apply");

}

sub on_apply_clicked {
    my ( $b, $self ) = @_;
    $self->{log}
        ->debug( "sform_apply deleting in sf is ", $self->{deleting} );

    if ( $self->{deleting} ) {
        $self->{sform}->apply;
        $self->{sform}->update;
        $self->{deleting} = 0;
        return;

    }
    my $value = $self->{sform}->get_widget_value('langid');
    my @pks   = $self->{sform}->get_data_manager->get_primarykeys;

    # modification of an existing record or addition of a new row
    #

    my $c = $self->{sform}->get_widget_value('countryid');
    return unless ( $c ne "" );
    $self->{log}->debug( "sform_apply country : "
            . $self->{countryid}
            . " langue : "
            . $value );

    #$self->{sform}->set_widget_value("langid1", $value);
    $self->{langid} = $value;
    my %h = ( countryid => $self->{countryid}, langid => $self->{langid} );

    # $self->{sform}->apply;

    $self->{sform}->get_data_manager->save(%h);

    $self->{sform}->apply( \@pks );

    $self->{data_broker}->query_DM( $self->{sform}->get_data_manager,
        'subform_data', [ $self->{countryid} ] );
    $self->{sform}->update;

    $self->{data_broker}->query_DM( $self->{grid}->get_data_manager,
        'grid_data', [ $value, $self->{countryid} ] );
    $self->{grid}->update;
}

sub on_apply_2_clicked {
    my ( $b, $self ) = @_;
    $self->{log}->debug("apply_2");
    my $c = $self->{sform}->get_widget_value('countryid');
    return unless ( $c ne "" );
    my $value = $self->{sform}->get_widget_value('langid');
    $self->{log}->debug( "sform_apply country : "
            . $self->{countryid}
            . " langue : "
            . $value );
    $self->{sform}->set_widget_value( "langid1", $value );
    $self->{sform}->apply;

    my $dman = $self->{sform}->get_data_manager;
    $self->{data_broker}->query_DM( $dman, "subform_data", [ $self->{countryid} ] );

    $self->{log}->debug( "apply_2: ", $dman->get_field('langid1') );

    $self->{sform}->update;

    $self->{data_broker}->query_DM( $self->{grid}->get_data_manager,
        "grid_data", [ $value, $self->{countryid} ] );
    $self->{grid}->update;

}

sub on_add_lst_clicked {
    my ( $b, $self ) = @_;
    return unless defined $self->{langid};

    $self->{grid}->insert(
        $self->{grid}->colnumber_from_name("langid") => $self->{langid} );

}

sub on_apply_lst_clicked {
    my ( $b, $self ) = @_;
    $self->{log}->debug("apply lst lst_deleting: ", $self->{lst_deleting});

    if ( $self->{lst_deleting} ) {
        $self->{grid}->apply;
        $self->{lst_deleting} = 0;
        return;
    }

    my $dman = $self->{grid}->get_data_manager;

    my %old = (
        countryid => $dman->get_field('countryid'),
        langid    => $dman->get_field('langid')
    );

    my %h = (
        langid    => $self->{langid},
        countryid => $self->{grid}->get_column_value('countryid')
    );
    $self->{log}->debug( "old values ", sub { Dumper %old });
    $self->{log}->debug( "new values ", sub { Dumper %h });
    my @pks = $dman->get_primarykeys;

#a new row is created in Datasheet->apply  and the inserting flag is turn to 1 (not in Datasheet->insert)
#so to instert a new row: calls Datasheet->aplly before saving in the new row with SqlADM->save
#passing the pk names to apply excludes these from being saved here
#since they are saved with the hashref  pass to DM->save
    $self->{log}->debug("pks: ", sub { Dumper @pks });
 
    $self->{grid}->apply( \@pks );

    # on which row are we in the grid ?
    my $row = $self->{grid}->get_current_row;
    $self->{log}->debug( "row pos from grid: ", $row );

# set dman to this row before saving, since dman is now positionned on the last row
    $dman->set_row_pos($row);
    $dman->save(%h);
}

sub on_delete_lst_clicked {
    my $b    = shift;
    my $self = shift;
    $self->{lst_deleting} = 1;
    $self->{grid}->delete;
}

sub update_widgets_sensitivity {
    my ( $self, $dnav, $dman ) = @_;
    my $rc = $dman->row_count;
    $self->{log}->debug( "update_widgets_sensitivity rc: " . $rc );
    if ( $rc == 0 ) {
        $dnav->widgets_set_sensitivity(0);
    }
    else {
        $dnav->widgets_set_sensitivity(1);
    }
}

1;
