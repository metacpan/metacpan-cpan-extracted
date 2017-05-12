package Pake::FileCreationTask;

our $VERSION = '0.2';

use strict;
use warnings;

our @ISA = qw(Pake::Task);

sub needed{
    my $self = shift;
    my $stamp;
    $stamp = $self->timestamp();
    return 1 unless -e $self->{"name"};
}

sub timestamp{
    my $self = shift;
    if(-e $self->{"name"}){
	return(stat($self->{"name"}))[9];
    }
}

1;

=head1 NAME

Pake::FileCreationTask

=head1 SYNOPSIS

    use Pake::FileCreationTask;
    $file_task = Pake::FileCreationTask->new($code,$name,$dependency_array_ref);
    $file_task->invoke();


=head1 Description

File creation task, executes if the file with the same name does not exists

=head1 Methods

Overview of overriden methods in the FileTask object

B<needed>

Needed only if the specified file does not exists

B<timestamp>
    
Returns file timestamp. If the file don't exists it returns... nothing

=cut
