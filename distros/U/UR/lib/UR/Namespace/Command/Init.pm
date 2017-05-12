package UR::Namespace::Command::Init;
use strict;
use warnings;
use UR;
our $VERSION = "0.46"; # UR $VERSION;

UR::Object::Type->define(
    class_name => __PACKAGE__,
    is => "Command",
    has => [
        namespace => {
            is => 'Text',
            shell_args_position => 1,
            doc => 'the name of the namespace/app to create'
        },
        db => {
            is => 'Text',
            is_optional => 1,
            shell_args_position => 2,
            doc => 'the (optional) DBI connection string for the primary data source',
        },
    ],
    doc => 'create a new ur app with default classes in place',
);

sub sub_command_sort_position { 1 }

sub execute {
    my $self = shift;
    my $c;
    my $t = UR::Context::Transaction->begin();

    $self->status_message("*** ur define namespace " . $self->namespace);
    UR::Namespace::Command::Define::Namespace->execute(nsname => $self->namespace)->result or die;

    if ($self->db) {
        $self->status_message("\n*** cd " . $self->namespace);
        chdir $self->namespace or ($self->error_message("error changing to namespace dir? $!") and die);
    
        $self->status_message("\n*** ur define db " . $self->db);
        $c = UR::Namespace::Command::Define::Db->create(uri => $self->db) or return;
        $c->dump_status_messages(1);
        $c->execute() or die;

        $self->status_message("\n*** ur update classes-from-db");
        $c = UR::Namespace::Command::Update::ClassesFromDb->create();
        $c->dump_status_messages(1);
        $c->execute() or die;
    }
    else {
        $self->status_message("next: cd " . $self->namespace);
        $self->status_message("then: ur define db DSN");
        $self->status_message("then: ur update classes-from-db");
    }
    $t->commit;

    return 1; 
}

1;

