package DBIx::Class::ResultSet::TP;

use Moose;
extends 'DBIx::Class::Core';

sub insert {
    my $self = shift;

    #print "Add a new page $self\n";

    my $return = $self->next::method( @_ );

    my $tp = $self->result_source->schema->treepath;
    my $obj = $tp->_row_to_obj($self);
    $tp->add($obj);
    return $return;
}

sub update {
    my $self = shift;

    #print "Update a page\n";

    my $return = $self->next::method( @_ );

    my $tp = $self->result_source->schema->treepath;
    my $obj_key = $tp->_rs_to_obj_key($self);
    my $node = $tp->tree->{$obj_key};
    my $obj = $tp->_row_to_obj($self);

    $tp->update($node,$obj);
    return $return;
}

sub delete {
    my $self = shift;

    #print "Del a page\n";

    my $return = $self->next::method( @_ );

    my $tp = $self->result_source->schema->treepath;
    my $obj = $tp->_row_to_obj($self);
    $tp->del($obj);
    return $return;
  }


1;
