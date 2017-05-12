package Argos::Code::Batch;

=head1 NAME

Argos::Code::Batch - Implements Argos::Code

=head1 SYNOPSIS

 use Argos::Code::Batch;

 my $batch = Argos::Code::Batch->new( '/code/file' );

 $batch->run( cache => {} .. );

=cut
use strict;
use warnings;

use base qw( Argos::Code );

=head1 METHODS

=head3 run( %param )

Run batch code. Returns batches. The following may be defined in %param.

 exclude : a HASH reference.
 target : required by plugin.
 thread : maximum number of threads/batches.

=cut
sub run
{
    my $self = shift;
    my %run = ( thread => 1, exclude => {}, $self->param( @_ ) );
    my $exclude = delete $run{exclude};
    map { [ grep { defined $_ && ! $exclude->{$_} } @$_ ] } &$self( %run );
}

1;
