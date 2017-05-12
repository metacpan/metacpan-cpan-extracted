package Vulcan::ProcLock;

=head1 NAME

Vulcan::ProcLock - Advisory lock using a regular file

=head1 SYNOPSIS

 use Vulcan::ProcLock;

 my $lock = Vulcan::ProcLock->new( '/lock/file' );

 $lock->lock();

 if ( my $pid = Vulcan::ProcLock->check( '/lock/file' ) )
 {
     print "Locked by $pid.\n";
 }
 
=cut
use strict;
use warnings;
use Carp;
use File::Spec;
use Fcntl qw( :flock );

sub new
{
    my ( $class, $file ) = splice @_;
    my $mode = -f ( $file = File::Spec->rel2abs( $file ) ) ? '+<' : '+>';

    confess "invalid lock file: $file" if -e $file && ! -f $file;
    confess "open $file: $!" unless open my ( $self ), $mode, $file;
    bless \$self, ref $class || $class;
}

=head1 METHODS

=head3 check( $file )

Returns PID of owner, undef if not locked.

=cut
sub check
{
    my ( $self, $file, $fh, $pid ) = splice @_, 0, 2;
    return open( $fh, '<', $file ) && ( $pid = $self->read( $fh ) )
        ? $pid : undef;
}

=head3 lock()

Attempts to acquire lock. Returns pid if successful, undef otherwise.

=cut
sub lock
{
    local $| = 1;

    my ( $self, $pid ) = shift;

    return $pid unless flock $$self, LOCK_EX | LOCK_NB;

    unless ( $pid = $self->read() )
    {
        seek $$self, 0, 0;
        truncate $$self, 0;
        print $$self ( $pid = $$ );
    }
    elsif ( $pid ne $$ )
    {
        $pid = undef;
    }
 
    flock $$self, LOCK_UN;
    return $pid;
}

=head3 handle()

Returns file handle of object.

=cut
sub handle { return ${ shift @_ } }

=head3 read()

Returns a running pid or undef. 

=cut
sub read
{
    my ( $self, $fh, $pid ) = splice @_, 0, 2;
    return seek( ( $fh ||= $$self ), 0, 0 ) && read( $fh, $pid, 16 )
        && $pid =~ /^(\d+)/ && kill( 0, $1 ) ? $1 : undef;
}

1;
