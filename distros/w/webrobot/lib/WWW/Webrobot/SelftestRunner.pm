package WWW::Webrobot::SelftestRunner;

# Author: Stefan Trcek
# Copyright(c) 2004 ABAS Software AG

use Exporter;
@EXPORT_OK = qw/ RunTestplan RunTestplan2 HttpdEcho Config /;

use strict;
use warnings;

use HTTP::Response;
use HTTP::Headers;
use URI;

use WWW::Webrobot;
use WWW::Webrobot::StupidHTTPD;


=head1 NAME

WWW::Webrobot::SelftestRunner - Start httpd and run a test plan

=head1 SYNOPSIS

 use WWW::Webrobot::SelftestRunner qw/RunTestplan HttpdEcho Config/;
 exit RunTestplan(HttpdEcho, Config(qw/Test/, $test_plan);

 exit RunTestplan(HttpdEcho, Config(qw/Test Html/, $test_plan);

see also t/get.t


=head1 DESCRIPTION

This package serves some functions to start a http daemon
and run a test plan.
It is only used for the test in the C<t/...> directory.


=head1 FUNCTIONS

=over

=item RunTestplan($serverfunc, $config, $testplan)

Run a C<WWW::Webrobot::StupidHTTPD> http daemon implementing C<$serverfunc>.
Then run a C<WWW::Webrobot> http client using the configuration C<$config>
and the testplan C<$testplan>.

=cut

sub RunTestplan {
    my ($exit, $webrobot) = RunTestplan2(@_);
    return $exit;
}

sub RunTestplan2 {
    my ($server_func, $config, $test_plan) = @_;

    my $daemon = WWW::Webrobot::StupidHTTPD -> new();
    $daemon -> start($server_func, fork_daemon => 1);

    $config .= "names=application=" . $daemon -> server_url() . "\n";
    my $webrobot = WWW::Webrobot -> new($config);
    my $exit = $webrobot -> run($test_plan);

    $daemon -> stop();

    return ($exit, $webrobot);
}


my $simple_html_text_0 = <<'EOF';
<html>
    <head>
        <title>A_Static_Html_Page</title>
    </head>
    <body>
        A simple text.
    </body>
</html>
EOF

my $simple_html_text_1 = <<'EOF';
<html>
    <body>
        Confuse perl regular expressions: [a-z]
        HTMLish&nbsp;text
    </body>
</html>
EOF

my $frame_0 = <<'EOF';
<html>
  <frameset cols='250,1*'>
    <frame name="menu" src="/constant_html_0">
    <frame name="Inhalt" src="/constant_html_1">
    <noframes>Your browser does not support frames.</noframes>
  </frameset>
</html>
EOF

my $ACTION = {
    # NOTE: depending on the key the HTTP response will be
    # text/html or text/plain
    url => sub {
        my ($connection, $request) = @_;
        $request -> uri();
    },
    content => sub {
        my ($connection, $request) = @_;
        $request -> content();
    },
    method => sub {
        my ($connection, $request) = @_;
        $request -> method();
    },
    headers => sub {
        my ($connection, $request) = @_;
        $request -> headers() -> as_string();
    },
    constant_html_0 => sub {
        my ($connection, $request) = @_;
        return $simple_html_text_0;
    },
    constant_html_1 => sub {
        my ($connection, $request) = @_;
        return $simple_html_text_1;
    },
    html_frame_0 => sub {
        my ($connection, $request) = @_;
        return $frame_0;
    },
    html_as_utf8 => sub {
        my ($connection, $request) = @_;
        my $path = $request->uri();
        my $file = $path || "";
        $file =~ s{^/*html_as_utf8/(.*)$}{$1};
        local *F;
        open F, "<$file" or die "Can't open '$file': $!";
        my $html = do { local $/; <F> };
        close F;
        return $html;
    },
    # 500 => sub {},
    # Don't use '500' as a key: some tests rely that this key doesn't exist!
};

=item HttpdEcho

A simple server function for the C<WWW::Webrobot::StupidHTTPD> http daemon.
It read the requested url C<http://server:port/action/anyting_else>
as an action where the action is denoted by the C<action> part within the url.
The result of the action is returned as content in the response.
Actions are

 url           echo the url as response content
 content       echo the content in the request as response content
 method        echo the method in the request as response content
 headers       echo a stringified form of the request headers as response content

=cut

sub HttpdEcho {
    my %parm = (@_);
    my $charset = $parm{charset} ? "; charset=" . $parm{charset} : "";
    my $plain_header = HTTP::Headers -> new(Content_Type => "text/plain$charset");
    my $html_header = HTTP::Headers -> new(Content_Type => "text/html$charset");
    return sub {
        my ($connection, $request) = @_;

        my $path = $request->uri();
        my $action = $path || "";
        $action =~ s{^/*([^/]+).*$}{$1};
        $action = "" if ! exists $ACTION->{$action};

        my $response = (exists $ACTION->{$action}) ?
            HTTP::Response -> new(
                200,
                undef,
                ($action =~ /html/) ? $html_header : $plain_header,
                $ACTION->{$action}->($connection, $request)
            ) : HTTP::Response -> new(500, undef, $plain_header, undef);
        $connection -> send_response($response);
    };
};


=item Config(Modulenames...)

Simple config string for C<WWW::Webrobot::Print::*> output.
Defaults to "Test" if no parameter is given.

Example:

 my $cfg = Config(qw/Html Test/);
 my $cfg = Config;

=cut

sub Config {
    push @_, "Test" if ! @_;
    return join "", map {"output=WWW::Webrobot::Print::$_\n"} @_;
}


=pod

=back

=cut

1;
