=head1 NAME

Vulcan::Daemon - CLI for daemontools service.

=cut
package Vulcan::Daemon;

use strict;
use warnings;
use Carp;

use YAML::XS;
use File::Spec;
use File::Temp;

=head1 CONFIGURATION

A YAML file that defines I<conf> and I<service> paths. Each must be a
valid directory or symbolic link. 

=head3 service

Under which services are set up.

=head3 conf

Under which configuration files reside. Each configuration file may specify
the following parameters in YAML:

I<required>:

 command: service command

I<optional>, default to ( ):

 user: ( nobody ) setuidgid user.
 size: ( 10000000 ) multilog S value
 keep: ( 5 ) multilog N value

=cut
our %RUN = ( user => 'nobody', size => 10000000, keep => 5 );

=head1 SYNOPSIS

 use Vulcan::Daemon;

 my $daemon = Vulcan::Daemon->new( name => 'foo', path => '/path/file' );

 $daemon->run();
 $daemon->kill();

=cut
sub new
{
    my ( $class, %self ) = splice @_;
    my $name = $self{name};
    my $path = Vulcan::Daemon::Path->new( $self{path} )->make();
    my $conf = $path->path( conf => $name );
    my $error = "invalid config $conf";
    confess "no such config $conf" unless -f $conf;

    $self{link} = "/service/$name";
    $self{path} = $path->path( service => $name );
    $self{conf} = $conf = eval { YAML::XS::LoadFile $conf };
    $self{mlog} = File::Spec->join( $self{path}, 'log' );

    confess "$error: $@" if $@; 
    confess "$error: not HASH" if ref $conf ne 'HASH';

    if ( my $command = $conf->{command} )
    {
        $conf->{command} = Vulcan::Daemon::Path->macro( $command );
    }
    else
    {
        confess "$error: command/script not defined" unless $conf->{script};
    }

    bless \%self, ref $class || $class;
}

=head1 METHODS

=head3 run()

Set up and launch service.

=cut
sub run
{
    my $self = shift;
    my %run = ( %RUN, %{ $self->{conf} } );
    my ( $name, $link, $path, $log ) = @$self{ qw( name link path mlog ) };

    my $mkdir = "mkdir -p $log";
    my $user = delete $run{user};
    my $main = './main';
    my %nice = ( nice => '-n', ionice => '-c' );
    my @nice = map { "$_ $nice{$_} $run{$_}" }
        grep { defined $run{$_} } keys %nice;

    confess "failed to $mkdir" if system $mkdir;

    $run{command} = $self->script( $path, 'run.script', $run{script} )
        if $run{script};

    $self->script( $path, 'run', "#!/bin/sh",
        "exec @nice setuidgid $user $run{command} 2>&1" );

    $self->script( $log, 'run', "#!/bin/sh",
        "mkdir -p $main", "chown -R $user $main",
        "exec setuidgid $user multilog t I s$run{size} n$run{keep} $main" );
            
    if ( -l $link ) { warn "$name: already running\n" }
    elsif ( ! symlink $path, $link ) { confess "symlink: $!" }
}

=head3 kill()

Kill service.

=cut
sub kill
{
    my $self = shift;
    my ( $link, $path, $log ) = @$self{ qw( link path mlog ) };
    system( "rm $link && svc -dx $path && svc -dx $log && rm -rf $path" );
}

=head3 tail( $number )

Tail service log

=cut
sub tail
{
    my ( $self, $count ) = splice @_;
    my $log = $self->{mlog};
    my $tail = "tail $log/main/current";

    $tail .= $count =~ /^\d+$/ ? " -n $count" : ' -f' if $count;
    system( "$tail | tai64nlocal" );
}

=head3 path()

Service path.

=cut
sub path
{
    my $self = shift;
    return $self->{path};
}

sub script
{
    local $| = 1;

    my ( $self, $path, $name ) = splice @_, 0, 3;
    my $handle = File::Temp->new( UNLINK => 0 );
    print $handle join "\n", @_;

    $path = File::Spec->join( $path, $name );
    my $move = sprintf "mv %s $path", $handle->filename();

    confess "failed to $move" if system $move;
    confess "chmod $path: $!" unless chmod 0544, $path;
    return $path;
}

package Vulcan::Daemon::Path;

use base qw( Vulcan::DirConf );

sub define { qw( conf service ) }

1;
