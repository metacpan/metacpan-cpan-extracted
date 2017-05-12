use strict;
use warnings;

use HTTP::Server::Simple;
use HTTP::Server::Simple::CGI;
use Test::Deep;
use Test::More;
use WebDriver::Tiny;

my ( $pid, %pids ) = $$;

END { if ( $$ == $pid ) { kill 15, $_ for values %pids } }

# FIXME Travis doesn't have ChromeDriver.
my $has_chromedriver = grep -x "$_/chromedriver", split /:/, $ENV{PATH};

if ($has_chromedriver) {
    exec qw/chromedriver/ or exit unless $pids{ChromeDriver} = fork;
}

exec qw/phantomjs -w/ or exit unless $pids{PhantomJS} = fork;

{
    no warnings 'redefine';

    *HTTP::Server::Simple::print_banner = sub {};

    local ( @ARGV, $/ ) = 'xt/test.html';

    utf8::decode our $html = my $bytes = <>;

    *HTTP::Server::Simple::CGI::handle_request = sub {
        print "HTTP/1.0 200 OK\nContent-Type:text/html;charset=UTF-8\n",
            "Content-Length:", length $bytes, "\n\n", $bytes;
    };
}

$pids{HTTPServerSimple} = HTTP::Server::Simple->new->background;

sleep 2;    # FIXME Give everyone enough time to start.

my %tests = map { /(\w+)\./ => require } <xt/*.pl>;

for (
    {   args => {
            capabilities => {
                chromeOptions => { binary => '/usr/bin/google-chrome-unstable' },
            },
            port => 9515,
        },
        capabilities => {
            acceptSslCerts           => bool(1),
            applicationCacheEnabled  => bool(0),
            browserConnectionEnabled => bool(0),
            browserName              => 'chrome',
            chrome                   => { userDataDir => re(qr(^/tmp/)) },
            cssSelectorsEnabled      => bool(1),
            databaseEnabled          => bool(0),
            handlesAlerts            => bool(1),
            hasTouchScreen           => bool(0),
            javascriptEnabled        => bool(1),
            locationContextEnabled   => bool(1),
            mobileEmulationEnabled   => bool(0),
            nativeEvents             => bool(1),
            platform                 => 'Linux',
            rotatable                => bool(0),
            takesHeapSnapshot        => bool(1),
            takesScreenshot          => bool(1),
            version                  => re(qr/^[\d.]+$/),
            webStorageEnabled        => bool(1),
        },
        name       => 'ChromeDriver',
        user_agent => qr/Chrome/,
    },
    {   args => { port => 8910 },
        capabilities => {
            acceptSslCerts           => bool(0),
            applicationCacheEnabled  => bool(0),
            browserConnectionEnabled => bool(0),
            browserName              => 'phantomjs',
            cssSelectorsEnabled      => bool(1),
            databaseEnabled          => bool(0),
            driverName               => 'ghostdriver',
            driverVersion            => re(qr/^[\d.]+$/),
            handlesAlerts            => bool(0),
            javascriptEnabled        => bool(1),
            locationContextEnabled   => bool(0),
            nativeEvents             => bool(1),
            platform                 => re(qr/linux/),
            proxy                    => { proxyType => 'direct' },
            rotatable                => bool(0),
            takesScreenshot          => bool(1),
            version                  => re(qr/^[\d.]+$/),
            webStorageEnabled        => bool(0),
        },
        name       => 'PhantomJS',
        user_agent => qr/PhantomJS/,
    },
) {
    next if !$has_chromedriver && $_->{name} eq 'ChromeDriver';

    note $_->{name};

    my $drv = WebDriver::Tiny->new( %{ $_->{args} } );

    cmp_deeply $drv->capabilities, $_->{capabilities}, 'capabilities';

    like $drv->user_agent, $_->{user_agent}, 'user_agent';

    $drv->get('http://localhost:8080');

    for ( sort keys %tests ) {
        note $_;

        $tests{$_}($drv);
    }
}

done_testing;
