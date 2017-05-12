package Argos::Code::Reduce;

=head1 NAME

Argos::Code::Reduce - Implements Argos::Code

=head1 SYNOPSIS

 use Argos::Code::Reduce;

 my $map = Argos::Code::Reduce->new( '/code/file' );

 $map->run( cache => {}, .. );

=cut
use strict;
use warnings;

use base qw( Argos::Code );

=head1 METHODS

=head3 run( %param )

Run reduce code. Returns invoking object.
The following may be defined in %param.


=cut
sub run
{
    my $self = shift;
    my %run = $self->param( @_ );
    local $SIG{ALRM} = sub { die 'timeout' };

    eval
    {
        alarm delete $run{timeout};
        &$self( %run );
        alarm 0;
    };

    return $self;
}

1;
