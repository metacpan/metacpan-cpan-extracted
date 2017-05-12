package DataAccess::Rdb::Service;

use strict;
use warnings;
use parent qw(DataAccess::Broker);
use Gtk2::Ex::DbLinker::RdbDataManager;
use Rdb::Speak::Manager;
use Rdb::Country::Manager;
use Rdb::Langue::Manager;
# use Data::Dumper;

sub new {

my ($class, $href)= @_;
   
     my $self = $class->SUPER::new(); 
     # $self->{dbh_orig} = $href->{dbh};  
  $self->{log} = Log::Log4perl->get_logger(__PACKAGE__);
        return $self;

}
sub get_dbh {
  my $self = shift;
    my $db = Rdb::DB->new_or_cached( domain => 'main' );
    $self->{dbh} = $db->dbh or die $db->error;
}

sub get_DM_for {
my ($self, $key, $value_ref) = @_;
my $arg_ref =$self->get_arg_rdb($key, $value_ref);
my $size = @$arg_ref;
 my $rdata;
 # $self->{log}->debug("Get_DM_for", Dumper $arg_ref);
my $class =  $arg_ref->[0];
  my $meta = $class->meta;

  #if ( exists $arg_ref->{arg3}) {
        #$rdata = $self->{schema}->resultset($arg_ref->{arg1})->search_rs( $arg_ref->{arg2}, $arg_ref->{arg3});
        # }
    if (  $arg_ref->[1]) {
        my %ar =%{$arg_ref->[1]};
        my @arg = (%ar);
        # $self->{log}->debug("Get_DM_for ", ref $arg_ref->[1],"\n", Dumper @arg);
        $rdata = Rose::DB::Object::Manager->get_objects(object_class => $class, @arg );
    }
    else {
         $rdata = Rose::DB::Object::Manager->get_objects(object_class => $class );
    }
    my $dman;
    if ( $arg_ref->[2]){
        my @ar =(  %{$arg_ref->[2]} );
         $dman = Gtk2::Ex::DbLinker::RdbDataManager->new(
        {   data => $rdata,
            meta => $meta,
            @ar,

        });
    }
    else {
        $dman = Gtk2::Ex::DbLinker::RdbDataManager->new(
        {   data => $rdata,
            meta => $meta,

        });
}
    return $dman;

}
sub query_DM {
    my ($self, $dman, $key, $values_ref) = @_;
    my $arg_ref =$self->get_arg_rdb( $key, $values_ref);
    # $self->{log}->debug("query_DM ", Dumper $arg_ref->[1]);
    my @ar = ( %{$arg_ref->[1]});
    #$self->{log}->debug(Dumper @ar);
    my $rs = Rose::DB::Object::Manager->get_objects(object_class => $arg_ref->[0], @ar);
    #$rs->query(@ar);
    $dman->query($rs);

}
1;


