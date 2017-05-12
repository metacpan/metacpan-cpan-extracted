#!perl

use strict;
use warnings;

package HTTP::Daemon::MockClient;

use HTTP::Daemon;
use base qw(HTTP::Daemon::ClientConn);

use HTTP::Status qw(:constants);
use Params::Util qw(_ARRAY _STRING);

my %documents = (
    "/etc/passwd" => [
                       "root:x:0:0:root:/root:/bin/sh", "daemon:x:1:1:daemon:/usr/sbin:/bin/sh",
                       "bin:x:2:2:bin:/bin:/bin/sh"
                     ],
    "/etc/fstab" => [
                      "# <file system> <mount point>   <type>  <options>       <dump>  <pass>",
                      "proc            /proc           proc    nodev,noexec,nosuid 0       0",
                      "/dev/sda1       /               ext2    defaults        0       0",
                      "/dev/sdb1       /data           ext2    defaults        0       0",
                      "none            /tmp            tmpfs   defaults,noatime        0       0",
                    ],
    "/etc/master.passwd"  => "/etc/master.passwd",
    "/var/run/dmesg.boot" => [
        '[    0.000000] Initializing cgroup subsys cpuset',
        '[    0.000000] Initializing cgroup subsys cpu',
        '[    0.000000] Linux version 2.6.32-41-generic (buildd@allspice) (gcc version 4.4.3 (Ubuntu 4.4.3-4ubuntu5.1) ) #94-Ubuntu SMP Fri Jul 6 18:00:34 UTC 2012 (Ubuntu 2.6.32-41.94-generic 2.6.32.59+drm33.24)'
    ],
    "/var/log/messages" => "/var/run/dmesg.boot",
);

sub respond_text_content
{
    my ( $c, @cnt ) = @_;
    my $resp = HTTP::Response->new(HTTP_OK);
    $resp->header( "Content-Type", "text/plain" );
    $resp->content( join( "\n", @cnt ) );
    $c->send_response($resp);
}

sub handle_httpd_get
{
    my ( $c, $req ) = @_;
    my $p = $req->uri()->path();
    if ( exists( $documents{$p} ) )
    {
        if ( _ARRAY( $documents{$p} ) )
        {
            $c->respond_text_content( @{ $documents{$p} } );
        }
        elsif ( _STRING( $documents{$p} ) )
        {
            my $tgt = $documents{$p};
            if ( $p eq $tgt )
            {
                $c->send_error(HTTP_I_AM_A_TEAPOT);
                $c->send_crlf;
                return 0 - HTTP_I_AM_A_TEAPOT;
            }
            else
            {
                $c->send_redirect( $tgt, HTTP_TEMPORARY_REDIRECT );
                $c->send_crlf;
            }
        }
        else
        {
            $c->send_error(HTTP_FORBIDDEN);
            $c->send_crlf;
        }
    }
    else
    {
        $c->send_error(HTTP_NOT_FOUND);
        $c->send_crlf;
    }

    return 0;
}

package main;

use Getopt::Long;

use HTTP::Daemon;
use HTTP::Status qw(:constants);

my %opts = ();
GetOptions( "httpd-opts=s%" => \%opts );

my $d = HTTP::Daemon->new(%opts);

print "Please to meet you at: <URL:", $d->url, ">\n";
open( STDOUT, $^O eq 'VMS' ? ">nl: " : ">/dev/null" );

my $go = 1;
while ( $go and my $c = $d->accept("HTTP::Daemon::MockClient") )
{
    while ( my $r = $c->get_request )
    {
        my $func = lc( "handle_httpd_" . $r->method );
        if ( $c->can($func) )
        {
            0 == $c->$func($r) or $go = 0;
        }
        else
        {
            $c->send_error(HTTP_METHOD_NOT_ALLOWED);
        }
    }
    $c = undef;    # close connection
}
$opts{hdf} or print STDERR "HTTP Server terminated\n";
exit;

