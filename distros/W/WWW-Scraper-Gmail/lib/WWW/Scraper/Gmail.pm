package WWW::Scraper::Gmail;

use 5.005003;
use strict;
use warnings;

require Exporter;
require LWP;
require Crypt::SSLeay;

use LWP::UserAgent;
use Env qw{HOME};
use Carp;
#use Data::Dumper;
use HTML::Entities;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use WWW::Scraper::Gmail ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.09';


# Preloaded methods go here.
#
my ($next_url);
#my ($js_ver);
my ($gm_l_cookie, $sid);


my ($url, $url2, $url3, $url_init, $urlx, $ua, $req, $res);
my ($cookie, $dump, $inbox, $head, $zx);
my ($gmail_at);
my $num = 0;
my ($username, $password);
my $logged_in = 0;
my $pid = "$ENV{HOME}/.gmailpid";
my $gmailrc = "$ENV{HOME}/.gmailrc";

$url = "https://www.google.com/accounts/ServiceLoginBoxAuth";
$url2 = "https://www.google.com/accounts/CheckCookie?service=mail&chtml=LoginDoneHtml";
#$urlx = "http://gmail.google.com/gmail?search=inbox&view=tl&start=0&init=1&zx=$zx";
$url3 = "http://gmail.google.com/gmail?search=inbox&view=tl&start=0";
$url_init = "http://gmail.google.com/gmail?search=inbox&view=tl&start=0&init=1";

sub setUP {
    unlink "$gmailrc";
    $username = shift @_;
    $password = shift @_;
}

sub getUP {
    open(GMAILRC, "$gmailrc") or die("Can't Open $gmailrc \nFormat:\n[gmail]\nusername=<username>\npassword=<password>\n");
    while (<GMAILRC>) {
        $username = $1 if (/username=(.*)/);
        $password = $1 if (/password=(.*)/);;
    }
    close(GMAILRC);
    return(0) if(!$username or !$password);
    return(1);
}

