use strictures;

use Test::More 0.88;
use Web::Simple::Application;
use Socket;

run();
done_testing;

sub run {

    my $a = Web::Simple::Application->new;

    my ( $cli, $cgi, $fcgi, $test ) = qw( cli cgi fcgi test );

    my $res;
    no warnings 'redefine';
    local *Web::Simple::Application::_run_fcgi             = sub { $res = "fcgi" };
    local *Web::Simple::Application::_run_cgi              = sub { $res = "cgi" };
    local *Web::Simple::Application::_run_cli              = sub { $res = "cli" };
    local *Web::Simple::Application::_run_cli_test_request = sub { $res = "test" };
    use strictures;

    {
        $a->run;
        is $res, "cli", "empty invocation goes to CLI mode";
    }

  SKIP: {
        skip "windows does not support the needed socket manipulation", 2 if $^O eq 'MSWin32' or $^O eq 'cygwin';
        {
            socket my $socket, AF_INET, SOCK_STREAM, 0 or die "socket: $!";
            open my $old_in, '<&STDIN' or die "open: $!";
            open STDIN, '<&', $socket or die "open: $!";
            $a->run;
            is $res, "fcgi", "STDIN being a socket means FCGI";
            open STDIN, '<&', $old_in or die "open: $!";
        }

        {
            local $ENV{GATEWAY_INTERFACE} = "CGI 1.1";
            socket my $socket, AF_INET, SOCK_STREAM, 0 or die "socket: $!";
            open my $old_in, '<&STDIN' or die "open: $!";
            open STDIN, '<&', $socket or die "open: $!";
            $a->run;
            isnt $res, "fcgi", "STDIN being a socket doesn't mean FCGI if GATEWAY_INTERFACE is set";
            open STDIN, '<&', $old_in or die "open: $!";
        }
    }

    return;
}
