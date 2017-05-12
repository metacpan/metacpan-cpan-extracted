$Tk::Labelled::VERSION = '0.2';

package Tk::Labelled;

use base  qw/ Tk::Frame /;
use Tk::widgets qw/ Label /;

Construct Tk::Widget '_Labelled';

sub Populate {

    my( $self, $args ) = @_;

    $self->SUPER::Populate( $args );
    my $widget = delete $args->{ -widget };
    die( '-widget option required.' ) unless $widget;
    my $labelled = $self->$widget->pack( -side => 'left' );
    $self->Advertise( 'labelled' => $labelled );
    $self->Delegates( 'DEFAULT' => $labelled );
    $self->ConfigSpecs( 'DEFAULT' => [ $labelled ] );

} # end Populate

sub Tk::Widget::Labelled {
    my( $pw, $widget, %args ) = @_;
    $args{ -labelPack } = [ -side => 'left' ] if not exists $args{ -labelPack };
    $pw->_Labelled( -widget => $widget, %args );
}

1;