sub login {

    $ua = LWP::UserAgent->new();
    #its a GOOSE
    $ua->agent("User-Agent: Mozilla/5.0 (Macintosh; U; PPC Mac OS X Mach-O; en-US; rv:1.7) Gecko/20040608");
    $head = HTTP::Headers->new(); #, Referer => $ref);

    if(open(GMAILPID, "$pid")) {
        my $first = <GMAILPID>;
        if ($first - time() > 50000) {
            #cookie is expired
            unlink($pid);
            last();
        }
        $cookie = <GMAILPID>;
        $gmail_at = <GMAILPID>;
        $zx = <GMAILPID>;
        #print "cookie = $cookie\ngmail_at = $gmail_at\nzx=$zx\n";
        $head = HTTP::Headers->new(Cookie => $cookie);
        close(GMAILPID);
        chomp($cookie, $gmail_at, $zx);
        return(0);
    }
    getUP() if (!$username);

    #---------------------------------------------------------
    $req = HTTP::Request->new(GET => "http://gmail.google.com/");
    $res = $ua->request($req);
    #Ok, all the cookies are blanked out at this point
    #---------------------------------------------------------
    $req = HTTP::Request->new(GET => "https://www.google.com/accounts/ServiceLoginBox?service=mail&continue=https%3A%2F%2Fgmail.google.com%2Fgmail");
    $res = $ua->request($req);
    #---------------------------------------------------------
    $req = HTTP::Request->new(GET => "https://www.google.com/accounts/ServiceLoginBox?service=mail&continue=https%3A%2F%2Fgmail.google.com%2Fgmail");
    $res = $ua->request($req);
    #---------------------------------------------------------
    $head->push_header(Referer => "https://www.google.com/accounts/ServiceLoginBox?service=mail&continue=https%3A%2F%2Fgmail.google.com%2Fgmail");
    $head->push_header(Cookie => "Session=en_US; en_US;");
    $req = HTTP::Request->new(POST => "https://www.google.com/accounts/ServiceLoginBoxAuth", $head);
    $req->content_type("application/x-www-form-urlencoded");
    $req->content("continue=https://gmail.google.com/gmail&service=mail&Email=$username&Passwd=$password&PersistentCookie=yes&null=Sign+in");
    $res = $ua->request($req);
    my $dump = $res->as_string();
    while ($dump =~ m!^Set-Cookie: (SID[^;]*).*!mgs) {
        #just get the SID
        $sid .= "$1";
    }
    if ($dump =~ m!(CheckCookie.+?)"!mgs) {
        #have to get the url to go to next
        $next_url = "https://www.google.com/accounts/$1";
    }
    $head->referer("https://www.google.com/accounts/ServiceLoginBoxAuth");
    $head->remove_header("Cookie");
    #Cookie: Session=en_US; en_US; SID=AdVxxBlym6yJx-cWNmCvV2EgDllBCk8R-B7MB_0fqeZ-2vYrVgFMwXiMJiJucsluXNY7SDuK4p7bGDGIcqqa0mg=
    #Cookie: Session=en_US; en_US; SID=AZ9jS5SGlgV7gX_clo063pjTE1R6OSonFHI2iPJcJGvR2vYrVgFMwXiMJiJucsluXINZah0H-npo0on6buw3QuM=; 
    $head->push_header(Cookie => "Session=en_US; en_US; $sid");
    $req = HTTP::Request->new(GET => $next_url, $head);
    $next_url = "";
    $res = $ua->simple_request($req);
    $dump = $res->as_string();  #do the redirect ourselves!
    while ($dump =~ m!Location: (.+?)Serv!gis) {
        $next_url = $1;
        chomp($next_url);
    }
    #---------------------------------------------------------
    $head->remove_header("Cookie");
    $head->remove_header("Referer");
    $gm_l_cookie = "GMAIL_LOGIN=T" . (time() - 2) . "435/" . (time()-1) . "221/" . time() . "264";
    $head->push_header(Cookie => "$gm_l_cookie; $sid");
    $req = HTTP::Request->new(GET => $next_url, $head);
    $next_url = "";
    $res = $ua->simple_request($req);
    $cookie = "";
    $dump = $res->as_string();
    while ($dump =~ m!^Set-Cookie: ([^;]*)!mgs) {
        $cookie .= "$1; ";
        if ($1 =~ /SID=(.*)/) {
            $sid = $1;
        }
        if ($1 =~ /AT=(.*)/) {
            $gmail_at = $1;
        }
    }
    $cookie .= "jscookietest=valid";
    if ($dump =~ m!src=(/gmail\?view=page&name=js&ver=(.+?)) f!mgis) {
        $next_url = $1;
        #$js_ver = $2;
        $zx = $2;
    }

    #print "got $cookie ---- $next_url - and $js_ver\n\n\n";
    #print $res->as_string(), "\n"; exit();
    #var fs_time=(new Date()).getTime();var testcookie = 'jscookietest=valid';
    #document.cookie = testcookie;
    #if (document.cookie.indexOf(testcookie) == -1) {top.location = '/gmail/html/nocookies.html';}
    #document.cookie = testcookie + ';expires=' + new Date(0).toGMTString();
    #var agt = navigator.userAgent.toLowerCase();
    #if (agt.indexOf('msie')!= -1 && document.all) {var control = (agt.indexOf('msie 5') != -1) ? 'Microsoft.XMLHTTP' : 'Msxml2.XMLHTTP';try {new ActiveXObject(control);} catch (e) {top.location = '/gmail/html/noactivex.html';}}
    #name=main src=/gmail/html/loading.html frameborder=0 noresize scrolling=no><frame name=js src=/gmail?view=page&name=js
    #&ver=8d26317a8120ce2c frameborder=0 noresize></frameset>

    #---------------------------------------------------------
    $head->remove_header("Cookie");
    $head->push_header(Cookie => "$gm_l_cookie; $cookie");
    $req = HTTP::Request->new(GET => "https://gmail.google.com/$next_url", $head);
    $res = $ua->simple_request($req);
    #---------------------------------------------------------
    my $url3 = "https://gmail.google.com/gmail?search=inbox&view=tl&start=0";
    #$req = HTTP::Request->new(GET => "https://gmail.google.com/gmail", $head);
    $req = HTTP::Request->new(GET=>$url3, $head);
    $res = $ua->simple_request($req);
    #---------------------------------------------------------
    #
    #
    #

    if (open(GMAILPID, "> $pid")) {
        #Save the cookie to a file so that we don't have to go through it all each time
        print GMAILPID time(), "\n";
        print GMAILPID $cookie, "\n";
        print GMAILPID $gmail_at, "\n";
        print GMAILPID $zx, "\n";
        #print GMAILPID $zx, "\n";
        close(GMAILPID);
    }

    $logged_in = 1;

}

