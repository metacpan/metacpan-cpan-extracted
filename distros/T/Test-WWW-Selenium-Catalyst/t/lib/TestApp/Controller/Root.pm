#!/usr/bin/perl
# Root.pm 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

package TestApp::Controller::Root;
use base qw(Catalyst::Controller);
__PACKAGE__->config->{namespace} = q{};
my @words = qw(foo bar baz bat qux quux);

sub index : Private {
    my ($self, $c, @args) = @_;
    my $words = $c->uri_for('/words');
    $c->response->body(<<"HERE");
<html>
<head>
<title>TestApp</title>
</head>
<body>
<h1>TestApp</h1>
<p>This is the TestApp.</p>
<p><a href="$words">Click here</a> to <i>see</i> some words.</p>
</body>
</html>    
HERE
}

sub words : Local {
    my ($self, $c, $times) = @_;
    $times ||= 0;
    my $html = <<"HEADER";
<html>
<head>
<title>TestApp</title>
</head>
<body>
<h1>TestApp &lt;&lt; Words</h1>
<p>Here you'll find all things "words" printed $times time(s)!</p>
<ul>
HEADER
    local $" = q{ }; # single space
    $html .= " <li>$_: @words</li>\n" for 1..$times;
    $html .= <<"FOOTER"; 
</ul>
</body>
</html>
FOOTER
    $c->response->body($html);
}

sub null : Path('/favicon.ico'){
    my ($self, $c) = @_;
    $c->response->status(404); # doesn't exist
}

1; # true.

