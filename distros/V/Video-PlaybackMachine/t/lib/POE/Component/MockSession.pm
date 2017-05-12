package POE::Component::MockSession;

use strict;
use warnings;

use POE;
use POE::Kernel;
use POE::Session;

sub new {
    my $type = shift;
    my %in = ();

    my $self = {
		alias => $in{'alias'},
		calls => {}
	       };

    bless $self, $type;
}


sub spawn {
    my $self = shift;

    POE::Session->create
	(
	 object_states => 
	 [ $self => [ qw[ _default _start ] ]  ]
	);
}

sub _start {
    my $self = $_[OBJECT];

    if (defined $self->{'alias'}) {
	foreach my $alias (@{ $self->{'alias'} }) {
	    $_[KERNEL]->alias_set($alias)
	}
    }


}

sub _default {
    my $self = $_[OBJECT];

    push(@{ $self->{'calls'}{$_[ARG0]} }, [ time(), $_[ARG1] ]);
}

sub get_calls {
    my $self = shift;
    my ($state) = @_;

    defined $self->{'calls'}{$state}
      or return;

    return @{ $self->{'calls'}{$state} };
}



1;

__END__

=head1 NAME

POE::Component::MockSession - Count the number of events sent to a fake session
