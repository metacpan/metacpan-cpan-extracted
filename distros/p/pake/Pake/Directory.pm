package Pake::Directory;

our $VERSION = '0.2';

use strict;
use warnings;

our @ISA = qw(Pake::FileTask);



sub needed{
    my $self = shift;

    if(-e $self->{"name"}){
	if(-d $self->{"name"}){
	    return 0;
	}
    }
    use File::Path;
    eval { mkpath($self->{"name"}) };
    if ($@) {
	warn "Couldn't create $self->{'name'}: $@";
    }

    return 1;
}

1;

__END__

=head1 NAME

Pake::Directory

=head1 SYNOPSIS

    use Pake::Directory;
    $dir_task = Pake::Directory->new($code,$name,$dependency_array_ref);
    $dir_task->invoke();


=head1 Description

Directory task, needs to execute only if the directory does not exists

=head1 Methods

Overview of overriden methods in the Directory object

B<needed>

Needed returns 1 only if the specified directory does not exists

=cut
