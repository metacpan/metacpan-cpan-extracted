package Pan::Node;

=head1 NAME

Pan::Node - Applies transforms. Extends Pan::Repo.

=head1 SYNOPSIS

 use Pan::Node;

 my $node = Pan::Node->new
 (
     conf => '/conf/file',
     path => '/path/file',
     group => 'foo',
 );

 $node->run( log => sub { .. } );

=cut
use strict;
use warnings;
use Carp;

use base qw( Pan::Repo );
use Vulcan::ProcLock;

=head1 METHODS

=head3 run( %param )

Launch Pan. Apply transforms. Any addtional parameters to the transforms
may be defined in I<%param>. Return 1 on failure, 0 on success.

=cut
sub run
{
    my $self = shift;
    my %run = ( cache => {}, log => sub {}, @_ );

=head1 OBJECTS and BEHAVIORS

=head3 lock

Pan creates/obtains an advisory lock under the I<run> directory.
See Vulcan::ProcLock.

=cut
    my $lock = Vulcan::ProcLock->new( $self->{path}->path( run => 'lock' ) );
    confess "Pan already running" unless $lock->lock();

    my %conf = $self->dump();
    for my $transform ( @{ $conf{ $self->{group} }{transform} } )
    {
        eval { &$transform( %run ) };
        if ( $@ ) { cluck $@; return 1 }
    }
    return 0;
}

1;
