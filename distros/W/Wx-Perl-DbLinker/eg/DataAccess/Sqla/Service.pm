package DataAccess::Sqla::Service;

use strict;
use warnings;
use parent qw(DataAccess::Broker);
use DBI;
use Gtk2::Ex::DbLinker::SqlADataManager;
use Data::Dumper;
# use Carp 'croak';

sub new {

my ($class, $href)= @_;
   
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
my ($self, $key, $value_ref) = @_;
   my $arg_ref = $self->get_arg_sqla($key, $value_ref);
   my @ar = (%{ $arg_ref });
   $self->{log}->debug("get_DM_for ", sub{ Dumper @ar});
 my $dman =  Gtk2::Ex::DbLinker::SqlADataManager->new(
     dbh => $self->{dbh},
     @ar
 );
    return $dman;

}

sub query_DM {
    my ($self, $dman, $key, $values_ref) = @_;
    my $arg_ref = $self->get_arg_sqla($key, $values_ref);
    my $where =  $arg_ref->{select_param}->{-where};    
     $self->{log}->logcroak ("select_param->where not found") unless (defined $where);
     
$self->{log}->debug("query_DM ", sub { Dumper $where });

$dman->query(-where => $where);

}
1;

