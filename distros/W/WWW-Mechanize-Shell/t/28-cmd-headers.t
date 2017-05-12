#!/usr/bin/perl -w
use strict;
use lib './inc';
use IO::Catch;

use vars qw($_STDOUT_);
tie *STDOUT, 'IO::Catch', '_STDOUT_' or die $!;

# Disable all ReadLine functionality
$ENV{PERL_RL} = 0;
delete $ENV{PAGER}
  if $ENV{PAGER};
$ENV{PERL_HTML_DISPLAY_CLASS}="HTML::Display::Dump";

use Test::More tests => 8;

use_ok('WWW::Mechanize::Shell');
my $s = WWW::Mechanize::Shell->new( 'test', rcfile => undef, warnings => undef );
isa_ok $s, 'WWW::Mechanize::Shell';

sub cleanup() {
    # clean up $_STDOUT_ so it fits on one line
    #diag $_STDOUT_;
    $_STDOUT_ =~ s/[\r\n]+/|/g;
    $_STDOUT_ =~ s!(?<=:)(\s+)!(">" x (length($1)/2))!eg;
};

SKIP: {

    $s->agent->{base} = 'http://example.com';
    $s->agent->update_html(<<HTML);
            <html>
                <head><base href="http://example.com" />
		<title>An HTML page</title>
		</head>
                <body>
		<h1>(H1.1)</h1>
		<h2>(H2)</h2>
		<h3>(H3.1)</h3>
		<h3>(H3.2)</h3>
		<h4>(H4)</h4>
		<h1>(H1.2)</h1>
		<h5>(H5)</h5>
		<h1></h1>
		<h1>  Some spaces before this</h1>
		<h1>
A newline in
this</h1>
		<h2>
		<h3>
		</body>
            </html>
HTML
    $s->cmd('headers');
    cleanup;
    is($_STDOUT_,"h1:(H1.1)|h2:>(H2)|h3:>>(H3.1)|h3:>>(H3.2)|h4:>>>(H4)|h1:(H1.2)|h5:>>>>(H5)|h1:<no text>|h1:Some spaces before this|h1:A newline in this|h2:><empty tag>|h3:>><empty tag>|", "The default works");
    undef $_STDOUT_;

    $s->cmd('headers 12345');
    cleanup;
    is($_STDOUT_,"h1:(H1.1)|h2:>(H2)|h3:>>(H3.1)|h3:>>(H3.2)|h4:>>>(H4)|h1:(H1.2)|h5:>>>>(H5)|h1:<no text>|h1:Some spaces before this|h1:A newline in this|h2:><empty tag>|h3:>><empty tag>|", "Explicitly specifying the default works as well");
    undef $_STDOUT_;

    $s->cmd('headers 1');
    cleanup;
    is($_STDOUT_,"h1:(H1.1)|h1:(H1.2)|h1:<no text>|h1:Some spaces before this|h1:A newline in this|", "H1 headers works as well");
    undef $_STDOUT_;

    $s->cmd('headers 23');
    cleanup;
    is($_STDOUT_,"h2:>(H2)|h3:>>(H3.1)|h3:>>(H3.2)|h2:><empty tag>|h3:>><empty tag>|", "Restricting to a subset works too");
    undef $_STDOUT_;

    $s->cmd('headers 25');
    cleanup;
    is($_STDOUT_,"h2:>(H2)|h5:>>>>(H5)|h2:><empty tag>|", "A noncontingous subset as well");
    undef $_STDOUT_;

    $s->cmd('headers 52');
    cleanup;
    is($_STDOUT_,"h2:>(H2)|h5:>>>>(H5)|h2:><empty tag>|", "Even in a weirdo order");
    undef $_STDOUT_;

};
