package TiVo::HME::Server;

use 5.008;
use strict;
use warnings;

our $VERSION = '1.2';

use TiVo::HME::IO;
use TiVo::HME::Context;

use Digest::MD5 qw(md5_hex);
use CGI::Cookie;
use HTTP::Daemon;
use HTTP::Status;
use POSIX ':sys_wait_h';

use constant DEFAULT_PORT => 7288;
use constant ACCEPTOR_NAME => 'Acceptor';
use constant MAGIC => 0x53425456;
use constant VERSION_MAJOR => 0;
use constant VERSION_MINOR => 36;
use constant VERSION => (VERSION_MAJOR << 8) | VERSION_MINOR;
use constant VERSION_STRING => VERSION_MAJOR . '.' . VERSION_MINOR;
use constant MIME_TYPE => 'application/x-hme';
use constant TIVO_DURATION => 'X-TiVo-Accurate-Duration';

sub REAPER {
    my $child;

    1 while (($child = waitpid(-1, WNOHANG)) > 0);
    $SIG{CHLD} = \&REAPER;

}

$SIG{PIPE} = 'IGNORE';

sub new {
        my ($class) = shift;
        my $d = HTTP::Daemon->new(
                LocalPort => DEFAULT_PORT,
                ReuseAddr => 1,
        );
        #print STDERR "\nPlease contact me at: <URL:", $d->url, ">\n";

    $SIG{CHLD} = \&REAPER;

        my $self = { server => $d };
        bless $self, $class;
}

sub start {
        my ($self) = shift;
        while (my($c, $peer) = $self->{server}->accept) {

        # fork it off
        my $pid = fork;
        die "Cannot fork\n" unless defined $pid;
        do { close $c; next; } if $pid;

                while (my $r = $c->get_request) {
                        $c->autoflush;

                        if ($r->method eq 'GET') {
                                # do something w/cookie...
                                my %cookies = CGI::Cookie->parse($r->header('Cookie'));
                                my $id;

                                $c->send_status_line;
                                $c->print('Content-type: ' . MIME_TYPE);
                                $c->send_crlf;
                                # drop in a cookie
                                unless (%cookies) {
                                        $id = generate_id();
                                        my $cookie = new CGI::Cookie(-name => 'id',
                                                                                        -value => $id,
                                                                                        -expires => '+20Y',
                                                                                        -path => '/');
                                        $c->print("Set-Cookie: $cookie");
                                        $c->send_crlf;
                                } else {
                                        $id = (keys %cookies)[0];
                                        $id = $cookies{$id}->value;
                                }

                                #end header
                                $c->send_crlf;

                                # dump SBTV & VERSION
                                $c->print(pack('N', MAGIC));
                                $c->print(pack('N', 0x0, 0x0, VERSION_MAJOR, VERSION_MINOR));

                                my($magic, $rv);

                                $c->sysread($magic, 4);
                                die "Bad Magic!\n" if ($magic ne 'SBTV');

                                $c->sysread($rv, 4);
                                $rv = unpack('N', $rv);
                                die "Bad Version!\n" if ($rv != VERSION);

                                # New chunked encoded IO stream
                                my $io = TiVo::HME::IO->new($c);

                                # Create a new App Context
                                my $context = TiVo::HME::Context->new(
                                        cookie => $id,
                                        connexion => $io,
                                        request => $r,
                                        peer => $peer,
                                );

                print STDERR ref $peer;

                                # Create the App
                                my $app_name;
                                ($app_name .= $r->url->path) =~ s#/##g;
                                $app_name = $app_name . '.pm';

                                eval { require "$app_name" };
                if ($@) {
                    print STDERR "\nI don't know where to find: $app_name!\n";
                    return;
                }

                                my $obj_name;
                                ($obj_name = $app_name) =~ s/\.pm$//;

                                # Sorta assuming app object is a subclass of
                                #        TiVo::HME::Application
                unless ($obj_name->isa('TiVo::HME::Application')) {
                    print STDERR
                        "$obj_name not a subclass of TiVo::HME::Application!\n";
                    last;
                }
                                my $app = $obj_name->new;
                                $app->set_context($context);
                                $app->init($context);

                                $app->read_events;
                        }
                        else {
                                $c->send_error(RC_FORBIDDEN)
                        }
            print STDERR "REQUEST DONE!!\n";
                }
                $c->close;
                undef($c);
        }
}

# ** Note ** This is intended to be unique, not unguessable. 
sub generate_id {
        my $id = md5_hex(md5_hex(time.{}.rand().$$)); 
        $id =~ tr|+/=|-_.|;     # make non-word characters URL friendly 
        $id;
}

1;

__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

TiVo::HME::Server - HTTP server & dispatcher for TiVo::HME

=head1 SYNOPSIS

  use TiVo::HME::Server;
  use lib qw(...);  # path to your TiVo apps
  TiVo::HME::Server->start;

=head1 DESCRIPTION

Handle connections from TiVos by finding your app & starting it.
A URL like http://localhost/myapp will cause this to load 'myapp.pm'
& start it by calling its 'init' method passing in a reference to
itself & the context.

=head1 SEE ALSO

http://tivohme.sourceforge.net
TiVo::HME::Application
TiVo::HME::HME.pm

=head1 AUTHOR

Mark Ethan Trostler, E<lt>mark@zzo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Mark Ethan Trostler

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
