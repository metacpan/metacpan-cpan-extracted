package Pake::MultiTask;

@ISA = qw(Pake::Task);

use threads;
use Scalar::Util qw(blessed);

sub invoke_prerequisites {
    my $self = shift;
    my @threads = ();
    for $pre (@{$self->{"pre"}}){
        if(blessed ($self->{"application"}{"tasks"}{$pre})){
	    my $thread = threads->new(\&invoker,$self->{"application"}{"tasks"}{$pre});
	    push @threads, $thread;
        } else{
	    warn "cannot apply rules" unless $self->{"application"}->check_rules($pre);
        }
    }

    for my $thread (@threads){
	$thread->join();
    }
}

sub invoker($){
    my $task = shift;
    $task->invoke();
}

1;


__END__

=head1 NAME

    Pake::MultiTask

=head1 SYNOPSIS

    use Pake::MultiTask;
    $multi_task = Pake::MultiTask->new($code,$name,$dependency_array_ref);
    $mulit_task->invoke();


=head1 Description

MultiTask task, executes dependencies in parallel. Right now there is no guarantee that dependencies want be run more then once

=head2 Methods

Overview of overriden methods in the FileTask object

B<invoke_prerequisites>

Parrallel invocation

B<inoker>
    
Thread method invoke

=cut
