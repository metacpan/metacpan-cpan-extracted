package MIO::SSH;

=head1 NAME

MIO::SSH - Run multiple SSH commands in parallel.

=head1 SYNOPSIS
 
 use MIO::SSH;

 my @node = qw( host1 host2 ... );
 my @cmd = qw( uptime );

 my $ssh = MIO::SSH->new( map { $_ => \@cmd } @node );
 my $result = $ssh->run( max => 32, timeout => 300 );

 my $output = $result->{output};
 my $error = $result->{error};

=cut
use strict;
use warnings;

use Carp;
use Expect;
use Tie::File;
use Fcntl qw( :flock );
use POSIX qw( :sys_wait_h );
use FindBin qw( $Script );

use base qw( MIO );

our %RUN = %MIO::RUN;
our $SSH = 'ssh -o StrictHostKeyChecking=no -c blowfish';

local $| = 1;

sub new
{
    my $self = shift;
    $self->cmd( @_ );
}

=head1 METHODS

=head3 run( %param )

Run ssh commands in parallel.
The following parameters may be defined in I<%param>:

 max : ( default 128 ) number of commands in parallel.
 timeout : ( default 300 ) number of seconds allotted for each command.
 sudo : ( default no sudo ) remote sudo user
 user : ( default logname ) connect as user
 pass : password

=cut
sub run
{
    local $/ = "\n";

    my $self = shift;
    my @node = keys %$self;
    my ( %run, %result, %busy ) = ( %RUN, @_ );
    my ( $ext, $prompt ) = ( "$Script.$$", 'password:' );
    my ( $max, $timeout, $user, $sudo, $pass, $lock ) =
        @run{ qw( max timeout user sudo pass lock ) };

    $user = `logname` unless defined $user; $user =~ s/\n*//g;
    $pass .= "\n" unless defined $pass && $pass =~ /\n$/g;

    $SIG{INT} = $SIG{TERM} = sub
    {
        local $SIG{INT} = $SIG{INT};

        kill 9, keys %busy;
        unlink $lock if $lock;
        unlink glob "/tmp/*.$ext";

        print STDERR "killed\n";
        exit 1;
    };

    do
    {
        while ( @node && keys %busy < $max )
        {
            my $node = shift @node;
            my $cmd = $self->{$node};
            my @cmd = map { my $t = $_; $t =~ s/{}/$node/g; $t } @$cmd;
            my $log = "/tmp/$node.$ext";
            my $ssh = "$SSH -l $user $node ";

            $ssh .= join ' ',
                $sudo ? map { "sudo -p '$prompt' -u $sudo $_" } @cmd : @cmd;

            if ( $run{noop} ) { warn "$ssh\n"; next }
            if ( my $pid = fork() ) { $busy{$pid} = [ $log, $node ]; next }
            
            my $exp = Expect->new();
            my $login = sub { $exp->send( $pass ); exp_continue };

            $exp->log_file( $log, 'w' );

            if ( $exp->spawn( $ssh ) )
            {
                my $fh; flock $fh, LOCK_EX if $lock && open $fh, '>', $lock;
                $exp->expect( $timeout, [ qr/$prompt\s*$/ => $login ] );
            }
            exit 0;
        }

        for ( keys %busy )
        {
            my $pid = waitpid( -1, WNOHANG );
            next if $pid <= 0;

            my ( $log, $node ) = @{ delete $busy{$pid} };
            tie my @log, 'Tie::File', $log;

            my @i = grep { $log[$_] =~ /$prompt/ } 0 .. $#log;
            splice @log, 0, $i[-1] + 1 if @i;

            push @{ $result{output}{ join "\n", @log, '' } }, $node if @log;
            unlink $log;
        }
    }
    while @node || %busy;

    unlink $lock if $lock;
    return wantarray ? %result : \%result;
}

1;
