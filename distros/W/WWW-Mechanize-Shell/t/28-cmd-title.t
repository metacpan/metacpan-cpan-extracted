#!/usr/bin/perl -w
use strict;
use lib './inc';
use IO::Catch;

our $_STDOUT_;
tie *STDOUT, 'IO::Catch', '_STDOUT_' or die $!;

# Disable all ReadLine functionality
$ENV{PERL_RL} = 0;
delete $ENV{PAGER}
  if $ENV{PAGER};
$ENV{PERL_HTML_DISPLAY_CLASS}="HTML::Display::Dump";

use Test::More tests => 6;

use_ok('WWW::Mechanize::Shell');
my $s = WWW::Mechanize::Shell->new( 'test', rcfile => undef, warnings => undef );
isa_ok $s, 'WWW::Mechanize::Shell';

SKIP: {
    $s->agent->{base} = 'http://example.com';
    $s->agent->update_html(<<HTML);
            <html>
                <head><base href="http://example.com" />
		<title>An HTML page</title>
		</head>
                <body>Some body</body>
            </html>
HTML
    $s->cmd('title');
    chomp $_STDOUT_;
    is($_STDOUT_,"An HTML page", "Title gets output correctly");

    undef $_STDOUT_;
    $s->agent->update_html(<<HTML);
            <html>
                <head><base href="http://example.com" />
		<title></title>
		</head>
                <body>Some body</body>
            </html>
HTML
    $s->cmd('title');
    chomp $_STDOUT_;
    is($_STDOUT_,"<empty title>", "Empty title gets output correctly");

    undef $_STDOUT_;
    $s->agent->update_html(<<HTML);
            <html>
                <head><base href="http://example.com" />
		<title>0</title>
		</head>
                <body>Some body</body>
            </html>
HTML
    $s->cmd('title');
    chomp $_STDOUT_;
    is($_STDOUT_,"0", "False title gets output correctly");

    undef $_STDOUT_;
    $s->agent->update_html(<<HTML);
            <html>
                <head><base href="http://example.com" />
		</head>
                <body>Some body</body>
            </html>
HTML
    $s->cmd('title');
    chomp $_STDOUT_;
    is($_STDOUT_,"<missing title>", "A missing title gets output correctly");
};