sub doGmailAt {
    #must be logged in to do the gmail at..
    login() unless $logged_in;

    $req = HTTP::Request->new(GET => $url_init,  $head);
    $res = $ua->request($req);
    $dump = $res->as_string();

    #more cookies
    #$zx = $1 if ($dump =~ m!ver=([A-Za-z0-9]*)!);
    while ($dump =~ m!^Set-Cookie: (GMAIL([^;]*)).*!mgs) {
        $cookie .= $1 . ";";
        if ($1 =~ /GMAIL_AT=(.*)/) {
            $gmail_at = $1;
        }
    }

    $head = HTTP::Headers->new(Cookie => $cookie);
    #print "cookie = $cookie\ngmail_at = $gmail_at\nzx=$zx\n";
}

sub countMail {

    login();

    $req = HTTP::Request->new(GET => $url3, $head);
    $res = $ua->request($req);

    my $num = 0;
    if ($res->is_success()) {
        $inbox = $res->content();
        $inbox =~ m!(D\(\[\"t\".*])!mgis;
        $inbox = $1;
        return(0) if (!$inbox);
        $inbox =~ s!\\!!ig;
        $inbox =~ s!</?b>!!ig;
        while ($inbox =~ m!\[".+?",([01]),[01],"(.+?)","<span id='_user_(.+?)'>.+?",".+?","(.+?)","(.+?)".+?\]!mgis) {
            $num++ if ($1);
            #my ($from, $subject, $new) = ($2, (($3 =~ /raquo/) ? $4 : $3), (($1 == 1) ? " NEW!!! " : ""));
            
        }
    }
    return $num;
}

sub outputMail {

    login();
    my $delim = ($ARGV[0]) ? $ARGV[0] : ";;";
    my $ret;

    $req = HTTP::Request->new(GET => $url3, $head);
    $res = $ua->request($req);

    if ($res->is_success()) {
        $inbox = $res->content();
        $inbox =~ m!(D\(\[\"t\".*])!mgis;
        $inbox = $1;
        return("") if (!$inbox);
        $inbox =~ s!\\!!ig;
        #$inbox =~ s!</?b>!!ig;
#        D(["t",["fe4f9c5b8c5bf74",1,0,"\<b\>1:49pm\</b\>","\<span id=\'_user_yonnage@gmail.com\'\>John\</span\>, \<span id=\'_user_kastner@gmail.com\'\>me\</span\>, \<span id=\'_user_yonnage@gmail.com\'\>\<b\>John\</b\>\</span\> (36)","\<b\>&raquo;\</b\>&nbsp;","\<b\>nutritional intake\</b\>","On Wed, 11 Aug 2004 16:10:29 -0400, Erik Kastner &lt;kastner@gmail.com&gt; wrote: &gt; Good &hellip;",[]
#        ,"","fe4f9c5b8c5bf74",0]
#        ,["fe4676e88eff196",0,0,"Aug 9","\<span id=\'_user_davidwboswell@yahoo.com\'\>David Boswell\</span\>","\<b\>&raquo;\</b\>&nbsp;","delicious on mozdev","erik, ok, you&#39;re all set up with http://delicious.mozdev.org/ i apologize for the delay in &hellip;",[]
#        ,"","fe4676e88eff196",0]
#        ]
#        );
#        D(["t",["fe4fc45c88db08f",1,0,"<b>2:32pm</b>","<span id='_user_yonnage@gmail.com'>John</span>, <span id='_user_kastner@gmail.com'>me</span>, <span id='_user_yonnage@gmail.com'><b>John</b></span> (39)","<b>&raquo;</b>&nbsp;","<b>nutritional intake</b>","this is the reply with more, &quot;bitch&quot; On Wed, 11 Aug 2004 17:15:15 -0400, Erik Kastner &hellip;",[]
#        ,"","fe4fc45c88db08f",0]
#        ,["fe4fc293a18f00a",1,0,"<b>2:30pm</b>","<span id='_user_efk@winelibrary.com'><b>Erik F. Kastner</b></span>","<b>&raquo;</b>&nbsp;","<b>Yoy</b>","yoyo",[]
#        ,"","fe4fc293a18f00a",0]
#        ,["fe4676e88eff196",0,0,"Aug 9","<span id='_user_davidwboswell@yahoo.com'>David Boswell</span>","<b>&raquo;</b>&nbsp;","delicious on mozdev","erik, ok, you&#39;re all set up with http://delicious.mozdev.org/ i apologize for the delay in &hellip;",[]
#        ,"","fe4676e88eff196",0]

        while ($inbox =~ m!\[".+?",([01]),[01],"(?:<b>)?(.+?)(?:</b>)?","(.+?)",".+?","(?:<b>)?(.+?)(?:</b>)?","(.+?)".+?\]!mgis) {
            $num++;
            my ($time, $from, $subject, $new, $blurb) = ($2, $3, $4, ($1 == 1) ? "new!" : "", $5);
            if ($from =~ m!<span.+?><b>(.+?)</b>!) {
                $from = $1;
            }
            else {
                $from =~ s!<span.+?>(.+?)</spa.*!$1!g;
            }
            #<span id='_user_yonnage@gmail.com'>John</span>, <span id='_user_kastner@gmail.com'>me</span>, <span id='_user_yonnage@gmail.com'><b>John</b></span> (39)
            #print "Looking at $4\n\n";
            #my ($from, $subject, $new) = ($2, (($3 =~ /raquo/) ? $4 : $3), (($1 == 1) ? " NEW!!! " : ""));
            my $rec = {};
            if ($1) {
                $ret .= "$from$delim$subject$delim$time$delim$blurb\n";
            }
        }
        #print "$num total messages in inbox\n";
        return $ret;

    }
    else {
        warn $res->content();
        warn $res->status_line, "\n";
        return("");
    }
}

sub fetchMail {

    login();

    my @msgs;
    $req = HTTP::Request->new(GET => $url3, $head);
    $res = $ua->request($req);

    if ($res->is_success()) {
        $inbox = $res->content();
        $inbox =~ m!(D\(\[\"t\".*])!mgis;
        $inbox = $1;
        return(0) if (!$inbox);
        $inbox =~ s!\\!!ig;
        $inbox =~ s!</?b>!!ig;
        while ($inbox =~ m!\[".+?",([01]),[01],"(.+?)","<span id='_user_(.+?)'>.+?",".+?","(.+?)","(.+?)".+?\]!mgis) {
            $num++;
            #my ($from, $subject, $new) = ($2, (($3 =~ /raquo/) ? $4 : $3), (($1 == 1) ? " NEW!!! " : ""));
            my ($time, $from, $subject, $new, $blurb) = ($2, $3, $4, ($1 == 1) ? "new!" : "", $5);
            my $rec = {};
            $rec = {
                from    => $from,
                subject => $subject,
                date    => $time,
                blurb   => $blurb,
                new     => $1
            };
            push @msgs, $rec;

            #print "Thread Started by $from, Subject $subject @ $time $new\n\t$blurb\n";
        }
        #print "$num total messages in inbox\n";
        return @msgs;

    }
    else {
        warn $res->content();
        warn $res->status_line, "\n";
        return(0);
    }
}

sub setPrefs {
    my ($arg) = @_;
    login();
    doGmailAt();
    $arg->{"MaxPer"} = 100 unless defined $arg->{MaxPer};
    $arg->{"Signature"} = "" unless defined $arg->{Signature};

    $arg->{"Signature"} = HTML::Entities::encode_entities_numeric($arg->{"Signature"});
    #print Dumper $arg;

    my $url_pref=" http://gmail.google.com/gmail?search=inbox&view=tl&start=0&act=prefs&at=$gmail_at&p_bx_hs=1&p_ix_nt=$arg->{MaxPer}&p_bx_sc=1&p_sx_sg=$arg->{Signature}&zx=$zx";
    #print "Going for $url_pref\n";
    #$head = HTTP::Headers->new(Cookie => $cookie); #, Referer => $ref);
    $req = HTTP::Request->new(GET=>$url_pref, $head);
    $res = $ua->request($req);
    return ($res->as_string() =~ /saved/);
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

WWW::Scraper::Gmail - Perl extension for loging in and reading Gmail Mailbox information.

=head1 SYNOPSIS

  use WWW::Scraper::Gmail;
  A simple scraper for gmail.

=head1 DESCRIPTION

Logs into email through https, does some stuff and gets back a list of inbox items.
Uses ~/.gmailrc for now for username and password. The format is as follows
[gmail]
username=<username>
password=<password>

you'd do well to chmod it 700.
Doesn't do error checking for log in problems.

=head2 EXPORT

None by default.



=head1 SEE ALSO

=head1 AUTHOR

Erik F. Kastner, <lt>kastner@gmail.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Erik F. Kastner

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
