package Zed::Plugin::Exe::Put;

use Zed::Plugin;
use Zed::Output;
use Zed::Config::Env;
use Zed::Config::Space;
use strict;

=head1 SYNOPSIS

    put localfile remotefile 
    ex:
        put /tmp/foo /tmp/bar

=cut

our %OPT = ( glob => 1, recursive => 1, quiet => 0 );

invoke "put" => sub {

    my ( @files, @host) =  @_;

    return unless @host = targets();

    Zed::SSHPool::run(\@host => 'put', { %OPT }, @files);
};
1;
