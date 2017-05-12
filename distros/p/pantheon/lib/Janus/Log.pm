package Janus::Log;

=head1 NAME

Janus::Log - Janus logging

=head1 SYNOPSIS

 use Janus::Log;

 my $log = Janus::Log->new( foobar => '/log/dir' );

 $log->link( '/symbolic/link' );
 $log->say( 'foo', 'bar' );
 my @lines = $log->tail( 10 );

=cut
use strict;
use warnings;
use Carp;
use POSIX;
use File::Spec;
use Thread::Semaphore;

our @WEEKDAY = qw( Sun Mon Tue Wed Thu Fri Sat );

sub new
{
    my ( $class, $name, $path ) = splice @_;
    my %self = ( mutex => Thread::Semaphore->new() );
    my @time = localtime;
    my $format = "$name.%Z.%Y.%m.%d_%H:%M.$WEEKDAY[$time[6]]";

    $path = $self{path} =
        File::Spec->join( $path, POSIX::strftime( $format, @time ) );

    confess "cannot open $path: $!" unless open $self{handle}, '>>', $path;
    bless \%self, ref $class || $class;
}

=head1 METHODS

=head3 say( @list )

I<say> @list to log. Returns invoking object.

=cut
sub say
{
    my $self = shift;
    my $handle = $self->{handle};
    if ( @_ )
    {
        $self->{mutex}->down();
        syswrite $handle, join( '', @_ ) . "\n";
        $self->{mutex}->up();
    }
    return $self;
}

=head3 link( $path )

Link $path to log path. Returns invoking object.

=cut
sub link
{
    my ( $self, $link ) = splice @_;
    my $path = File::Spec->rel2abs( $self->{path} );

    confess "cannot link $link to $path"
        if system( "rm -f $link && ln -s $path $link" );
    return $self;
}

1;
