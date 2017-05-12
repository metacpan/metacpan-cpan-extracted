package Zed::Plugin::Exe::Cmd;
use Zed::Plugin;

use Zed::SSHPool;
use Zed::Config::Env;
use Zed::Config::Space;
use Zed::Output;

use strict;

=head1 SYNOPSIS

    cmd CMD 
    ex:
        cmd ls /
        cmd echo hello

=cut


our %CMD = ( quote_args => 0, stderr_discard => 1);

invoke "cmd" => sub {
    my (@cmd, $pwd, @host) = @_;

    $pwd = passwd();
    return unless @host = targets();

    debug("host: ", \@host );

    if($cmd[0] eq 'sudo')
    {
        shift @cmd;
        @cmd = ( { stdin_data => "$pwd\n", %CMD }, 'sudo -k;', 'sudo', '-S', '-p', '', '--', @cmd );

    }else{

        @cmd = ( { %CMD }, @cmd );
    }
    
    debug("last cmd: |" => \@cmd);

    Zed::SSHPool::run(\@host => 'cmd', @cmd);
};

1;
