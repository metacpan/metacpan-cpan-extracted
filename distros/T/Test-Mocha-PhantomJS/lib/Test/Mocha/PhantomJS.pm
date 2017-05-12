package Test::Mocha::PhantomJS;

use strict;
use warnings;

use Exporter qw(import);
use Net::EmptyPort qw(empty_port wait_port);
use Scope::Guard qw(scope_guard);

our $VERSION = '0.01';
our @EXPORT = qw(test_mocha_phantomjs);
our @EXPORT_OK = @EXPORT;

sub test_mocha_phantomjs {
    my %args = @_ == 1 ? %{$_[0]} : @_;
    Carp::croak("missing mandatory parameter 'server'")
        unless exists $args{server};
    %args = (
        auto_skip => undef,
        max_wait  => 10,
        build_uri => sub {
            my $port = shift;
            "http://127.0.0.1:$port/";
        },
        %args,
    );

    if ($args{auto_skip}) {
        system "which mocha-phantomjs > /dev/null";
        if ($? != 0) {
            require "Test/More.pm";
            Test::More::plan(skip_all => "could not find mocha-phantomjs");
        }
    }

    my $client_pid = $$;

    # determine empty port
    my $port = empty_port();

    # start server
    my $server_pid = fork;
    die "fork failed:$!"
        unless defined $server_pid;
    if ($server_pid == 0) {
        eval {
            $args{server}->($port);
        };
        # should not reach here
        warn $@;
        die "[Test::Mocha::PhantomJS] server callback should not return";
    }

    # setup guard to kill the server
    my $guard = scope_guard sub {
        kill 'TERM', $server_pid;
        waitpid $server_pid, 0;
        print STDERR "hi";
    };

    # wait for the port to start
    wait_port($port, $args{max_wait});

    # run the test
    system qw(mocha-phantomjs -R tap), $args{build_uri}->($port);
    my $status = $?;

    undef $guard; # stop the server

    if ($status == 1) {
        die "failed to execute mocha-phantomjs: $status";
    } elsif (($status & 127) != 0) {
        die "mocha-phantomjs died with signal " . ($status & 127);
    } else {
        warn "mocha-phantomjs exitted with: $status";
        exit $status >> 8;
    }
}

1;
__END__

=head1 NAME

Test::Mocha::PhantomJS - test your server code using mocha

=head1 SYNOPSIS

  use Test::Mocha::PhantomJS;

  test_mocha_phantomjs(
      server => sub {
          my $port = shift;
          # start server at $port that returns the test code
          # for mocha-phantomjs
          ...
      },
  );

=head1 DESCRIPTION

Test::Mocha::PhantomJS is a wrapper of L<mocha-phantomjs>.  By using the module, it is easy to automatically test your server-side logic simply by writing the tests written using L<mocha>.

=head1 USAGE

=head2 test_mocha_phantomjs(%args)

This is the only function exposed by the module.  When called, the function invokes the C<server> callback, and when the server starts up, invokes L<mocha-phantomjs> to run the test scripts.  Note that the function never returns.

The arguments accepted by the function is as follows.

=head3 server (mandatory)

A callback to start the server.  The callback should start a server running at the specilied port (notified as the only argument to the callback) that should keep on running until a SIGTERM is being received.

=head3 build_uri (optional)

A callback for building the URL that is opened by L<mocha-phantomjs>.  If omitted, L<mocha-phantomjs> will open http://127.0.0.1:$port/index.html.

=head3 max_wait (optional)

Will wait for at most given seconds before checking port.  See also: L<Net::EmptyPort>.  The default value is 10 (seconds).

=head3 auto_skip (optional)

A boolean value indicating if the test should be skipped in case L<mocha-phantomjs> cannot be found.  The default value is false (i.e. do not skip).

=head1 AUTHOR

Kazuho Oku

Copyright (c) 2013 DeNA Co., Ltd.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
