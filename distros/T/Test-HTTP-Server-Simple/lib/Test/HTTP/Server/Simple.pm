package Test::HTTP::Server::Simple;

our $VERSION = '0.11';

use warnings;
use strict;
use Carp;

use NEXT;

use Test::Builder;
my $Tester = Test::Builder->new;

use constant WIN32 => $^O =~ /win32/i;

my $Event; # used on win32 only
if (WIN32) {
    require Win32::Event;
    $Event = Win32::Event->new();
}

=head1 NAME

Test::HTTP::Server::Simple - Test::More functions for HTTP::Server::Simple


=head1 SYNOPSIS

    package My::WebServer;
    use base qw/Test::HTTP::Server::Simple HTTP::Server::Simple/;
    
    package main;
    use Test::More tests => 42;
    
    my $s = My::WebServer->new;

    my $url_root = $s->started_ok("start up my web server);

    # connect to "$url_root/cool/site" and test with Test::WWW::Mechanize,
    # Test::HTML::Tidy, etc

  
=head1 DESCRIPTION

This mixin class provides methods to test an L<HTTP::Server::Simple>-based web
server.  Currently, it provides only one such method: C<started_ok>.

=head2 started_ok [$text]

C<started_ok> takes 
an optional test description.  The server needs to have been configured (specifically,
its port needs to have been set), but it should not have been run or backgrounded.
C<started_ok> calls C<background> on the server, which forks it to run in the background.
L<Test::HTTP::Server::Simple> takes care of killing the server when your test script dies,
even if you kill your test script with an interrupt.  C<started_ok> returns the URL 
C<http://localhost:$port> which you can use to connect to your server.

Note that if the child process dies, or never gets around to listening for connections, this
just hangs.  (This may be fixed in a future version.)

Also, it probably won't work if you use a custom L<Net::Server> in your server.

=cut

my @CHILD_PIDS;

# If an interrupt kills perl, END blocks are not run.  This
# essentially converts interrupts (like CTRL-C) into a standard
# perl exit (even if we're inside an eval {}).
$SIG{INT} = sub { exit };

# In case the surrounding 'prove' or similar harness got the SIGINT
# before we did, and hence STDERR is closed.
$SIG{PIPE} = 'IGNORE';

END {
    local $?;
    if (WIN32) {
        # INT won't do since the server is doing a blocking read
        # which isn't interrupted by anything but KILL on win32.
        kill 9, $_ for @CHILD_PIDS;
        sleep 1;
        foreach (@CHILD_PIDS) {
            sleep 1 while kill 0, $_;
        }
    }
    else {
        @CHILD_PIDS = grep {kill 0, $_} @CHILD_PIDS;
        if (@CHILD_PIDS) {
            kill 'USR1', @CHILD_PIDS;
            local $SIG{ALRM} = sub {
                use POSIX ":sys_wait_h";
                my @last_chance = grep { waitpid($_, WNOHANG) == -1 }
                    grep { kill 0, $_ } @CHILD_PIDS;
                die 'uncleaned Test::HTTP::Server::Simple processes: '.join(',',@last_chance)
                    if @last_chance;
            };
            alarm(5);
            eval {
                my $pid;
                @CHILD_PIDS = grep {$_ != $pid} @CHILD_PIDS
                  while $pid = wait and $pid > 0 and @CHILD_PIDS;
                @CHILD_PIDS = () if $pid == -1;
            };
            die $@ if $@;
            alarm(0);
        }
    }
} 

sub started_ok {
    my $self = shift;
    my $text   = shift;
    $text = 'started server' unless defined $text;

    my $port = $self->port;
    my $pid;

    $self->{'test_http_server_simple_parent_pid'} = $$;

    my $child_loaded_yet = 0;

    # So this is a little complicated.  The following signal handler does two
    # ENTIRELY DIFFERENT things:
    #
    #  In the parent, it just sets $child_loaded_yet, which breaks out of the
    #  while loop below.  It's activated by the kid sending it a SIGUSR1 after
    #  it runs setup_listener
    #
    #  In the kid, it sets the variable, but that's basically pointless since
    #  the call to ->background doesn't actually return in the kid.  But also,
    #  it exits.  And when you actually exit with 'exit' (as opposed to being
    #  killed by a signal) END blocks get run.  Which means that you can use
    #  Devel::Cover to test the kid's coverage.  This one is activated by the
    #  parent's END block in this file.

    local %SIG;
    if (not WIN32) {
        $SIG{'USR1'} = sub { $child_loaded_yet = 1; exit unless $self->{'test_http_server_simple_parent_pid'} == $$ }
    }

    # XXX TODO FIXME should somehow not have the signal handler around in the
    # kid
    # Comment: How about if ($pid) { $SIG{'USR1'} = ... }?
    
    eval { $pid = $self->background; };

    if ($@) {
        my $error_text = $@;  # In case the next line changes it.
        $Tester->ok(0, $text);
        $Tester->diag("HTTP::Server::Simple->background failed: $error_text");
        return;
    }

    unless ($pid =~ /^-?\d+$/) {
        $Tester->ok(0, $text);
        $Tester->diag("HTTP::Server::Simple->background didn't return a valid PID");
        return;
    } 

    push @CHILD_PIDS, $pid;

    if (WIN32) {
        $Event->wait();
    }
    else {
        1 while not $child_loaded_yet;
    }

    $Tester->ok(1, $text);

    return "http://localhost:$port";
}

=begin private

=head2 setup_listener

We send a signal to the parent here.  We need to use NEXT because this is a mixin.

=end private

=cut

sub setup_listener {
    my $self = shift;
    $self->NEXT::setup_listener;
    if (WIN32) {
        $Event->pulse();
    }
    else {
        kill 'USR1', $self->{'test_http_server_simple_parent_pid'};
    }
}

=head2 pids

Returns the PIDs of the processes which have been started.  Since
multiple test servers can be running at one, be aware that this
returns a list.

=cut

sub pids {
    return @CHILD_PIDS;
}

=head1 DEPENDENCIES

L<Test::Builder>, L<HTTP::Server::Simple>, L<NEXT>.


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

Installs an interrupt signal handler, which may override any that another part
of your program has installed.

Please report any bugs or feature requests to
C<bug-test-http-server-simple@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

David Glasser  C<< <glasser@bestpractical.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2005, Best Practical Solutions, LLC.  All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

1;

