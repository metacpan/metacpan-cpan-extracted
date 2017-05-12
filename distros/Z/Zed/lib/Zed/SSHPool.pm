package Zed::SSHPool;

use Zed::Config::Env;
use Zed::Config::Space;
use Zed::Output;

use Net::OpenSSH;
use strict;

=head1 NAME

Zed::SSHPool - manage ssh connection.

=head1 SYNOPSIS

    use Zed::SSHPool;

    Zed::SSHPool::run(\@host => 'cmd', @cmd);
    Zed::SSHPool::run(\@host => 'get', { %OPT }, @files);
    Zed::SSHPool::run(\@host => 'put', { %OPT }, @files);

=cut

our %OPT = 
( 
    async                 => 1, 
    expand_vars           => 1,
    master_stderr_discard => 1, 
    master_stdout_discard => 1, 
    master_opts           => [-o => "ConnectTimeout=3", -o => "StrictHostKeyChecking=no"],
);

my %ssh;

sub get_ssh { $ssh{ $_[0] } }

sub connect
{
    my(%error, $user, $pwd);

    $user = env("username");
    $pwd = passwd();

    for my $host(@_)
    {
        $ssh{$host} && !$ssh{$host}->check_master && delete $ssh{$host};
        $ssh{$host} ||= Net::OpenSSH->new( $host, user => $user, password => $pwd, %OPT);
    }

    for my $host(@_)
    {
        $ssh{$host}->wait_for_master(0);

        if($ssh{$host}->error)
        {
            $error{$host} = $ssh{$host}->error;
            delete $ssh{$host};
        }
    }

    wantarray ? %error : \%error;
}

sub run
{
    my($hosts, $type, @params) = @_;

    my(%result, @fail, @suc, $count) = Zed::SSHPool::connect(@$hosts);

    for my $host(@$hosts)
    {
        $count += 1;
        my($c_str, $ssh, $output) = "$count/". scalar @$hosts;

        if( $result{$host} )
        {
            result($c_str, 0, "$host done..");
            push @fail, $host;
            next;
        }

        $ssh = Zed::SSHPool::get_ssh( $host );
        
        if($type eq 'cmd')
        {

            $output = $ssh->capture( @params );
            $result{$host} = $output;
    
        }elsif($type eq 'get'){

            $ssh->scp_get( @params );

        }elsif($type eq 'put'){

            $ssh->scp_put( @params );
        }

        result($c_str, !$ssh->error, "$host done..");
        $ssh->error ? push @fail, $host
                    : push @suc,  $host;
    }

    (\@suc, \@fail, \%result);

}


1;

__END__
