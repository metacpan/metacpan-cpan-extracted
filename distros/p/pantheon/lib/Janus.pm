package Janus;

=head1 NAME

Janus - A maintenance platform

=head1 SYNOPSIS

 use Janus;

 my $janus = Janus->new
 (
     name => 'foobar',
     conf => '/conf/file',
     path => '/path/file',
 );

 $janus->run();

=cut
use strict;
use warnings;

use Carp;
use POSIX;
use YAML::XS;

use Janus::Log;
use Janus::Path;
use Janus::Conf;
use Janus::Ctrl;
use Janus::Sequence;
use Vulcan::ProcLock;

=head1 SEQUENCES

The following sequences may be defined. See Janus::Sequence.

=head3 alpha

BEGIN sequence.

=head3 delta

sequence for each batch of targets.

=head3 omega

End sequence.

=cut
our @SEQUENCE = qw( alpha delta omega );

sub new 
{
    my ( $class, %self ) = splice @_;

=head1 CONFIGURATION

=head3 name

Name of the maintenance event.

=cut
    my $name = $self{name};

=head3 conf

See Janus::Conf.

=cut
    my $conf = Janus::Conf->new( $self{conf} );
    confess "$name has no config" unless
        $self{conf} = $conf = $conf->dump( $name );

=head3 path

See Janus::Path.

=cut
    my $path = $self{path} = Janus::Path->new( $self{path} )->make();
    my %path =
    ( 
        conf => $path->path( conf => $name ),
        code => $path->path( code => delete $conf->{maint} )
    );

    my $sequence = $self{sequence} = {};

    for my $name ( @SEQUENCE )
    {
        my $seq = Janus::Sequence->new( %path, name => $name );
        $sequence->{$name} = $seq if $seq->check;
    }

    my $batch = $path->path( code => delete $conf->{batch} );
    my $error = "$name: invalid batch definition $batch";

    $batch = $self{batch} = do $batch;

    confess "$error: $@" if $@;
    confess "$error: not CODE" unless $batch && ref $batch eq 'CODE';
    bless \%self, ref $class || $class;
}

=head1 METHODS

=head3 run()

Launch maintenance. Return 1 on failure, 0 on success.

=cut
sub run
{
    my $self = shift;
    my ( $name, $path ) = @$self{ qw( name path ) };
    my %run = ( janus => $name );
    my ( $lock, $link, $cache, $ctrl ) =
        map { $path->path( run => "$name.$_" ) } qw( lock log cache ctrl );

=head1 OBJECTS and BEHAVIORS

=head3 lock

Janus creates/obtains an advisory lock under the I<run> directory.
See Vulcan::ProcLock.

=cut
    $lock = Vulcan::ProcLock->new( $lock );
    confess "$name is already running" unless $lock->lock();
    

=head3 log

Janus logs to a file under the I<log> directory. A symbolic link to the
log file is created under the I<run> directory. See Janus::Log.

=cut
    my $log = Janus::Log->new( $name => $path->path( 'log' ) );
    $log->link( $link );

    $run{log} = sub
    {
        $log->say( shift, @_ ? ( ': ' . POSIX::sprintf @_ ) : @_ );
    };

=head3 ctrl

Subroutines I<stuck> and I<exclude> are created from ctrl.
See Janus::Ctrl.

=cut
    $ctrl = Janus::Ctrl->new( $name, $ctrl );
    $run{stuck} = sub
    {
        $ctrl->pause( @_ ) if @_ == 3;
        push @_, Janus::Ctrl->any();

        if ( $ctrl->stuck( @_ ) )
        {
            $log->say( 'janus: paused.' );
            $self->{stuck} = 1;
        }
        sleep 3 while $ctrl->stuck( @_ );
        $self->{stuck} = 0;
    };

    $run{exclude} = sub
    {
        my $batch = shift;
        return $batch unless $batch && ref $batch eq 'ARRAY' && @$batch;
        $batch = [ $batch ] if my $delta = ref $batch->[0] ne 'ARRAY';

        my %xcldd = map { $_ => 1 } @{ $ctrl->excluded() };
        my @batch = map { [ grep { defined $_ && ! $xcldd{$_} } @$_ ] } @$batch;
        return $delta ? shift @batch : \@batch;
    };

=head3 cache

Janus loads cache (HASH) from a YAML file, if any, under the I<run>
directory, then unlinks said file. When INT or TERM signal is caught,
Janus dumps cache to said file, clears I<ctrl>, and exits.

=cut
    $run{cache} = {};
    $SIG{TERM} = $SIG{INT} = sub
    {
        if ( $self->{stuck} )
        {
            YAML::XS::DumpFile( $cache, $run{cache} );
            $ctrl->clear();
            $log->say( 'janus: killed.' );
            exit 1;
        }
    };

    if ( -f $cache )
    {
        $run{cache} = YAML::XS::LoadFile( $cache );
        unlink $cache;
    }

    my @batch = &{ $self->{batch} }( %run, %{ $self->{conf} } );
    $log->say( "janus: begin." );

    for my $name ( @SEQUENCE )
    {
        next unless my $seq = $self->{sequence}{$name};
        if ( $name ne 'delta' ) { $seq->run( %run, batch => [ @batch ] ) }
        else { map { $seq->run( %run, batch => $_ ) } @batch }
    }

    $log->say( "janus: done." );
    $ctrl->clear();
    return 0;
}

1;
