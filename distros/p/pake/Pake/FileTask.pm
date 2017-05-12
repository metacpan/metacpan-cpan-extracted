package Pake::FileTask;

our $VERSION = '0.2';

use strict;
use warnings;

our @ISA = qw(Pake::Task);

sub needed{
    my $self = shift;
    my $stamp;
    $stamp = $self->timestamp();
    return 1 unless $stamp;

    foreach my $pre (@{$self->{"pre"}}){
	if(-e $pre){
	    return 1 if $stamp < (stat($pre))[9];    
	} else{
	    warn "Task: ",$self->{"name"}," dependency -> $pre havn't created file";
	    return 1;
	    # warning, error?? Return one and execute or implement other funcionality
	}
    }
}

sub timestamp{
    my $self = shift;
    if(-e $self->{"name"}){
	return(stat($self->{"name"}))[9];
    }
}

1;

__END__

=head1 NAME

    Pake::FileTask

=head1 SYNOPSIS

    use Pake::FileTask;
    $file_task = Pake::FileTask->new($code,$name,$dependency_array_ref);
    $file_task->invoke();


=head1 Description

File task, executes if the file with the same name does not exists, or is out of date with dependencies

=head2 Methods

Overview of overriden methods in the FileTask object

=over 12

=item C<needed>

    Needed if the specified file does not exists or dependencies are out of date

=item C<timestamp>
    
    Returns file timestamp

=back

=cut
