package XAO::DO::DepBase;
use strict;
use warnings;
use XAO::Objects;
use XAO::Projects;
use base XAO::Objects->load(objname => 'Atom');

sub combine {
    my $self=shift;
    my ($tag,$arg)=@_;

    return
        (XAO::Projects::get_current_project_name() // '<no-site>') .
        ':' .
        ($tag // '<no-tag>') .
        ':' .
        ($arg // '<no-arg>');
}

sub method_A ($) {
    my $self=shift;
    return $self->combine('test-DepBase-A',shift);
}

sub method_B ($) {
    my $self=shift;
    return $self->combine('test-DepBase-B',shift);
}

1;
