package DataAccess::Dbi::Service;

use strict;
use warnings;
use parent qw(DataAccess::Broker);
use DBI;
use Gtk2::Ex::DbLinker::DbiDataManager;
#use Data::Dumper;
#use Carp 'croak';

sub new {
    my ( $class, $href ) = @_;

    my $self = $class->SUPER::new();
    $self->{dbh} = $href->{dbh};
    $self->{log} = Log::Log4perl->get_logger(__PACKAGE__);
    return $self;

}

sub get_dbh {
    my $self = shift;

    return $self->{dbh};
}

sub get_DM_for {
    my ( $self, $key, $value_ref ) = @_;
    my $arg_ref = $self->get_arg_dbi( $key, $value_ref );
    my @ar = (%{ $arg_ref });
     my $dman  = Gtk2::Ex::DbLinker::DbiDataManager->new(
         dbh => $self->{dbh},
        @ar
     );
    return $dman;
}

sub query_DM {
    my ( $self, $dman, $key, $values_ref ) = @_;
    my $arg_ref = $self->get_arg_dbi( $key, $values_ref );
    $self->{log}->debug("query_DM values ", join(" ", @{$values_ref}));
    my $where = $arg_ref->{sql}->{where};
    $self->{log}->logcroak("sql->where not found") unless ( defined $where );
    my $values =$arg_ref->{sql}->{bind_values};
    $self->{log}->logcroak("sql->bind_values not found") unless ( defined $values );
    $dman->query( where => $where, bind_values => $values );

}
1;

