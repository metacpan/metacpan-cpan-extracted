package DataAccess::Dbc::Service;

use strict;
use warnings;
use parent qw(DataAccess::Broker);
use Gtk2::Ex::DbLinker::DbcDataManager;
use Data::Dumper;
sub new {

    my ( $class, $href ) = @_;

    my $self = $class->SUPER::new();
    $self->{log}    = Log::Log4perl->get_logger(__PACKAGE__);
    $self->{schema} = $href->{schema};
    $self->{dbh}    = $self->{schema}->storage->dbh;
    return $self;

}

sub get_dbh {
    return shift->{dbh};
}

sub get_DM_for {
    my ( $self, $key, $values_ref ) = @_;
    # my $arg_ref = $self->get_arg_dbc( $key, $value_ref );
    $self->{log}->debug("get_DM_for ", $key, " ", sub { Dumper $values_ref });
     my $rs = $self->get_resultset($key, $values_ref);
    my $dman = Gtk2::Ex::DbLinker::DbcDataManager->new(
        {   rs => $rs,

        }
    );
    # $dman->first;
    return $dman;

}

sub query_DM {
    my ( $self, $dman, $key, $values_ref ) = @_;
   
    $self->{log}->debug("query_DM ", $key, " ", sub { Dumper $values_ref });
     my $rs = $self->get_resultset($key, $values_ref);

    $dman->query($rs);

}

sub get_resultset {
 my ($self, $key, $values_ref) = @_;
    my $arg_ref = $self->get_arg_dbc( $key, $values_ref );
    my @arg = @$arg_ref;
    # $self->{log}->debug("get_DM_for ", Dumper @arg);
    my $size = @arg;
    my $rs;
    if ( $size == 3 ) {
        $self->{log}->debug("get_resultset arg2 ", sub { Dumper $arg[2], ref $arg[2] });
        $rs = $self->{schema}->resultset( $arg[0] )
            ->search_rs( $arg[1], $arg[2] );
    }
    elsif ( $size == 2 ) {
        $rs = $self->{schema}->resultset( $arg[0] )
            ->search_rs( $arg[1] );
    }
    else {
        $rs = $self->{schema}->resultset( $arg[0] )->search_rs();
    }
    return $rs;
}
1;

