package App::ForkProve::PipeIterator;
use strict;
use parent qw(TAP::Parser::Iterator::Stream);

sub new {
    my($class, $fh, $pid) = @_;
    my $self = $class->SUPER::new($fh);
    $self->{pid} = $pid;
    $self->{mypid} = $$;
    $self;
}

sub get_select_handles { $_[0]->{fh} }

sub wait { $_[0]->_wait }
sub exit { $_[0]->_wait >> 8 }

sub _wait {
    my $self = shift;
    if (!defined $self->{wait}) {
        waitpid $self->{pid}, 0;
        $self->{wait} = $?;
    }
    return $self->{wait};
}

sub DESTROY {
    return unless $_[0]->{mypid} == $$;
    $_[0]->_wait;
}

1;

