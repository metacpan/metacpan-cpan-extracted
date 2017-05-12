#!perl
package Test::WWW::Declare::Tester::Server;
use strict;
use warnings;
use base 'HTTP::Server::Simple::CGI';

my %content = (
   index => << "INDEX",
<h1>This is an index</h1>
<a href="good">good link</a>
<a href="bad">bad link</a>
<a href="good">same good link</a>
INDEX

   good => << "GOOD",
<h1>This is a good page</h1>
<a href="index">index</a>
<a href="bad">bad link</a>
<a href="good">infinite recursion</a>
GOOD

   formy => << "FORMY",
<h1>This page has two forms!</h1>
<form method="post" name="one" action="result1">
    <input type="text" size="20" name="clever" />
    <input type="submit" size="20" value="sub-mits" />
</form>
<form method="get" name="two" action="result2">
    <input type="text" size="20" name="clever" />
    <input type="submit" size="20" value="sub-mits 2" />
</form>
FORMY

    result1 => sub {
        my $cgi = shift; my $clever = $cgi->param('clever');
        return "<h1>\U$clever\E</h1>";
    },

    result2 => sub {
        my $cgi = shift; my $clever = $cgi->param('clever');
        return "<h1>\L$clever\E</h1>";
    },

);

sub wrap_content
{
    my ($url, $content) = @_;
    $content =~ s/^/        /mg;

    $content = << "WRAPPER";
<html>
    <head>
        <title>\U$url\E</title>
    </head>
    <body>
$content
    </body>
</html>
WRAPPER

    return $content;
}

sub get {
    my $page = (split '/', shift)[-1];
    $page ||= 'index';
    $page =~ s/\s+//g;

    my $content = $content{$page};

    return if !defined($content);
    return wrap_content($page, $content->(@_)) if ref($content) eq 'CODE';
    return wrap_content($page, $content);
}

sub handle_request {
    my $self = shift;
    my $cgi = shift;

    if (my $content = get($cgi->path_info, $cgi)) {
        print "HTTP/1.0 200 OK\r\n";
        print "Content-Type: text/html\r\nContent-Length: ",
              length($content),
              "\r\n\r\n",
              $content;
        return;
    }

    print "HTTP/1.0 404 Not Found\r\n\r\n";
}

package Test::WWW::Declare::Tester;
use Test::Tester;
use Test::WWW::Declare;
use base 'Test::More';

our $VERSION = '0.02';
our @EXPORT = qw($PORT $SERVER $PID);

our $PORT = 12321;
our $SERVER = Test::WWW::Declare::Tester::Server->new($PORT);
our $PID = $SERVER->background or die "Cannot start the server";
sleep 1;

sub import_extra {
    Test::Tester->export_to_level(2);
    Test::WWW::Declare->export_to_level(2);
    Test::More->export_to_level(2);
}

END {
    kill(9, $PID);
}

1;

