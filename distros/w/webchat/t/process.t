# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok\n" unless $loaded;}
use WWW::Chat::Processor;
$loaded = 1;
print "ok 1\n";


my $script = << 'EOS';
GET http://www.perl.com
EXPECT OK
EOS

my $convert;

eval { $convert = WWW::Chat::Processor::parse ($script, '<inline>'); };

unless ($@)
{
	print "ok 2\n";
} else {
	print "not ok 2\n";
}

my $proper = << 'EOP';
#!/usr/bin/perl -w
# !!! DO NOT EDIT !!!
# This program was automatically generated from '<inline>' by process.t

use strict;

use URI ();
use HTTP::Request ();
use LWP::UserAgent ();
#use LWP::Debug qw(+);

use HTML::Form ();
use WWW::Chat qw(fail OK ERROR);

use vars qw($ua $uri $base $req $res $status $ct @forms $form @links $TRACE);

$base ||= "http://localhost";
unless ($ua) {
    $ua  = LWP::UserAgent->new;
    $ua->agent("webchat/0.01 " . $ua->agent);
    $ua->env_proxy;
}

$TRACE = $ENV{WEBCHAT_TRACE};

#line 1 "<inline>"
#GET "http://www.perl.com"
eval {
    local $uri = URI->new_abs("http://www.perl.com", $base);
    local $req = HTTP::Request->new(GET => $uri);
    local $res = WWW::Chat::request($req, $ua, $TRACE);
    #print STDERR $res->as_string;
    local $status = $res->code;
    local $base = $res->base;
    local $ct = $res->content_type || "";
    local $_ = $res->content;
    local(@forms, $form, @links);
    if ($ct eq 'text/html') {
        @forms = HTML::Form->parse($_, $res->base);
        $form = $forms[0] if @forms;
        @links = WWW::Chat::extract_links($_);
    }
#line 2 "<inline>"
fail("OK", $res, $ct) unless OK($status);
}; WWW::Chat::check_eval($@);
EOP

exit 0;

#if ($convert eq $proper)
#{
#	print "ok 3\n";
#} else {
#	print "not ok 3\n";
#}


exit 0;
