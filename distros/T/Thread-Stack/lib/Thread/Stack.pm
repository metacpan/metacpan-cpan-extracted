package Thread::Stack;

use 5.008;
use threads::shared;
use strict;
use warnings;


our $VERSION = '1.00';


sub new {
    my $class = shift;
    my @q : shared = @_;
    return bless \@q, $class;
}

sub pop {
    my $q = shift;
    lock(@$q);
    cond_wait @$q until @$q;
    cond_signal @$q if @$q > 1;
    return CORE::pop @$q;
}

sub pop_nb {
    my $q = shift;
    lock(@$q);
    return CORE::pop @$q;
}
sub push {
    my $q = shift;
    lock(@$q);
    push @$q, @_  and cond_signal @$q;
}

sub size  {
    my $q = shift;
    lock(@$q);
    return scalar(@$q);
}

1;

__END__

=head1 NAME

Thread::Stack - thread-safe stacks adapted from Thread::Queue

=head1 SYNOPSIS

    use Thread::Stack;
    my $s = new Thread::Stack;
    $s->push("foo", "bar");
    my $bar = $s->pop;     # The "foo" is still in the stack.
    my $foo = $s->pop_nb;  # returns "foo", or undef if the stack was empty
    my $size = $s->size;   # returns the number of items still in the stack 

=head1 DESCRIPTION

A stack, as implemented by C<Thread::Stack> is a thread-safe 
data structure much like a list.  Any number of threads can safely 
add or remove elements to or from the beginning of the list. 
(Stacks don't permit adding or removing elements from the middle of the list).

=head1 FUNCTIONS AND METHODS

=over 8

=item new

The C<new> function creates a new empty stack.

=item push LIST

The C<push> method adds a list of scalars on the top of the stack.
The stack will grow as needed to accommodate the list.

=item pop

The C<pop> method removes a scalar from the top of the stack and
returns it. If the stack is currently empty, C<pop> will block the
thread until another thread C<push>es a scalar.

=item pop_nb

The C<pop_nb> method, like the C<pop> method, removes a scalar from
the top of the stack and returns it. Unlike C<pop>, though,
C<pop_nb> won't block if the stack is empty, instead returning
C<undef>.

=item size

The C<size> method returns the number of items still in the stack.

=back

=head1 CREDIT

The author of Thread::Queue deserves any credit here.  I simply 
modified Thread::Queue to implemnet a stack interface.

=head1 SEE ALSO

L<threads>, L<threads::shared>, L<Thread::Queue>

=cut
