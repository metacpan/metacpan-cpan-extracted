package Argos::Map;

=head1 NAME

Argos::Map - Data collection

=head1 SYNOPSIS

 use Argos::Map;

 my $map = Argos::Map->new
 (
     name => 'foobar',
     conf => '/conf/file',
     path => '/path/file',
 );

 $map->run();

=cut
use strict;
use warnings;

use Carp;
use YAML::XS;

use threads;
use Thread::Queue;
use Time::HiRes qw( time sleep alarm stat );

use Argos::Code::Batch;
use Argos::Code::Map;
use Argos::Conf::Map;
use Argos::Path;
use Argos::Ctrl;
use Argos::Data;
use Vulcan::Logger;

our $SLEEP = 3;

sub new
{
    my ( $class, %self ) = splice @_;

=head1 CONFIGURATION

=head3 name

Name of watcher

=cut
    my $name = $self{name};

=head3 conf

See Argos::Conf::Map.

=cut
    my $conf = Argos::Conf::Map->new( $self{conf} );
    confess "$name has no config" unless
        $self{conf} = $conf = $conf->dump( $name );

    my ( $map, $batch ) = delete @$conf{ 'map', 'batch' };

=head3 path

See Argos::Path.

=cut
    my $path = $self{path} = Argos::Path->new( $self{path} )->make();

=head1 COLLECTION

Targets are devided into batches, and data are to be collected in parallel
by threads. Therefore the following takes place.

=head3 batch

Load code that deal with batching. See Argos::Code::Batch.

=cut
    $self{batch} = Argos::Code::Batch->new( $path->path( code => $batch ) );

=head3 map

Load code that deal with collecting. See Argos::Code::Map.

=cut
    $self{map} = Argos::Code::Map->new( $path->path( code => $map ) );

=head3 param

Load parameters for I<batch> and I<map>. See Argos::Conf.

=cut
    $self{param} = Argos::Conf->new( $path->path( conf => "map/$name" ) );

    bless \%self, ref $class || $class;
}

=head1 METHODS

=head3 run()

Launch Argos data collection.

=cut
sub run
{
    my $self = shift;
    my ( $name, $conf, $path, $map, $batch, $param  ) =
        @$self{ qw( name conf path map batch param ) };

    my $interval = $conf->{interval};
    my %run = ( cache => {}, name => $name, path => $path );

=head1 OBJECTS and BEHAVIORS

=head3 log

Process logs activites to STDERR. See Vulcan::Logger.

( Intended for daemontools multilog to collect. )

=cut
    my $log = Vulcan::Logger->new( \*STDERR );
    $run{log} = sub { $log->say( @_ ) };

=head3 ctrl

Process may be paused and targets may be excluded. See Argos::Ctrl.

=cut
    my $ctrl = Argos::Ctrl->new( $path->path( run => '.ctrl' ) );

=head3 data

Process dumps collected data to I<run> directory. See Argos::Data.

=cut
    my $data = Argos::Data->new( $name => $path->path( 'run' ) );
    my ( $queue, @queue, @thread ) = Thread::Queue->new();

    $SIG{TERM} = $SIG{INT} = sub
    {
        $data->clear();
        $log->say( 'argos: killed.' );
        map { $_->kill( 'KILL' )->detach() } threads->list();
        exit 1;
    };

    $log->say( 'argos: started.' );

    my %map = ( %run, param => $param->dump( 'map' ) );

    for my $i ( 0 .. $conf->{thread} - 1 )
    {
        $queue[$i] = Thread::Queue->new();
        push @thread, threads::async
        { 
            $map->run( %map, queue => [ $queue[$i], $queue ] )
        };
    }

    my %batch =
    (
        %run, param => $param->dump( 'batch' ),
        map { $_ => $conf->{$_} } qw( thread target ),
    );

    for ( my $now; $now = time; )
    {
        if ( $ctrl->stuck( $name ) )
        {
            $data->clear();
            $log->say( 'map: paused.' );
            sleep $SLEEP while $ctrl->stuck( $name );
        }

        my ( %exclude, %result ) = map { $_ => 1 } @{ $ctrl->excluded() };

        $log->say( 'batch: begin.' );
        my @batch = $batch->run( %batch, exclude => \%exclude );
        $log->say( 'batch: done.' );

        confess "thread and batch mismatch" if @batch > threads->list();
        map { $queue[$_]->enqueue( YAML::XS::Dump( $batch[$_] ),
            YAML::XS::Dump( $batch{cache} ) ) } 0 .. $#batch;

        $log->say( 'map: pending..' );
        my ( $time, %done ) = time;

        while ( sleep 1 )
        {
            my @tid = map { $_->tid } threads->list();
            splice @tid, 0 + @batch, 0 + @tid;
            last if keys %done >= @tid;

            while ( $queue->pending() )
            {
                my ( $tid, $result ) = $queue->dequeue_nb( 2 );
                $data->load( $result );
                $done{$tid} = 1;
            }

            if ( time - $time > $interval )
            {
                $data->dump();
                $log->say( 'map: timeout.' );
                exit 1;
            }
        }

        $data->dump();
        $log->say( 'map: done.' );

        my $due = $interval + $now - time;
        sleep $due if $due > 0; ## wait until due to run again
    }
}

1;
