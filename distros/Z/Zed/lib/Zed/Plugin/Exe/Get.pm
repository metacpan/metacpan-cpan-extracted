package Zed::Plugin::Exe::Get;

use Zed::Plugin;
use Zed::Output;
use Zed::Config::Env;
use Zed::Config::Space;

use strict;

=head1 SYNOPSIS

    get remotefile localfile
    ex:
        get /tmp/foo /tmp/bar

=cut

our %OPT = ( glob => 1, recursive => 1, stdout_discard => 1,stderr_discard => 1 );

invoke "get" => sub {
    my ( @files, @host) =  @_;

    return unless @files and @host = targets();

    if(@files == 1)
    {
        push @files, $files[-1]. "@%HOST%"

    }elsif( -d $files[-1]){

        $files[-1] .= "/%HOST%";
    }else{

        $files[-1] .= "@%HOST%";
    }
    
    Zed::SSHPool::run(\@host => 'get', { %OPT }, @files);
};
1;
