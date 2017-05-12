package Forms::Langues;

use strict;
use warnings;
# use Data::Dumper;
use base qw(Wx::App);
use Wx::Perl::DbLinker::Wxform;
use Log::Log4perl;
use Scalar::Util 'weaken';
use Wx_dnav;
use Forms::Sflang;

sub new {

    my ( $class, $href ) = @_;
    my $self = $class->SUPER::new();
    @$self{ keys %$href } = values %$href;

    #$self->{data_broker}       = $$href{d};
    $self->{log}  = Log::Log4perl->get_logger(__PACKAGE__);
    $self->{dnav} = Wx_dnav->new(
        {   size      => [ 900, 900 ],
            main_name => 'mainwindow',
            main_file => '../xrc/main.xrc',
            dbh       => $self->{data_broker}->get_dbh,
            mibuilder => sub    { $self->get_datamanager_formenuitems(@_); },

        }
    );
    weaken $self->{dnav};
    $self->{dnav}->load_panel( 'mainwindow', 'xrc/nav.xrc', 'm_dnav_panel' );

    my $path = $self->{xrcfolder} . "\\content.xrc";
    my $top_panel =
        $self->{dnav}->load_panel( 'm_panel_for_content', $path, 'm_panel1' );

    $self->{log}->debug(" new form ");

    $self->{dnav}->populate_widgets( $self->{dnav}->get_object("m_panel_for_buttons"), [qw(b_add)] );

    my $dman = $self->{data_broker}->get_DM_for('mainform_data');

    $self->{linker} = Wx::Perl::DbLinker::Wxform->new(
        data_manager        => $dman,
        builder             => $self->{dnav},
        rec_spinner         => $self->{dnav}->get_object('RecordSpinner'),
        status_label        => $self->{dnav}->get_object('lbl_RecordStatus'),
        rec_count_label     => $self->{dnav}->get_object("lbl_RecordCount"),
        primary_keys        => ["countryid"],
        datawidgets_changed => {
            countryid => sub {
                on_countryid_changed( $self->{dnav}->get_object('countryid'),
                    $self );
            },
        },
    );
    weaken $self->{linker};

    $self->{dnav}->set_form( $self->{linker} );

    $self->{countryid} = $dman->get_field('countryid');

    my $combodata = $self->{data_broker}->get_DM_for('langue');
    $self->{linker}->add_combo(
        data_manager => $combodata,
        id           => 'mainlangid',
    );

    $self->{sf} = Forms::Sflang->new(
        xrcfolder   => $self->{xrcfolder},
        data_broker => $self->{data_broker},
        dnav        => $self->{dnav},
        panel_to    => 'panel_subform',
        countryid   => $self->{countryid},
    );
    weaken $self->{sf};
    $self->{linker}->add_childform( $self->{sf}->{sform} );

    $self->{linker}->update;

    #the binding with the buttons in made in the call to
    #dnav->set_form() above
    #the functions called are the add, delete etc functions
    #provided by the Wx::Perl::DbLinker::Form object stored in $self->{linker}

    $self->{dnav}->show_all_except(                  [] );
    $self->{sf}->{dnav}->show_all_except(            [] );
    $self->{sf}->{sf_list}->{dnav}->show_all_except( [] );
    $self->update_widgets_sensitivity;
    return $self;

}

sub OnInit {
    1;
}

sub on_countryid_changed {
    my ( $b, $self ) = @_;
    $self->{log}->debug("countryid_changed called");
    my $value = $b->GetLineText(0);
    $value = ( $value eq "" ? undef : $value );

 #return && $self->{dnav}->widgets_set_sensitivity(0) unless defined ($value);
    if ( defined $value ) {
        $self->{log}->debug("on_countryid_changed : $value");
        $self->{countryid} = $value;
       
    }
   
     $self->{sf}->on_countryid_changed($value);
     $self->update_widgets_sensitivity;
}

sub get_datamanager_formenuitems {
    my $self = shift;

# called as &coderef from wx_dnav $self is not passed and the first element in @_ is the argument passed in the call
    my $href = ( ref $_[0] eq "HASH" ? $_[0] : { (@_) } );
    my $data;
    if ( $href->{name} ) {

        $data = $self->{data_broker}->get_DM_for( $href->{name} );
    }
    else {
        $self->{log}
            ->debug("Displaying result from select query is not implemented");

    }
    return $data;
}

sub update_widgets_sensitivity {
    my $self = shift;
    my $rc = $self->{linker}->get_data_manager->row_count;
    if ( $rc == 0 ) {
        $self->{dnav}->widgets_set_sensitivity(0);
    }
    else {
        $self->{dnav}->widgets_set_sensitivity(1);
    }
   

}

1;
