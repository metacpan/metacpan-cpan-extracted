package MyVal;

use Validation::Class;

load {
    classes => 1
};

profile new_ticket => sub {

    my ($self) = shift;

    # check person, and ticket values
    my $person = $self->class('person');
    my $ticket = $self->class('ticket');
    
    unless ($person->validate('+name')) {
        $self->set_errors($person->get_errors);
    }
    
    unless ($ticket->validate('+description', 'priority')) {
        $self->set_errors($ticket->get_errors);
    }
    
    return $self->error_count ? 0 : 1

};

1;
