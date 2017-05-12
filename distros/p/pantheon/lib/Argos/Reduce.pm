package Argos::Reduce;

=head1 NAME

Argos::Reduce - Data processing

=head1 SYNOPSIS

 use Argos::Reduce;

 my $reduce = Argos::Reduce->new
 (
     name => 'foobar',
     conf => '/conf/file',
     path => '/path/file',
 );

 $reduce->run();

=cut
use strict;
use warnings;

use Carp;
use File::Spec;
use Time::HiRes qw( time sleep alarm );

use Argos::Conf::Reduce;
use Argos::Code::Reduce;
use Argos::Path;
use Vulcan::Logger;

our $FREQ = 6;

sub new
{
    my ( $class, %self ) = splice @_;

=head1 CONFIGURATION

=head3 name

Name of watcher

=cut
    my $name = $self{name};

=head3 conf

See Argos::Conf::Reduce.

=cut
    my $conf = Argos::Conf::Reduce->new( $self{conf} );
    confess "$name has no config" unless
        $self{conf} = $conf = $conf->dump( $name );

    my $code = delete $conf->{code};

=head3 path

See Argos::Path.

=cut
    my $path = $self{path} = Argos::Path->new( $self{path} )->make();

=head3 code

Load code that deal with alerting. See Argos::Code::Reduce.

=cut
    $self{reduce} = Argos::Code::Reduce->new( $path->path( code => $code ) );

=head3 param

Load parameters for I<code>. See Argos::Conf.

=cut
    $self{param} = Argos::Conf->new( $path->path( conf => "reduce/$code" ) );

    bless \%self, ref $class || $class;
}

=head1 METHODS

=head3 run()

Launch Argos data processing.

=cut
sub run
{
    my $self = shift;
    my ( $name, $conf, $path ) = @$self{ qw( name conf path ) };
    my %run = ( cache => {} );

=head1 BEHAVIORS

=head3 log

Argos logs activites to STDERR. See Vulcan::Logger.

( Intended for daemontools multilog to collect. )

=cut
    my $log = Vulcan::Logger->new( \*STDERR );
    $run{log} = sub { $log->say( @_ ) };

    $SIG{TERM} = $SIG{INT} = sub
    {
        $log->say( 'argos: killed.' );
        exit 1;
    };

    $log->say( 'argos: started.' );

    my $data = $path->path( 'run' );
    my @stat = @{ $conf->{stat} };
    my ( $freq, $rate, $tier, $esc ) = @$conf{ qw( freq rate tier esc ) };

    for ( my ( %stat, $now ); $now = time; ) ## path => [ timestamp, count ]
    {
        my ( %curr, %due ) = map { $_ => ( stat $_ )[9] } ## path => mtime
        my @path = map { glob File::Spec->join( $data, $_ ) } @stat;

        map { $stat{$_} = [ $now, -1 ] unless $stat{$_} } @path; ## new

        map { delete $stat{$_} if ! $curr{$_}
            || $now - $curr{$_} > $freq } keys %stat; ## gone or cruft

        while ( my ( $path, $stat ) = each %stat )
        {
            my $prev = $stat->[1];
            my $curr = int( ( $now - $stat->[0] ) / $freq );
            push @{ $due{ $stat->[1] = $curr } }, $path
                if $prev < 0 || $prev < $curr; ## due to run
        }

        for my $count ( sort { $b <=> $a } keys %due )
        {
            my $index = $esc ? int $count / $esc : -1;
            $index = @$tier - 1 if $index >= @$tier;

            $self->{reduce}->run
            (
                %run, param => $self->{param}->dump( $name ), name => $name,
                data => $due{$count ++}, tier => $tier->[$index ++],
                esc => $index, count => $count, timeout => $freq,
            );
        }

        my $due = $rate + $now - time;
        sleep $due if $due > 0; ## wait until due to run again
    }
}

1;
