#!/usr/bin/perl
# 2.2.2010, Sampo Kellomaki (sampo@iki.fi)
# 18.11.2010, greatly enchanced --Sampo
# 28.8.2012, added some features from hitest.pl, added zxbusd tests --Sampo
#
# Test suite for ZXID

$usage = <<USAGE;
Test driver for ZXID
Usage: http://localhost:8081/zxtest.pl?tst=XML1  # Run as CGI with HTML putput
       ./zxtest.pl -a [-a] [-x] [-dx] tst=XML1   # Run specific test
       ./zxtest.pl -a [-a] [-x] [-dx] ntst=XML   # Run all tests except specified
         -a  Ascii mode (give twice for colored ascii)
         -x  Print exec(2) command lines to stderr
         -dx Proprietary per character color diff (default: system diff -u)
         N.B. Positional order of even optional arguments is significant.
USAGE
    ;

$cvsid = '$Id$';
($rev) = (split /\s+/, $cvsid)[2];

# See https://wiki.archlinux.org/index.php/Color_Bash_Prompt
#sub red   { $ascii > 1 ? "\e[1;31m$_[0]\e[0m" : $_[0]; }  # red text
#sub green { $ascii > 1 ? "\e[1;32m$_[0]\e[0m" : $_[0]; }
sub red    { $ascii > 1 ? "\e[1;41m$_[0]\e[0m" : $_[0]; }  # red background, black bold text
sub green  { $ascii > 1 ? "\e[1;42m$_[0]\e[0m" : $_[0]; }
sub redy   { $ascii > 1 ? "\e[41m$_[0]\e[0m" : $_[0]; }    # red background, black text (no bold)
sub greeny { $ascii > 1 ? "\e[42m$_[0]\e[0m" : $_[0]; }

use Encode;
use Digest::MD5;
use Digest::SHA;  # apt-get install libdigest-sha-perl
use Net::SSLeay qw(get_httpx post_httpx make_headers make_form);  # Need Net::SSLeay-1.24
use WWW::Curl::Easy;    # HTTP client library, see curl.haxx.se. apt-get install libwww-curl-perl
use WWW::Curl::Multi;
use XML::Simple;   # apt-get install libxml-simple-perl
#use Net::SMTP;
#use MIME::Base64;  # plain=decode_base64(b64)   # RFC3548
#sub decode_safe_base64 { my ($x) = @_; $x=~tr[-_][+/]; return decode_base64 $x; }
#sub encode_safe_base64 { my ($x) = @_; $x = encode_base64 $x, ''; $x=~tr[+/][-_]; return $x; }
use Data::Dumper;
use Time::HiRes;

die $usage if $ARGV[0] =~ /^--?[hH?]/;
$trace = 0;

if ($ARGV[0] eq '-t') {
    warn "Test: ".check_diff("ZXBUSM64", 60, 10, '10x10x20');
    exit;
}

# Where error log goes tail -f zxtest.err
#open STDERR, ">>zxtest.err";

select STDERR; $| = 1; select STDOUT; $| = 1;
$ascii = 1,shift if $ARGV[0] eq '-a';
$ascii = 2,shift if $ARGV[0] eq '-a';
$show_exec = shift if $ARGV[0] eq '-x';
$diffx = shift if $ARGV[0] eq '-dx';

$ENV{'LD_LIBRARY_PATH'} = '/apps/lib';  # *** Specific to Sampo's environment
warn "START pid=$$ $cvsid qs($ENV{'QUERY_STRING'}) LD($ENV{'LD_LIBRARY_PATH'})";
syswrite STDOUT, "Content-Type: text/html\r\n\r\n" if !$ascii;

### N.B. Ignoring SIGCHLD breaks return value of system() and $?
#$x=system "false"; warn "x($x) q($?) $!";
#$SIG{CHLD} = 'IGNORE';  # No zombies, please (subprocesses for delayed ops).
#$x=system "false"; warn "x($x) q($?) $!";

$uname_minus_s = `uname -s`;
chop $uname_minus_s;

###
### Library Functions
###

sub writeall {
    my ($f,$d) = @_;
    open F, ">$f" or die "Cant write($f): $!";
    binmode F;
    flock F, 2;    # Exclusive
    print F $d;
    flock F, 8;    
    close F;
}

sub readall {
    my ($f,$silent) = @_;
    my ($pkg, $srcfile, $line) = caller;
    undef $/;         # Read all in, without breaking on lines
    if (open F, "<$f") {
	binmode F;
	#flock F, 1;
	my $x = <F>;
	#flock F, 8;
	close F;
	return $x;
    } else {
	return undef if $silent;
	warn "$srcfile:$line: Cant read($f): $!";
	warn "pwd(".`pwd`.")";
	return undef;
    }
}

sub cgiout {
    my ($hdr, $mime, $body, $isbin) = @_;
    warn "Len body preenc=".length($body);
    $body = encode_utf8($body);
    warn "Len body postenc=".length($body);
    syswrite STDOUT, "${hdr}Content-Type: $mime\r\nContent-Length: ".length($body)."\r\n\r\n$body";

    if ($isbin > 0) {  # 0 = proto, 1 = html, 2 = true binary
	#warn "cgiout(${hdr}Content-Type: $mime\r\nContent-Length: ".length($body)."\r\n\r\n(binary($isbin) body omitted from log)";
	warn "-- cgiout $$ hdr(${hdr}) mime($mime) len=".length($body)." bin($isbin)";
    } else {
	#warn "cgiout(${hdr}Content-Type: $mime\r\nContent-Length: ".length($body)."\r\n\r\n$body)";
	warn "-- cgiout $$ hdr(${hdr}) mime($mime) len=".length($body)." body($body)";
    }
}

sub cgidec {
    my ($d) = @_;
    my %qs;
    for $nv (split '&', $d) {
	($n, $v) = split '=', $nv, 2;
	$qs{$n} = $v;
    }
    return \%qs;
}

sub uridec {
    my ($val) = @_;
    $val =~ s/\+/ /g;
    $val =~ s/%([0-9a-f]{2})/chr(hex($1))/gsex;  # URI decode
    return $val;
}

sub urienc {
    my ($val) = @_;
    $val =~ s/([^A-Za-z0-9.,_-])/sprintf("%%%02x",ord($1))/gsex; # URI enc
    return $val;
}

###
### Custome diff package
###

# Erase some common innocent differences

sub blot_out_std_diffs {
    my ($x) = @_;
    #warn "len=".length($x);
    $x =~ s/(ID)=".*?"/$1=""/g;
    $x =~ s/(IssueInstant)=".*?"/$1=""/g;
    
    $x =~ s/0\.\d+ 12\d+ libzxid \(zxid\.org\)/0./g;
    $x =~ s/R0\.\d+ \(\d+\)/R0./g;
    $x =~ s/R0\.\d+/R0./g;
    
    $x =~ s/^(msgid: ).+/$1/gm;
    $x =~ s/^(sespath: ).+/$1/gm;
    $x =~ s/^(sesid: ).+/$1/gm;
    $x =~ s/^(tgta7npath: ).+/$1/gm;
    $x =~ s/^(ssoa7npath: ).+/$1/gm;
    $x =~ s/^(zxididp: 0\.).+/$1/gm;

    $x =~ s%<wsu:Created>.*?</wsu:Created>%CREATED_TS%g;
    $x =~ s%<a:MessageID[^>]*>.*?</a:MessageID>%MessageID%g;
    $x =~ s%<a:InReplyTo[^>]*>.*?</a:InReplyTo>%InReplyTo%g;
    $x =~ s%<ds:DigestValue>.*?</ds:DigestValue>%DIGESTVAL%g;
    $x =~ s%<ds:SignatureValue>.*?</ds:SignatureValue>%SIGVAL%g;
    $x =~ s%<xenc:CipherValue>.*?</xenc:CipherValue>%CIPHERVALUE%g;

    # zxbusd hiiosdump related

    #warn "len=".length($x);
    $x =~ s%(shf_0x)[0-9a-f]+%$1%g;
    $x =~ s%(io_0x)[0-9a-f]+%$1%g;
    $x =~ s%(hit_0x)[0-9a-f]+%$1%g;
    $x =~ s%(tid_)[0-9a-f]+%$1%g;
    $x =~ s%(pdu_0x)[0-9a-f]+%$1%g;
    $x =~ s%(-> pdu_0x  // \()[A-Z]+\)%$1)%g;
    $x =~ s%(// fd=0x)[0-9a-f]+%$1%g;

    #warn "len=".length($x);
    $x =~ s%test\(-?\d+,\d+,\d+\)%test(,,)%g;
    $x =~ s%RECEIPT \d+%RECEIPT %g;
    #warn "len=".length($x);
    return $x;
}

sub ediffy {   # The main diff algo
    my ($a,$b) = @_;
    return 0 if $a eq $b;

    # Ignore some common innocent differences

    $a = blot_out_std_diffs($a);
    $b = blot_out_std_diffs($b);
    return 0 if $a eq $b;

    warn "enter heavy diff -u tmp/a tmp/b; len1=".length($a)." len2=".length($b);
    writeall("tmp/a", $a);
    writeall("tmp/b", $b);

    my $ret = 0;

    eval {
	local $SIG{ALRM} = sub { die "TIMEOUT\n"; };
	alarm 60;   # The ediff algorithm seems exponential time, so lets not wait forever.
	require Algorithm::Diff;
	my @seq1 = split //, $a;
	my @seq2 = split //, $b;
	my $diff = Algorithm::Diff->new( \@seq1, \@seq2 );
	
	$diff->Base(1);   # Return line numbers, not indices
	while(  $diff->Next()  ) {
	    if (@sames = $diff->Same()) {
		print @sames;
		next;
	    }
	    if (@dels = $diff->Items(1)) {
		print redy(join '', @dels);
		++$ret;;
	    }
	    if (@adds = $diff->Items(2)) {
		print greeny(join '', @adds);
		++$ret;
	    }
	}
    };
    alarm 0;
    print "\n" if $ret;
    return $ret;
}

sub ediffy_read {
    my ($file1,$file2) = @_;
    my $data1 = readall $file1;
    my $data2 = readall $file2;
    return ediffy($data1,$data2);
}

sub isdiff_read {
    my ($file1,$file2,$silent) = @_;
    my $data1 = readall($file1,$silent);
    my $data2 = readall($file2,$silent);
    #warn "len1($file1)=".length($data1)." def1=".defined($data1)." len2($file2)=".length($data2)." def2=".defined($data2).".";
    return -6 if !defined($data1) || !defined($data2);
    #warn "data1($data1)\ndata2($data2)" if $data1 && $data2;
    $data1 = blot_out_std_diffs($data1);
    $data2 = blot_out_std_diffs($data2);
    return 0 if $data1 eq $data2;
    return (length($data1)-length($data2)) || -5;
}

sub check_diff {
    my ($tsti, $latency, $slow, $test) = @_;
    my $ret;
    $ok_lvl = '';
    return 0 if !($ret = isdiff_read("t/$tsti.out", "tmp/$tsti.out"));
    $ok_lvl = 2;
    return 0 if !isdiff_read("t/$tsti.out2", "tmp/$tsti.out", 1);  # second truth matches
    $ok_lvl = 3;
    return 0 if !isdiff_read("t/$tsti.out3", "tmp/$tsti.out", 1);  # third truth
    if ($diffx) {
	if ($ret = ediffy_read("t/$tsti.out", "tmp/$tsti.out")) {
	    tst_print('col1r', 'Diff ERR', $latency, $slow, $test, "$ret lines of diff");
	    return 1;
	}
    } elsif ($diffmeth eq 'diffu') {
	if (system "/usr/bin/diff t/$tsti.out tmp/$tsti.out") {
	    tst_print('col1r', 'Diff Err', $latency, $slow, $test, '');
	    return 1;
	}
    } else {
	tst_print('col1r', (abs($ret)>5)?'Size ERR':'Diff ERR', $latency, $slow, $test, ($ret==-5?'':"Difference in size: $ret"));
	return 1;
    }
    $ok_lvl = 4;
    return 0;
}

### HTTP clients

if (1) {
sub resp_cb {
    my ($chunk,$curl_id) = @_;
    #warn "resp_cb curl_id($curl_id) chunk($chunk) len=".length($chunk);
    $resp{$curl_id} .= $chunk;
    return length $chunk; # OK
}

sub curl_reset_all {
    my ($curl) = @_;
    $curl->reset();
    sleep 5;
}

sub test_http {
    my ($curl, $cmd, $tsti, $expl, $url, $timeout, $slow) = @_;
    return unless $tst eq 'all' || $tst eq substr($tsti,0,length $tst);
    return if $ntst && $ntst eq substr($tsti,0,length $ntst);
    #warn "\n======= $tsti =======";
    
    $slow ||= 0.5;
    $timeout ||= 15;
    my $test = tst_link($tsti, $expl, $url);
    my $send_ts = Time::HiRes::time();
    $cmd{$curl_id} = $cmd;
    $key{$curl_id} = $koerkki;
    $qs{$curl_id} = '';
    $sesid{$curl_id} = '';
    warn "HERE1 ".Time::HiRes::time() if $timeout_trace;
    eval {
	warn "HERE2 ".Time::HiRes::time() if $timeout_trace;
	local $SIG{ALRM} = sub { die "TIMEOUT\n"; };
	warn "HERE3 ".Time::HiRes::time() if $timeout_trace;
	alarm $timeout;
	warn "HERE4 ".Time::HiRes::time() if $timeout_trace;
	send_http($curl, $url, 0);
	warn "HERE5 ".Time::HiRes::time() if $timeout_trace;
	wait_response();
	warn "HERE6 ".Time::HiRes::time() if $timeout_trace;
    };
    warn "HERE7 ".Time::HiRes::time() if $timeout_trace;
    alarm 0;
    warn "HERE8 ".Time::HiRes::time() if $timeout_trace;
    my $status = $@;
    warn "HERE9 ".Time::HiRes::time() if $timeout_trace;
    my $latency = substr(Time::HiRes::time() - $send_ts, 0, 5);
    if ($status eq "TIMEOUT\n") {
	tst_print('col1r', 'Timeout', $latency, $slow, $test, '');
	$@ = 0;
	warn "Timeout ($@) ".Time::HiRes::time();
	#$timeout_trace = 1;
	curl_reset_all($curl);
    } elsif ($status) {
	tst_print('col1r', 'Conn. Err', $latency, $slow, $test, $status);
    } elsif ($laststatus ne 'OK') {
	tst_print('col1r', 'App Err', $latency, $slow, $test, $lasterror);
    } else {
	tst_ok($latency, $slow, $test);
    }
}

sub test_http_post {
    my ($curl, $cmd, $tsti, $expl, $url, $body, $timeout, $slow) = @_;
    return unless $tst eq 'all' || $tst eq substr($tsti,0,length $tst);
    return if $ntst && $ntst eq substr($tsti,0,length $ntst);
    #warn "\n======= $tsti =======";

    $slow ||= 0.5;
    $timeout ||= 15;
    my $test = tst_link($tsti, $expl, $url);
    my $send_ts = Time::HiRes::time();
    $cmd{$curl_id} = $cmd;
    $key{$curl_id} = $koerkki;
    $qs{$curl_id} = '';
    $sesid{$curl_id} = '';
    eval {
	local $SIG{ALRM} = sub { die "TIMEOUT\n"; };
	alarm $timeout;
	send_http_post($curl, $url, $body, 1);
	wait_response();
    };
    alarm 0;
    my $status = $@;
    my $latency = substr(Time::HiRes::time() - $send_ts, 0, 5);
    if ($status eq "TIMEOUT\n") {
	tst_print('col1r', 'Timeout', $latency, $slow, $test, '');
	$@ = 0;
	curl_reset_all($curl);
    } elsif ($status) {
	tst_print('col1r', 'Conn. Err', $latency, $slow, $test, $status);
    } elsif ($laststatus ne 'OK') {
	tst_print('col1r', 'App Err', $latency, $slow, $test, $lasterror);
    } else {
	tst_ok($latency, $slow, $test);
    }
}

### Create http connection handles. Each will correspnd to one session, i.e. set of cookies

$curl_id = 1;
$curlm = WWW::Curl::Multi->new;  # Multihandle, technically needed

$curlA = new WWW::Curl::Easy;  # Share curl handle so that cookies are shared

sub tA { test_http($curlA, @_); }
sub pA { test_http_post($curlA, @_); }

sub send_req {
    my ($what, $send_trace) = @_;
    my ($pkg, $srcfile, $line) = caller;
    $send_ts{$curl_id} = Time::HiRes::time();
    #my $curl = new WWW::Curl::Easy; # Globally created to preserve cookies
    my $curl = $curlP;
    $curl->setopt(CURLOPT_FOLLOWLOCATION, 1);
    $curl->setopt(CURLOPT_MAXREDIRS, 5);
    #$curl->setopt(CURLOPT_SSL_VERIFYHOST, 2);  # 2=verify (default, 0=disable check
    $curl->setopt(CURLOPT_SSL_VERIFYPEER, 0);  # 1=verify (default, 0=disable check
    $curl->setopt(CURLOPT_UNRESTRICTED_AUTH, 1);
    #$curl->setopt(CURLOPT_HTTPAUTH, CURLAUTH_BASIC);
    #$curl->setopt(CURLOPT_USERPWD, "sampo:12345678");  # ***
    $curl->setopt(CURLOPT_COOKIEFILE, '');  # Empty file enables tracking cookies
    #open (my $fileb, ">", \$resp);            # Read into inmemory file
    #$curl->setopt(CURLOPT_WRITEDATA,$fileb);
    $curl->setopt(CURLOPT_WRITEFUNCTION, \&resp_cb);
    $curl->setopt(CURLOPT_FILE, $curl_id);
    $resp{$curl_id} = '';
    $curl->setopt(CURLOPT_HTTPGET, 1);
    my @hdr = ("User-Agent: wrevd-0.2-$rev");
    $curl->setopt(CURLOPT_HTTPHEADER, \@hdr);
    $easy_url{$curl_id} = "$dom$soap_endpoint/$what";  # Curl will reference mem so make sure it will not be garbage collected until the handle is
    $curl->setopt(CURLOPT_URL, $easy_url{$curl_id});
    warn "  $srcfile:$line: WS GET($easy_url{$curl_id}) curl_id($curl_id)" if $send_trace;
    $curl->setopt(CURLOPT_PRIVATE, $curl_id);
    $easy{$curl_id} = $curl;
    $curlm->add_handle($curl);
    ++$curl_id;
    ++$active_handles;
}

sub send_req_post_soap {
    my ($body) = @_;
    my ($pkg, $srcfile, $line) = caller;
    $send_ts{$curl_id} = Time::HiRes::time();
    #my $curl = new WWW::Curl::Easy; # Globally created to preserve cookies
    my $curl = $curlP;
    $curl->setopt(CURLOPT_FOLLOWLOCATION, 1);
    $curl->setopt(CURLOPT_MAXREDIRS, 5);
    #$curl->setopt(CURLOPT_SSL_VERIFYHOST, 2);  # 2=verify (default, 0=disable check
    $curl->setopt(CURLOPT_SSL_VERIFYPEER, 0);  # 1=verify (default, 0=disable check
    $curl->setopt(CURLOPT_UNRESTRICTED_AUTH, 1);
    #$curl->setopt(CURLOPT_HTTPAUTH, CURLAUTH_BASIC);
    #$curl->setopt(CURLOPT_USERPWD, "sampo:12345678");  # ***
    $curl->setopt(CURLOPT_COOKIEFILE, '');  # Empty file enables tracking cookies
    #open (my $fileb, ">", \$resp);         # Read into inmemory file
    #$curl->setopt(CURLOPT_WRITEDATA,$fileb);
    $curl->setopt(CURLOPT_WRITEFUNCTION, \&resp_cb);
    $curl->setopt(CURLOPT_FILE, $curl_id);
    $resp{$curl_id} = '';

    #$curl->setopt(CURLOPT_POSTFIELDS, qq(<?xml version="1.0" encoding="utf-8"?><soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope"><soap12:Body>$body</soap12:Body></soap12:Envelope>));
    # Curl will reference mem so make sure it will not be garbage collected until the handle is
    $easy_post{$curl_id} = qq(<?xml version="1.0" encoding="utf-8"?><soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body>$body</soap:Body></soap:Envelope>);
    $curl->setopt(CURLOPT_POSTFIELDS, $easy_post{$curl_id});  # implies CURLOPT_POST

    #my @hdr = ("Content-Type: application/soap+xml","User-Agent: wrevd-0.2");
    my @hdr = ("Content-Type: text/xml","User-Agent: wrevd-0.2-$rev",'SOAPAction: "http://timebi.com/UpdatePositions"');
    $curl->setopt(CURLOPT_HTTPHEADER, \@hdr);
    $easy_url{$curl_id} = "$dom$soap_endpoint";  # Curl will reference mem so make sure it will not be garbage collected until the handle is
    $curl->setopt(CURLOPT_URL, $easy_url{$curl_id});
    warn "$srcfile:$line: WS SOAP($body)" if $wstrace;
    $curl->setopt(CURLOPT_PRIVATE,$curl_id);
    $easy{$curl_id} = $curl;
    $curlm->add_handle($curl);
    ++$curl_id;
    ++$active_handles;
}

sub send_http {
    my ($curl, $url, $send_trace) = @_;
    my ($pkg, $srcfile, $line) = caller;
    $send_ts{$curl_id} = Time::HiRes::time();
    #my $curl = new WWW::Curl::Easy;   # see 1st arg
    $curl->setopt(CURLOPT_FOLLOWLOCATION, 1);
    $curl->setopt(CURLOPT_MAXREDIRS, 5);
    #$curl->setopt(CURLOPT_SSL_VERIFYHOST, 2);  # 2=verify (default, 0=disable check
    $curl->setopt(CURLOPT_SSL_VERIFYPEER, 0);  # 1=verify (default, 0=disable check
    $curl->setopt(CURLOPT_UNRESTRICTED_AUTH, 1);
    $curl->setopt(CURLOPT_COOKIEFILE, ''); # Empty file enables cookie tracking
    $curl->setopt(CURLOPT_WRITEFUNCTION, \&resp_cb);
    $curl->setopt(CURLOPT_FILE, $curl_id);
    $resp{$curl_id} = '';
    $curl->setopt(CURLOPT_HTTPGET, 1);
    my @hdr = ("User-Agent: wrevd-0.2-$rev");
    $curl->setopt(CURLOPT_HTTPHEADER, \@hdr);
    $easy_url{$curl_id} = $url;  # Curl will reference mem so make sure it will not be garbage collected until the handle is
    $curl->setopt(CURLOPT_URL, $easy_url{$curl_id});
    warn "  $srcfile:$line: WS GET($easy_url{$curl_id}) curl_id($curl_id)" if $send_trace;
    $curl->setopt(CURLOPT_PRIVATE, $curl_id);
    $easy{$curl_id} = $curl;
    $curlm->add_handle($curl);
    ++$curl_id;
    ++$active_handles;
}

sub send_http_post {
    my ($curl, $url, $body, $send_trace) = @_;
    my ($pkg, $srcfile, $line) = caller;
    $send_ts{$curl_id} = Time::HiRes::time();
    #my $curl = new WWW::Curl::Easy;  # see 1st arg
    $curl->setopt(CURLOPT_FOLLOWLOCATION, 1);
    $curl->setopt(CURLOPT_MAXREDIRS, 5);
    #$curl->setopt(CURLOPT_SSL_VERIFYHOST, 2);  # 2=verify (default, 0=disable check
    $curl->setopt(CURLOPT_SSL_VERIFYPEER, 0);  # 1=verify (default, 0=disable check
    $curl->setopt(CURLOPT_UNRESTRICTED_AUTH, 1);
    $curl->setopt(CURLOPT_COOKIEFILE, ''); # Empty file enables cookie tracking
    $curl->setopt(CURLOPT_WRITEFUNCTION, \&resp_cb);
    $curl->setopt(CURLOPT_FILE, $curl_id);

    #             1 1    234     4 5     53 2
    #$url =~ s%http(s)?://((([^:]+):([^@]+))@)?%%si;
    #if ($3) {  # inline specified username and password
    #warn "Basic-Auth($3) url($url)";
    #$curl->setopt(CURLOPT_USERPWD, $1);
    #}

    $resp{$curl_id} = '';
    $easy_post{$curl_id} = $body;
    $curl->setopt(CURLOPT_POSTFIELDS, $easy_post{$curl_id});  # implies CURLOPT_POST
    my @hdr = ("User-Agent: wrevd-0.2-$rev");
    $curl->setopt(CURLOPT_HTTPHEADER, \@hdr);
    $easy_url{$curl_id} = $url;  # Curl will reference mem so make sure it will not be garbage collected until the handle is
    $curl->setopt(CURLOPT_URL, $easy_url{$curl_id});
    warn "  $srcfile:$line: WS POST($easy_url{$curl_id}) BODY($body) curl_id($curl_id)" if $send_trace;
    $curl->setopt(CURLOPT_PRIVATE, $curl_id);
    $easy{$curl_id} = $curl;
    $curlm->add_handle($curl);
    ++$curl_id;
    ++$active_handles;
}

sub wait_response {
    $laststatus = $lasterror = '';
    while ($active_handles) {
	warn "  curlm->perform loop active($active_handles) n=$n_resp vol=$v_resp avg_lat=".($n_resp?($tot_latency / $n_resp):0) if $trace;
	$tcid = $curl_id - 1;
	warn "  url($easy_url{$tcid}) curl_id($tcid)" if $trace;
	my $active_transfers = $curlm->perform;
	if ($active_transfers == $active_handles) {
	    #warn "  url($easy_url{$curl_id})";
	    select(undef, undef, undef, 0.1);   # transfers incomplete, wait a little and try again
	    next;
	}
	warn "  url($easy_url{$tcid}) at=$active_transfers ah=$active_handles" if $trace;
	while (my ($id, $ret) = $curlm->info_read) {
	    next if !$id;
	    --$active_handles;
	    my $curle = $easy{$id};
	    delete $easy{$id}; # let curl handle get garbage collected, or we leak memory
	    delete $easy_post{$id};
	    $latency = Time::HiRes::time() - $send_ts{$id};
	    if ($ret) {
		warn "HTTP layer failed: ".$curle->errbuf."\nid=$id qs($qs{$id})\nurl($easy_url{$id})\nret($ret) id=$id latency=$latency";
		delete $easy_url{$id};
		next;
	    }
	    #warn "HTTP complete $id URL($easy_url{$id})";
	    $qs = cgidec $qs{$id};
	    $rsp = decode_utf8($resp{$id});  # http response
	    delete $resp{$id};
	    #warn "resp($rsp) id=$id latency=$latency ($send_ts{$id})" if $wstrace>1;
	    warn "resp($rsp) id=$id qsid($qs{$id}) latency=$latency\n\n" if $wstrace>1 && $$qs{'id'} ne 'intupd';
	    ++$n_resp;
	    $tot_latency += $latency;
	    $v_resp += length $rsp;
	    if (length $rsp) {
		if ($cmd{$id} eq 'PING'
		    || $cmd{$id} eq 'LOGOUT') {
		    #warn "Non XML cmd($cmd{$id}) url($easy_url{$id}) response($rsp)";
		} elsif ($cmd{$id} eq 'ST') {
		    #warn "static response len=".length($rsp);
		} else {
		    # Wrapped in eval {} to avoid death when web service sends non XML errors
		    eval {
			$xx = XMLin $rsp, ForceArray => 1, KeyAttr => [];   # <== Decode XML
		    };
		    if ($@) {
			if (($lasterror) = $rsp =~ /^(.*?Exception.*?)\n/s) {
			    $cmd{$id} = 'exception';
			}
			#warn "XMLin: $@";
			#warn "cmd($cmd{$id}) resp($id)=($rsp)";
			$xx = undef;
		    }
		}
	    } else {
		#warn "Empty response (possibly OK)";
		$xx = undef;
	    }
	    #warn "XML::Simple: " . Dumper($xx);

	    $user = $ses{$sesid{$id}}{'user'};
	    #warn "user($user) qs($qs{$id})" . Dumper($xx) if $wstrace && $$qs{'id'} ne 'intupd';
	    #printf WS_LOG "%.3f %2.3f %5d %4d %s %s %s\n", $send_ts{$id}, $latency, length($rsp), $id, $user, $key{$id}, $qs{$id}; #substr($qs{$id},0,30);
	    
	    if ($cmd{$id} eq 'PING'
		|| $cmd{$id} eq 'WRSEND') {
		$lasterror = $rsp;
		eval { $rr = $jsonobj->decode($rsp); };
		if ($$rr[0]{'err'} && $$rr[0]{'err'} ne 'OK' && $$rr[0]{'err'} ne 'LAST') {
		    warn "err($$rr[0]{'err'})";
		    $laststatus = $$rr[0]{'err'};
		} else {
		    warn "OK err($$rr[0]{'err'})";
		    $laststatus = 'OK';
		}
	    } elsif ($cmd{$id} eq 'NOT') {
		$lasterror = $rsp;
		eval { $rr = $jsonobj->decode($rsp); };
		if ($$rr[0]{'err'} ne 'NA') {
		    $laststatus = "E=".$$rr[0]{'err'};
		} else {
		    $laststatus = 'OK';
		}
	    } elsif ($cmd{$id} eq 'NOP') {
		$lasterror = $rsp;
		eval { $rr = $jsonobj->decode($rsp); };
		if ($$rr[0]{'err'} ne 'NP') {
		    $laststatus = "E=".$$rr[0]{'err'};
		} else {
		    $laststatus = 'OK';
		}
	    } elsif ($cmd{$id} eq 'AR') {
		# Extract from the POST binding page form fields to pass on
		($AR) = $rsp =~ /<input name="ar" value="(.*?)"/;
		$laststatus = 'OK';
		$lasterror = "len=".length($rsp);
	    } elsif ($cmd{$id} eq 'SP') {
		# Extract from the POST binding page form fields to pass on
		($SAMLResponse) = $rsp =~ /<input name="SAMLResponse" value="(.*?)"/;
		$laststatus = 'OK';
		$lasterror = "len=".length($rsp);
	    } elsif ($cmd{$id} eq 'ST') {
		$laststatus = 'OK';
		$lasterror = "len=".length($rsp);
	    }
	    delete $easy_url{$id};
	    delete $cmd{$id};
	    delete $key{$id};
	    delete $sesid{$id};
	    delete $send_ts{$id};
	}
    }
}

### N.B. Runs in context of inquiring user and only sends messages (such
### as diffs or end result) to the inquiring user's sessions.

sub process_timetag_response {
    my ($xx, $user, $sesid, $qs) = @_;
    
    if (length $$xx{'Name'}[0]) {
	$laststatus = 'OK';
    } else {
	$laststatus = 'ERRTT';
    }
}

sub process_simple_response {
    my ($xx, $user, $sesid, $qs) = @_;
    $laststatus = 'OK';
}

sub process_error_response {
    my ($erro, $user, $sesid, $qs) = @_;
    warn "error($erro) user($user) sesid($sesid) qs(".Dumper($qs).")";
    $laststatus = $erro;
}

sub process_sent_response {
    my ($xx, $user, $sesid, $qs) = @_;
    $lasterror = 'OK'; # Need better check to verify if message really was sent
}
} # Close if (0) several pages above

###
### Daemon management routines
###

### Persist in killing a child process

sub kill_child {
    my ($pid,$sig) = @_;
    return 1 unless $pid;
    $sig ||= USR1;  # 1 = SIGHUP, 10 = SIGUSR1 (which cause gcov friendly exit(3))
    #warn "KILL CHILD $pid";
    kill $sig, $pid;
    eval {
	local $SIG{ALRM} = sub { die "timeout\n"; };
	alarm 5;
	waitpid $pid,0;
	alarm 0;
    };
    if ($@) {
	die "waitpid $pid failed: $@ / $!" unless $@ eq "timeout\n";
	warn "Die hard process $pid refuses to die. Trying kill -9";
	kill 9, $pid for (1..3);
	alarm 5;       # If it won't die, its an error so do not catch the timeout
	waitpid $pid,0;
	alarm 0;
    }
    return 1;
}

### Check that the port numbers and take them out of the message (because
### port numbers could be variable and cause test log comparison to fail).

sub check_ports {
   my ($m) = @_;
   my @a=split (/\n/,$m);
   my %port;
   my $cont=0;
   my $fin='';
   for my $m (@a) {
       my @aux = split (/:/,$m);
       if ($aux[0] eq "search_port"){
	  if ($cont == 0){    #The first port is used to compare
	     $cont=$aux[1];
	  }else{
       	     $port{$aux[1]}++;
	  }
       }else{
           $fin .= "$m\n";
       }
   }

   $fin .= "\n";

   my $number = keys(%port);
   $fin.= "There are $number ports\n";
   $fin.="\n";
   for my $p (keys(%port)){
	if ($p < $cont){
	   $fin.= "One port minor than first port \n";
	   $fin.="\n";
	}else {  #It should not be the same port
	   $fin.= "One port mayor than first port \n";
	   $fin.="\n";
	}
   }
   return $fin;
}

sub check_nums {
   my ($m) = @_;
   my @a=split (/\n/,$m);
   my %nums;
   my $cont=0;
   my $fin='';
   for my $m (@a) {
       my @aux = split (/:/,$m);
       if ($aux[0] eq "numorder"){
       	     $nums{$aux[1]}++;
       }
   }

   $fin .= "\n";

   my $number = keys(%nums);
   $fin.= "There are $number nums\n";
   $fin.="\n";
   for my $p (keys(%nums)){
	   $fin.= "$p,";
   }
   $fin.="\n";
   return $fin;
}

sub check_for_listener {
    my $port = shift @_;
    return 1 if $always_external_test_servers;  # avoid netstat because it oopes Linux 2.5.74
    if ($uname_minus_s eq "SunOS" || $uname_minus_s eq "Darwin" || $uname_minus_s eq "AIX" || $uname_minus_s eq "Interix") {
	if (`netstat -an` =~ /\.$port\s+.+LISTEN$/m) {
	    return 1;
	}
    } elsif ($uname_minus_s eq "Linux") {
	my $netstat = `netstat -ln --inet`;
	if ($netstat =~ /(\:$port\s+.+LISTEN\s*)/) {
	    #warn "MATCH netstat($netstat)";
	    #warn "matched($1)";
	    return 1;
	}
	#warn "NO MATCH netstat($netstat)";
    } elsif (substr($uname_minus_s, 0, 9) eq "CYGWIN_NT" || $uname_minus_s eq "Windows") {
	if (`netstat -an` =~ /\:$port\s+.+LISTENING\s*/) {
	    return 1;
	}
    } else {
	die "Can't determine system type($uname_minus_s)";
    }
    return 0;
}

sub check_for_udp {
    my $port = shift @_;
    return 1 if $always_external_test_servers;  # avoid netstat 'cause it oopes Linux 2.5.74
    if ($uname_minus_s eq "SunOS") {         # Solaris8
	if (`netstat -an -P udp` =~ /^\s+\*.$port\s+Idle\s*$/m) {
	    return 1;
	}
    } elsif ($uname_minus_s eq "Darwin") {   # this probably works for SunOS 2.6, too
	if (`netstat -an` =~ /^udp[\d\s.]+\.$port\s+/m) {
	    return 1;
	}
    } elsif ($uname_minus_s eq "Linux") {
	my $x = `netstat -an`;
	#warn ">>$x<<";
	if ($x =~ /^udp[0-9. \t]+\:$port\s+/m) {
	    return 1;
	}
    } else {
	die "Unknown system type($uname_minus_s)";
    }
    return 0;
}

### Wait for a network service to ramp up and start listening for a port

$port_wait_secs = 10;

sub wait_for_port {
    my ($p) = @_;
    #return 1 if $host ne 'localhost';
    my $ret;
    my $iter = 0;
    my $sleep = 0.05;
    # sleep 10; return;
    eval {
	local $SIG{ALRM} = sub { die "timeout\n"; };
	alarm $port_wait_secs;
	while (1) {
	    last if $ret = check_for_listener($p);
	    #warn "Waiting for exe to come up on TCP port $p" if $iter++>6;
	    warn "Waiting for exe to come up on TCP port $p" if $iter++>1;
	    select(undef, undef, undef, $sleep);
	    $sleep += 0.05;
	}
	alarm 0;
	#warn "out of check_for_listener($ret)";
    };
    if ($@) {
	die "wait for port $p failed: $@ / $!" unless $@ eq "timeout\n";
	warn "Port number $p did not come up LISTENing in reasonable time";
	#success_report();
	return undef;
    }
    return 1;
}

sub wait_for_udp {
    my ($p) = @_;
    #return 1 if $host ne 'localhost';
    my $iter = 0;
    my $sleep = 0.05;
    # sleep 10; return;
    eval {
	local $SIG{ALRM} = sub { die "timeout\n"; };
	alarm $port_wait_secs;
	while (1) {
	    last if (&check_for_udp($p));
	    warn "Waiting for exe to come up on UDP port $p" if $iter++>6;
	    select(undef, undef, undef, $sleep);
	    $sleep += 0.05;
	}
	alarm 0;
    };
    if ($@) {
	die "wait for port $p failed: $@ / $!" unless $@ eq "timeout\n";
	warn "Port number $p did not come up LISTENing in reasonable time";
	#success_report();
	return undef;
    }
    #warn "udp $p came up";
    return 1;
}

# Launches a server, unless one is already listening on the targeted port,
# and arranges for logs to go to the right place.

sub launch_server {
#    for some tests to work with -e flag
#    my ($port, $log_file, @cmd_line, $file) = @_;
#    @cmd_line = "@cmd_line" . "$file";
    my ($port, $log_file, @cmd_line) = @_;
    my $pid;
    my $devnull = "</dev/null";
    if (substr($uname_minus_s, 0, 9) eq "CYGWIN_NT" || $uname_minus_s eq "Windows") {
    	$devnull = "<:NUL";
    }
    return if $host ne 'localhost';   # Presumably it was set up somewhere else
    return if check_for_listener($port);
    die "Test server (port $port) died. Tried to relaunch"
	if $relaunch_testserver{$port}++;
    #warn "Launching @cmd_line";
    if ($pid = fork) {
        #warn "launched server $pid:: @cmd_line\n";
	wait_for_port($port) or kill_child($pid) and exit 1;
	return $pid;
    }
    die "fork($port) failed: $!" unless defined $pid;
    open STDIN, $devnull;  # Keep fd 0 occupied as it has special meaning
    warn "\nEXEC @cmd_line (>$log_file pid=$$)\n" if $show_exec;
    open STDOUT, ">>$log_file"
	or die "Redirect of STDOUT to $log_file failed: $!";
    open STDERR, ">&STDOUT" or die "Redirect of STDERR failed: $!";
    exec @cmd_line;
    die "exec($port) failed: $!";
}

sub launch_udp_server {
#   for some tests to work with -e flag
#   my ($port, $log_file, @cmd_line,$file) = @_;
#   @cmd_line = "@cmd_line" . "$file";
    my ($port, $log_file, @cmd_line) = @_;
    my $pid;
    return if $host ne 'localhost';   # Presumably it was set up somewhere else
    return if check_for_udp($port);
    die "Test server died (port $port). Tried to relaunch"
	if $relaunch_testserver{$port}++;
    #warn "Launching @cmd_line";
    if ($pid = fork) {
	wait_for_udp($port) or kill_child($pid) and exit 1;
	return $pid;
    }
    die "fork($port) failed: $!" unless defined $pid;
    open STDIN, "</dev/null";  # Keep fd 0 occupied as it has special meaning
    warn "\nEXEC @cmd_line (>$log_file pid=$$)\n" if $show_exec;
    open STDOUT, ">>$log_file"
	or die "Redirect of STDOUT to $log_file failed: $!";
    open STDERR, ">&STDOUT" or die "Redirect of STDERR failed: $!";
    exec @cmd_line;
    die "exec($port) failed: $!";
}

#only kill the zxbusd that runs foo
sub kill_server {
    my @process=split ' ',`ps -efa | grep zxbusd | grep foo | grep -v "ps -efa"`;
    my $proc=$process[1];
    if ($proc){
	kill_child($proc);
	#The next line initialize the relaunch counter
	$relaunch_testserver{$testserver_port}=0;
    }
}

sub G {
    my ($cmd, $tsti, $expl, $timeout, $slow, $url) = @_;
    return unless $tst eq 'all' || $tst eq substr("$tsti ",0,length $tst);
    return if $ntst && $ntst eq substr("$tsti ",0,length $ntst);
    warn "\n======= $tsti =======";

    #my ($page, $result, %headers);  Let these be global!
    my ($proto, $host, $port, $localurl)
	= $url =~ m%^(https?)://([^:/]+)(?:(\d+))?(/.*?)$%i;
    my $usessl = ($proto =~ /^https$/i ? 1 : 0);
    $port ||= $usessl?443:80;
    
    my $test = tst_link($tsti, $expl, $url);
    my $send_ts = Time::HiRes::time();
    warn "HERE1 ".Time::HiRes::time() if $timeout_trace;
    eval {
	warn "HERE2 ".Time::HiRes::time() if $timeout_trace;
	local $SIG{ALRM} = sub { die "TIMEOUT\n"; };
	warn "HERE3 ".Time::HiRes::time() if $timeout_trace;
	alarm $timeout;
	warn "HERE4 ".Time::HiRes::time() if $timeout_trace;
	
	($page, $result, %headers)
	    = get_httpx($usessl, $host, $port, $localurl, $headers);

	warn "HERE6 ".Time::HiRes::time() if $timeout_trace;
    };
    warn "HERE7 ".Time::HiRes::time() if $timeout_trace;
    alarm 0;
    warn "HERE8 ".Time::HiRes::time() if $timeout_trace;
    my $status = $@;
    warn "HERE9 ".Time::HiRes::time() if $timeout_trace;
    my $latency = substr(Time::HiRes::time() - $send_ts, 0, 5);
    if ($status eq "TIMEOUT\n") {
	tst_print('col1r', 'Timeout', $latency, $slow, $test, '');
	$@ = 0;
	warn "Timeout ($@) ".Time::HiRes::time();
	$timeout_trace = 1;
    } elsif ($status) {
	tst_print('col1r', 'Conn. Err', $latency, $slow, $test, $status);
    } elsif ($result !~ m%^HTTP/1\.[01] 200%) {
	tst_print('col1r', 'App Err', $latency, $slow, $test, $result);
    } else {
	$lasterror = 'len='.length($page);
	tst_ok($latency, $slow, $test);
    }
}

sub call_system {
    my ($test, $timeout, $slow, $command_line, $exitval) = @_;
    my $send_ts = Time::HiRes::time();
    $? = 0;
    warn "HERE1 ".Time::HiRes::time() if $timeout_trace;
    eval {
	warn "HERE2 ".Time::HiRes::time() if $timeout_trace;
	local $SIG{ALRM} = sub { die "TIMEOUT\n"; };
	warn "HERE3 ".Time::HiRes::time() if $timeout_trace;
	alarm $timeout;
	warn "HERE4 ".Time::HiRes::time() if $timeout_trace;

	warn "EXEC($command_line)\n" if $show_exec;
	system $command_line;
	#warn "ret($ret) exit($?): $!";
	warn "HERE6 ".Time::HiRes::time() if $timeout_trace;
    };
    warn "HERE7 ".Time::HiRes::time() if $timeout_trace;
    alarm 0;
    warn "HERE8 ".Time::HiRes::time() if $timeout_trace;
    my $latency = substr(Time::HiRes::time() - $send_ts, 0, 5);
    if ($@ eq "TIMEOUT\n") {
	tst_print('col1r', 'Timeout', $latency, $slow, $test, '');
	$@ = 0;
	warn "Timeout ($@) ".Time::HiRes::time();
	#$timeout_trace = 1;
	return -1;
    } elsif ($@) {
	tst_print('col1r', 'Conn. Err', $latency, $slow, $test, $@);
	return -1;
    } elsif ($? != $exitval) {
	tst_print('col1r', 'App Err', $latency, $slow, $test, "exit=$?" . ($?==-1?"$!":""));
	return -1;
    }
    return $latency;
}

sub C { # simple command
    my ($tsti, $expl, $timeout, $slow, $command_line) = @_;
    return unless $tst eq 'all' || $tst eq substr("$tsti ",0,length $tst);
    return if $ntst && $ntst eq substr("$tsti ",0,length $ntst);
    warn "\n======= $tsti =======\n";

    my $test = tst_link($tsti, $expl, $url);
    my $latency = call_system($test, $timeout, $slow, $command_line);
    return if $latency == -1;
    tst_ok($latency, $slow, $test);
}

sub ED {  # enc-dec command with diff
    my ($tsti, $expl, $n_iter, $file, $exitval, $timeout) = @_;
    return unless $tst eq 'all' || $tst eq substr("$tsti ",0,length $tst);
    return if $ntst && $ntst eq substr("$tsti ",0,length $ntst);
    my $test = tst_link($tsti, $expl, '');
    my $slow = 0.01 * $n_iter;
    $timeout ||= 60;
    
    unlink "tmp/$tsti.out";
    
    my $latency = call_system($test, $timeout, $slow, "./zxencdectest -i $n_iter <$file >tmp/$tsti.out 2>tmp/$tsti.err", $exitval);
    return if $latency == -1;
    return if check_diff($tsti, $latency, $slow, $test);
    tst_ok($latency, $slow, $test);
}

sub ZXC {  # zxcall
    my ($tsti, $expl, $n_iter, $arg, $file) = @_;
    return unless $tst eq 'all' || $tst eq substr("$tsti ",0,length $tst);
    return if $ntst && $ntst eq substr("$tsti ",0,length $ntst);
    my $test = tst_link($tsti, $expl, '');
    my $slow = 0.03 * $n_iter;
    
    unlink "tmp/$tsti.out";
    
    #my $latency = call_system($test, 60, $slow, "./zxcall -a http://idp.tas3.pt:8081/zxididp?o=B tastest:tas123 $arg <$file >tmp/$tsti.out 2>tmp/tst.err");
    my $latency = call_system($test, 60, $slow, "./zxcall -a http://idp.tas3.pt:8081/zxididp tastest:tas123 $arg <$file >tmp/$tsti.out 2>tmp/$tsti.err");
    return if $latency == -1;
    
    #if (system "/usr/bin/diff -u t/$tsti.out tmp/$tsti.out") {
    #	tst_print('col1r', 'Diff Err', $latency, $slow, $test, '');
    #	return;
    #}
    tst_ok($latency, $slow, $test);
}

sub CMD {  # command with diff
    my ($tsti, $expl, $cmd, $exitval, $timeout, $slow) = @_;
    return unless $tst eq 'all' || $tst eq substr("$tsti ",0,length $tst);
    return if $ntst && $ntst eq substr("$tsti ",0,length $ntst);
    my $test = tst_link($tsti, $expl, '');
    $slow ||= 0.1;
    $timeout ||= 60;

    unlink "tmp/$tsti.out";
    
    my $latency = call_system($test,$timeout,$slow, "$cmd >tmp/$tsti.out 2>tmp/$tsti.err", $exitval);
    return if $latency == -1;
    return if check_diff($tsti, $latency, $slow, $test);
    tst_ok($latency, $slow, $test);
}

sub DAEMON {  # launch a daemon that can be used as test target by clients. See also KILLD.
    my ($tsti, $expl, $port, $cmd, $exitval, $timeout, $slow) = @_;
    return unless $tst eq 'all' || $tst eq substr("$tsti ",0,length $tst);
    return if $ntst && $ntst eq substr("$tsti ",0,length $ntst);
    my $test = tst_link($tsti, $expl, '');
    $slow ||= 0.1;
    $timeout ||= 60;

    unlink "tmp/$tsti.out";
    unlink "tmp/$tsti.pid";

    if ($port != -1) {
	if (check_for_listener($port)) {
	    warn "Some on is already using the port($port). Waiting a bit...";
	    sleep 1;
	    if (check_for_listener($port)) {
		die "Some on is already using the port($port). Test can not continue. killall...";
	    }
	}
    }
    $send_ts{$tsti} = Time::HiRes::time();
    my $latency = call_system($test,$timeout,$slow, "$cmd >tmp/$tsti.out 2>tmp/$tsti.err &", $exitval);
    return if $latency == -1;
    
    if ($port != -1) {
	#warn "port($port)";
	die "Daemon not up in time" unless wait_for_port($port);
    }
    tst_ok($latency, $slow, $test);
}

sub STILL {  # Check that daemon is still alive, but do not reap its results
    my ($tsti, $expl) = @_;
    return unless $tst eq 'all' || $tst eq substr("$tsti ",0,length $tst);
    return if $ntst && $ntst eq substr("$tsti ",0,length $ntst);
    my $test = tst_link($tsti, $expl, '');
    
    $pid = readall("tmp/$tsti.pid");
    if (!kill(0, $pid)) {
	tst_print('col1r', 'Daemon dead', 0, 0, $test, '');
	return;
    }
    tst_ok(0,0, $test);
}

sub KILLD {  # Collect results of a daemon (see DAEMON) after client tests.
    my ($tsti, $expl, $cmd, $exitval, $timeout, $slow) = @_;
    return unless $tst eq 'all' || $tst eq substr("$tsti ",0,length $tst);
    return if $ntst && $ntst eq substr("$tsti ",0,length $ntst);
    my $test = tst_link($tsti, $expl, '');
    $slow ||= 60;
    $timeout ||= 600;
    my $latency = substr(Time::HiRes::time() - $send_ts{$tsti}, 0, 5);

    $pid = readall("tmp/$tsti.pid");
    if (!kill(0, $pid)) {
	tst_print('col1r', 'Daemon dead', $latency, $slow, $test, '');
	return;
    }
    kill_child($pid);
    return if check_diff($tsti, $latency, $slow, $test);
    tst_ok($latency, $slow, $test);
}

##################################################################
### START
###

$cgi = cgidec($ENV{'QUERY_STRING'} || shift);
$tst = $$cgi{'tst'} || 'all';
$ntst = $$cgi{'ntst'};
$diffmeth = $$cgi{'diffmeth'} || 'nodiff';

my ($ss, $mm, $hh, $day, $mon, $year) = gmtime();
$ts = sprintf "%04d%02d%02d-%02d%02d%02d", $year+1900,$mon+1,$day,$hh,$mm,$ss;

# N.B. It appears that it is very important for the table-layout: fixed
#      to be complemented with width: specification at table and th/td level.
#
#     <table class=line width=980><tr><td class=$class1 width=80>$status</td><td class=col2 width=50>$latency</td><td class=col3 width=50>$slow</td><td class=col4 width=300>$test</td><td class=col5>$lasterror&nbsp;</td></tr></table>


#$out =
syswrite STDOUT, <<HTML if !$ascii;
<title>ZXTEST</title>
<style type="text/css" media="screen, projection">
table.line  {  table-layout: fixed; width: 980px;  }
table       {  table-layout: fixed; width: 980px;  }
td  {  vertical-align: top;  white-space: nowrap; }
td.col1  {  width=80px;  padding-left: 3px; padding-right: 7px; border-right: 1px dotted #066;  }
td.col1r {  width=60px;  padding-left: 3px; padding-right: 7px; border-right: 1px dotted #066;  background-color: red;  }
td.col1g {  width=80px;  padding-left: 3px; padding-right: 7px; border-right: 1px dotted #066;  background-color: green;  }
td.col1y {  width=80px;  padding-left: 3px; padding-right: 7px; border-right: 1px dotted #066;  background-color: yellow;  }
td.col2  {  width=50px;  padding-left: 3px; padding-right: 7px; border-right: 1px dotted #066;  }
td.col3  {  width=50px;  padding-left: 3px; padding-right: 7px; border-right: 1px dotted #066;  }
td.col4  {  width=300px; padding-left: 3px; padding-right: 7px; border-right: 1px dotted #066;  }
td.col5  {  width=500px; padding-left: 3px; padding-right: 3px; border-right: 0px;  white-space: normal; } 
</style>
<body bgcolor=white>
<h1>ZXID Testing Tool $ts $diffmeth</h1>
<a href="zxtest.pl">zxtest.pl</a>
<p>
HTML
    ;

sub tst_link {
    my ($tsti, $expl, $url) = @_;
    ++$n_tst;
    return "$tsti $expl" if $ascii;
    return qq(<a href="zxtest.pl?tst=$tsti">$tsti</a> <a href="$url">*</a> $expl);
}

sub tst_ok {
    my ($latency, $slow, $test) = @_;
    ++$n_tst_ok;
    if ($latency > $slow) {
	tst_print('col1y', "OK slow$ok_lvl", $latency, $slow, $test, $lasterror);
    } else {
	tst_print('col1g', "OK $ok_lvl", $latency, $slow, $test, $lasterror);
    }
}

sub tst_print {
    my ($class1, $status, $latency, $slow, $test, $lasterror) = @_;
    if ($ascii) {
	$status = sprintf "%-8s", $status;
	$status = $class1 eq 'col1r' ? red($status) : green($status);
	printf "%s %-5s %-5s %-50s %s\n", $status, $latency, $slow, $test, $lasterror;
    } else {
	syswrite STDOUT, "<table class=line><tr><td class=$class1>$status</td><td class=col2>$latency</td><td class=col3>$slow</td><td class=col4>$test</td><td class=col5>$lasterror&nbsp;</td></tr></table>\n";
    }
    $tst_nl_called = 0;
}

sub tst_nl {
    return if $tst_nl_called++;
    if ($ascii) {
	print "\n";
    } else {
	syswrite STDOUT, "<hr>\n";
    }
}

if ($ascii) {
    tst_print('col1', 'STATUS', 'SECS', 'GOAL', 'TEST NAME', 'MESSAGES');
} else {
    tst_print('col1', '<b>Status</b>', '<b>Secs</b>', '<b>Goal</b>', '<b>Test name</b>', '<b>Messages</b>');
}

### Service testing

CMD('HELP1', 'zxcall -h',    "./zxcall -v -h");
CMD('HELP2', 'zxpasswd -h',  "./zxpasswd -v -h");
CMD('HELP3', 'zxcot -h',     "./zxcot -v -h");
CMD('HELP4', 'zxdecode -h',  "./zxdecode -v -h");
CMD('HELP5', 'zxlogview -h', "./zxlogview -v -h");
CMD('HELP6', 'zxumacall -h', "./zxumacall -v -h");

CMD('SOENC1', 'EncDec Status',     "./zxencdectest -r 3");
CMD('ATORD1', 'Attribute sorting', "./zxencdectest -r 4");
CMD('ATCERT1', 'Attribute certificate', "./zxencdectest -r 7|wc -l");
CMD('TIMEGM1', 'zx_timegm leaps', "./zxencdectest -r 8");

CMD('CONF1', 'zxcall -dc dump config',       "./zxcall -v -v -c PATH=/var/zxid/ -dc");
CMD('CONF2', 'zxidhlo o=d dump config',      "QUERY_STRING=o=d ./zxidhlo");
CMD('CONF3', 'zxidhlo o=c dump carml',       "QUERY_STRING=o=c ./zxidhlo");
CMD('CONF4', 'zxidhlo o=B dump metadata',    "QUERY_STRING=o=B ./zxidhlo");
CMD('CONF5', 'zxididp o=B dump metadata',    "QUERY_STRING=o=B ./zxididp");

CMD('HLO1', 'zxidhlo o=M LECP check',        "QUERY_STRING=o=M ./zxidhlo");
CMD('HLO2', 'zxidhlo o=C CDC',               "QUERY_STRING=o=C ./zxidhlo");
CMD('HLO3', 'zxidhlo o=E idp select page',   "QUERY_STRING=o=E ./zxidhlo");
CMD('HLO4', 'zxidhlo o=L start sso failure', "QUERY_STRING=o=L ./zxidhlo");
CMD('HLO5', 'zxidhlo o=A artifact failure',  "QUERY_STRING=o=A ./zxidhlo");
CMD('HLO6', 'zxidhlo o=P POST failure',      "QUERY_STRING=o=P ./zxidhlo");
CMD('HLO7', 'zxidhlo o=D deleg invite fail', "QUERY_STRING=o=D ./zxidhlo");
CMD('HLO8', 'zxidhlo o=F not an idp fail',   "QUERY_STRING=o=F ./zxidhlo");

CMD('IDP1', 'zxididp o=R fail', "QUERY_STRING=o=R ./zxididp");
CMD('IDP2', 'zxididp o=F fail', "QUERY_STRING=o=F ./zxididp");
CMD('IDP3', 'zxididp o=N new user fail', "QUERY_STRING=o=N ./zxididp");
CMD('IDP4', 'zxididp o=W pwreset fail',  "QUERY_STRING=o=W ./zxididp");
CMD('IDP5', 'zxididp o=S SASL Req',  "QUERY_STRING=o=S CONTENT_LENGTH=222 ./zxididp <t/sasl_req.xml");

system 'rm -rf /var/zxid/uid/tastest';  # Delete user so we can test again
CMD('PW0', 'zxpasswd list user fail',   "./zxpasswd -l tastest",1024);  # no user
CMD('PW01', 'zxpasswd new user',    "echo tas123 | ./zxpasswd -v -new tastest");
CMD('PW1', 'zxpasswd list user',   "./zxpasswd -l tastest");
CMD('PW2', 'zxpasswd pw an ok',    "echo tas123 | ./zxpasswd -v -a tastest");
CMD('PW3', 'zxpasswd pw an fail',  "echo tas124 | ./zxpasswd -v -a tastest",1792);

system 'rm -rf /var/zxid/uid/pwtest';  # Delete user so we can test again
CMD('PW4', 'zxpasswd create user', "echo tas125 | ./zxpasswd -t y -at 'cn: pw test user\$o: test corp' -new pwtest");
CMD('PW5', 'zxpasswd change pw y',   "echo tas126 | ./zxpasswd -t y pwtest");
CMD('PW6', 'zxpasswd list user',   "./zxpasswd -l pwtest");
CMD('PW7', 'zxpasswd change pw plain',   "echo tas126 | ./zxpasswd -t 0 pwtest");
CMD('PW8', 'zxpasswd plain an ok',   "echo tas126 | ./zxpasswd -v -a pwtest");
CMD('PW9', 'zxpasswd plain an fail', "echo tas127 | ./zxpasswd -v -a pwtest",1792);

# ./zxid_httpd -p 8081 -c 'zxid*' &
CMD('META1', 'Java LEAF Meta', "curl 'http://sp.tas3.pt:8080/zxidservlet/wspleaf?o=B'");

CMD('COT1', 'zxcot list',          "./zxcot");
CMD('COT2', 'zxcot list swap',     "./zxcot -s");
CMD('COT3', 'zxcot list s2',       "./zxcot -s -s");
CMD('COT4', 'zxcot get idp meta dry', "./zxcot -g http://idp.tas3.pt:8081/zxididp?o=B -n -v");
CMD('COT5', 'zxcot get sp meta dry',"./zxcot -g http://sp.tas3.pt:8080/zxidservlet/sso?o=B -n -v");
CMD('COT6', 'zxcot my meta',       "./zxcot -m");
CMD('COT7', 'zxcot my meta add',   "./zxcot -m | ./zxcot -a");
CMD('COT8', 'zxcot gen epr',       "./zxcot -e http://localhost:1234/ testabstract http://localhost:1234/?o=B x-impossible");
CMD('COT9', 'zxcot gen epr add',   "./zxcot -e http://localhost:1234/ testabstract http://localhost:1234/?o=B x-impossible | ./zxcot -b -bs");
CMD('COT10', 'zxcot my meta',      "./zxcot -p http://localhost:1234/?o=B");
CMD('COT11', 'zxcot list s2',      "./zxcot -s /var/zxid/cot");

# ~/zxid/zxcot -c CPATH=/var/zxid/bus/ -dirs
# ~/zxid/zxcot -c 'CPATH=/var/zxid/bus/&NON_STANDARD_ENTITYID=stomp://localhost:2229/' -m | ~/zxid/zxcot -a
# ~/zxid/zxcot -c 'CPATH=/var/zxid/bus/&NON_STANDARD_ENTITYID=stomp://localhost:2229/' -m | ~/zxid/zxcot -c CPATH=/var/zxid/bus/ -a

CMD('LOG1', 'zxlogview list',      "./zxlogview /var/zxid/pem/logsign-nopw-cert.pem /var/zxid/pem/logenc-nopw-cert.pem <t/act");
CMD('LOG2', 'zxlogview test',      "./zxlogview -t /var/zxid/pem/logsign-nopw-cert.pem /var/zxid/pem/logenc-nopw-cert.pem");
CMD('LOG3', 'zxlogview receipt',   "./zxlogview -t1");

# See also README.smime for tutorial of these commands
CMD('SMIME1', 'smime key gen ca',  "echo 'commonName=TestCA|emailAddress=test\@test.com' | ./smime -kg 'description=CA' passwd tmp/careq.pem >tmp/capriv_ss.pem; wc -l tmp/capriv_ss.pem");
CMD('SMIME2', 'smime key gen joe', "echo 'commonName=Joe Smith|emailAddress=joe\@test.com' | ./smime -kg 'description=foo' passwd tmp/req.pem >tmp/priv_ss.pem; wc -l tmp/priv_ss.pem");
CMD('SMIME3', 'smime ca',          "./smime -ca tmp/capriv_ss.pem passwd 1 <tmp/req.pem >tmp/cert.pem; wc -l tmp/cert.pem");
CMD('SMIME4', 'smime code sig',    "./smime -ds tmp/priv_ss.pem passwd <t/XML1.out >tmp/XML1.sig; wc -l tmp/XML1.sig");
CMD('SMIME5', 'smime code vfy',    "cat tmp/priv_ss.pem tmp/XML1.sig |./smime -dv t/XML1.out");
CMD('SMIME6', 'smime sig',          "echo foo|./smime -mime text/plain|./smime -s tmp/priv_ss.pem passwd >tmp/foo.p7m; wc -l tmp/foo.p7m");
CMD('SMIME7', 'smime clear sig',    "echo foo|./smime -mime text/plain|./smime -cs tmp/priv_ss.pem passwd >tmp/foo.clear.smime; wc -l tmp/foo.clear.smime");
CMD('SMIME8', 'smime pubenc',       "echo foo|./smime -mime text/plain|./smime -e tmp/priv_ss.pem|wc -l");
CMD('SMIME8b', 'smime pubencdec',   "echo foo|./smime -mime text/plain|./smime -e tmp/priv_ss.pem|./smime -d tmp/priv_ss.pem passwd");
CMD('SMIME9', 'smime sigenc',       "echo foo|./smime -mime text/plain|./smime -cs tmp/priv_ss.pem passwd|./smime -e tmp/priv_ss.pem");
CMD('SMIME10', 'smime encsig',      "echo foo|./smime -mime text/plain|./smime -e tmp/priv_ss.pem|./smime -cs tmp/priv_ss.pem passwd");
CMD('SMIME11', 'smime multi sigenc', "echo bar|./smime -m image/gif t/XML1.out|./smime -cs tmp/priv_ss.pem passwd|./smime -e tmp/priv_ss.pem");
CMD('SMIME12', 'smime query sig',   "./smime -qs <tmp/foo.p7m");
CMD('SMIME13', 'smime verify',      "./smime -v tmp/priv_ss.pem <tmp/foo.p7m");
CMD('SMIME14', 'smime query cert',  "./smime -qc <tmp/cert.pem");
CMD('SMIME15', 'smime verify cert', "./smime -vc tmp/capriv_ss.pem <tmp/req.pem");
CMD('SMIME16', 'smime mime ent',    "./smime -mime text/plain <tmp/XML1.out");
CMD('SMIME17', 'smime mime ent b64',"./smime -mime_base64 image/gif <tmp/XML1.out");
CMD('SMIME18', 'smime pkcs12 exp',  "./smime -pem-p12 you\@test.com passwd pw-for-p12 <tmp/priv_ss.pem >tmp/me.p12; wc -l tmp/me.p12");
CMD('SMIME19', 'smime pkcs12 imp',  "./smime -p12-pem pw-for-p12 passwd <tmp/me.p12 >tmp/me.pem; wc -l tmp/me.pem");
CMD('SMIME20', 'smime query req',   "./smime -qr <tmp/req.pem");
CMD('SMIME21', 'smime covimp',      "echo foo|./smime -base64|./smime -cat|./smime -unbase64");

#CMD('SIG1',  'sig vry shib resp',  "./zxdecode -v -s -c AUDIENCE_FATAL=0 -c TIMEOUT_FATAL=0 -c DUP_A7N_FATAL=0 -c DUP_MSG_FATAL=0 <cal-private/shib-resp.xml");
#CMD('SIG2',  'sig vry shib post',  "./zxdecode -v -s -c AUDIENCE_FATAL=0 -c TIMEOUT_FATAL=0 -c DUP_A7N_FATAL=0 -c DUP_MSG_FATAL=0 <cal-private/shib-resp.qs");

CMD('SIG3',  'sig vry zxid resp',  "./zxdecode -v -s -c AUDIENCE_FATAL=0 -c TIMEOUT_FATAL=0 -c DUP_A7N_FATAL=0 -c DUP_MSG_FATAL=0 <t/anrs1.xml");
CMD('SIG4',  'sig vry zxid post',  "./zxdecode -v -s -c AUDIENCE_FATAL=0 -c TIMEOUT_FATAL=0 -c DUP_A7N_FATAL=0 -c DUP_MSG_FATAL=0 <t/anrs1.post");

#CMD('SIG5',  'sig vry sm resp',    "./zxdecode -v -s -c AUDIENCE_FATAL=0 -c TIMEOUT_FATAL=0 -c DUP_A7N_FATAL=0 -c DUP_MSG_FATAL=0 <t/siteminder-resp.xml");
#CMD('SIG6',  'sig vry sm post',    "./zxdecode -v -s -c AUDIENCE_FATAL=0 -c TIMEOUT_FATAL=0 -c DUP_A7N_FATAL=0 -c DUP_MSG_FATAL=0 <t/siteminder-resp.b64");

CMD('SIG7',  '* sig vry shib resp undecl prefix deep', "./zxdecode -v -s -s <t/shib-a7n2.xml");  # fail due to inclusive ns prefix that is declared only deep in the document
CMD('SIG8',  '* sig vry ping resp', "./zxdecode -v -s -s <t/ping-resp.xml");  # Ping miscanonicalizes. Fail due to lack of InclusiveNamespace/@PrefixList="xs" (and declares namespace deep in the document)
CMD('SIG9',  'sig vry ping post',  "./zxdecode -v -s -s <t/ping-resp.qs");
CMD('SIG10', 'sig vry hp a7n',     "./zxdecode -v -s -s <t/hp-a7n.xml");
CMD('SIG11', 'sig vry hp post',    "./zxdecode -v -s -s <t/hp-idp-post-resp.cgi");
CMD('SIG12', 'sig vry hp resp',    "./zxdecode -v -s -s <t/hp-idp-post-resp.xml");
CMD('SIG13', 'sig vry hp resp2',   "./zxdecode -v -s -s <t/hp-idp-post-resp2.xml");
#CMD('SIG14', 'sig vry saml artifact request',  "./zxdecode -v -s -s <t/se-req2.xml"); # no a7n
CMD('SIG15', 'sig vry saml artifact response', "./zxdecode -v -s -s <t/se-resp.xml");
CMD('SIG16', 'sig vry saml artifact response', "./zxdecode -v -s -s <t/se-req.xml");
CMD('SIG17', 'sig vry saml artifact response', "./zxdecode -v -s -s <t/se-artif-resp.xml");
#CMD('SIG18', 'sig vry prstnt-a7n',  "./zxdecode -v -s -c AUDIENCE_FATAL=0 -c TIMEOUT_FATAL=0 -c DUP_A7N_FATAL=0 -c DUP_MSG_FATAL=0 <t/prstnt-a7n.xml");  # RSA padding check fail (wrong private key)
CMD('SIG18b', 'sig vry prstnt-a7n',  "./zxdecode -v -s -s <t/prstnt-a7n.xml");

#CMD('SIG19', 'sig vry rsa-slo-req', "./zxdecode -v -s -c AUDIENCE_FATAL=0 -c TIMEOUT_FATAL=0 -c DUP_A7N_FATAL=0 -c DUP_MSG_FATAL=0 <t/rsa-slo-req.xml");
#CMD('SIG20', 'sig vry rsa-a7n', "./zxdecode -v -s -c AUDIENCE_FATAL=0 -c TIMEOUT_FATAL=0 -c DUP_A7N_FATAL=0 -c DUP_MSG_FATAL=0 <t/rsa-a7n.xml");  # RSA padding check fail (wrong private key)
CMD('SIG20b', 'sig vry rsa-a7n', "./zxdecode -v -s -s <t/rsa-a7n.xml");
#CMD('SIG21', 'sig vry rsa-a7n2', "./zxdecode -v -s -c AUDIENCE_FATAL=0 -c TIMEOUT_FATAL=0 -c DUP_A7N_FATAL=0 -c DUP_MSG_FATAL=0 <t/rsa-a7n2.xml");  # RSA padding check fail (wrong private key)
CMD('SIG21b', 'sig vry rsa-a7n2', "./zxdecode -v -s -s <t/rsa-a7n2.xml");
#CMD('SIG22', 'sig vry rsa-idp-post',  "./zxdecode -v -s -c AUDIENCE_FATAL=0 -c TIMEOUT_FATAL=0 -c DUP_A7N_FATAL=0 -c DUP_MSG_FATAL=0 <t/rsa-idp-post-resp.cgi");  # RSA padding check fail (wrong private key)
CMD('SIG22b', 'sig vry rsa-idp-post',  "./zxdecode -v -s -s <t/rsa-idp-post-resp.cgi");

#CMD('SIG23', 'sig vry rsa-idp-post-enc-a7n', "./zxdecode -v -s -c AUDIENCE_FATAL=0 -c TIMEOUT_FATAL=0 -c DUP_A7N_FATAL=0 -c DUP_MSG_FATAL=0 <t/rsa-idp-post-resp2.cgi");  # RSA padding check fail (wrong private key)

#CMD('SIG24', 'sig vry protectednet-post-enc-a7n', "./zxdecode -v -s -c AUDIENCE_FATAL=0 -c TIMEOUT_FATAL=0 -c DUP_A7N_FATAL=0 -c DUP_MSG_FATAL=0 <t/protectednet-encrypted.txt");
#CMD('SIG25', 'sig vry protectednet-resp-enc-a7n', "./zxdecode -v -s -c AUDIENCE_FATAL=0 -c TIMEOUT_FATAL=0 -c DUP_A7N_FATAL=0 -c DUP_MSG_FATAL=0 <t/protectednet-encrypted.xml");

#CMD('SIG26', 'sig vry orange simple sign', "./zxdecode -v -s -c AUDIENCE_FATAL=0 -c TIMEOUT_FATAL=0 -c DUP_A7N_FATAL=0 -c DUP_MSG_FATAL=0 <t/orange1.post-simple-sign");  # No metadata
#CMD('SIG27', 'sig vry orange simple sign2', "./zxdecode -v -s -c AUDIENCE_FATAL=0 -c TIMEOUT_FATAL=0 -c DUP_A7N_FATAL=0 -c DUP_MSG_FATAL=0 <t/orange2-sig-data.b64");  # No metadata

#CMD('SIG28', 'sig vry ibm-enc-a7n', "./zxdecode -v -s -c AUDIENCE_FATAL=0 -c TIMEOUT_FATAL=0 -c DUP_A7N_FATAL=0 -c DUP_MSG_FATAL=0 <t/ibm-enc-a7n.xml");
#CMD('SIG29', 'sig vry ibm-resp-extra-ns', "./zxdecode -v encdec-s -c AUDIENCE_FATAL=0 -c TIMEOUT_FATAL=0 -c DUP_A7N_FATAL=0 -c DUP_MSG_FATAL=0 <t/ibm-resp-extra-ns.xml");  # No a7n, no metadata

#CMD('SIG30', 'sig vry simplesamlphp enc a7n', "./zxdecode -v -s -c AUDIENCE_FATAL=0 -c TIMEOUT_FATAL=0 -c DUP_A7N_FATAL=0 -c DUP_MSG_FATAL=0 <t/encrypted-simplesamlphp.xml"); # Messed up by whitespace
#CMD('SIG31', 'sig vry simplesamlphp enc post', "./zxdecode -v -s -c AUDIENCE_FATAL=0 -c TIMEOUT_FATAL=0 -c DUP_A7N_FATAL=0 -c DUP_MSG_FATAL=0 <t/encrypted-simplesamlphp.txt"); # Messed up by whitespace

#CMD('SIG32', 'sig vry enc-nid-enc-attr', "./zxdecode -v -s -c AUDIENCE_FATAL=0 -c TIMEOUT_FATAL=0 -c DUP_A7N_FATAL=0 -c DUP_MSG_FATAL=0 <t/enc-nid-enc-attr.xml");  # wrong private key
CMD('SIG32b', 'sig vry enc-nid-enc-attr', "./zxdecode -v -s -s <t/enc-nid-enc-attr.xml");
#CMD('SIG33', 'sig vry a7n stijn', "./zxdecode -v -s -c AUDIENCE_FATAL=0 -c TIMEOUT_FATAL=0 -c DUP_A7N_FATAL=0 -c DUP_MSG_FATAL=0 <t/assertion-stijn-20100108.xml");  # Corrupt with non-printable chars
#CMD('SIG34', 'sig vry symsp-ibmidp-slo',     "./zxdecode -v -s -s <t/symsp-ibmidp-slo.xml");
#CMD('SIG35', 'sig vry symsp-symidp-slo',     "./zxdecode -v -s -s <t/symsp-symidp-slo-soap.xml");
#CMD('SIG36', 'sig vry zxidp-ki-old',     "./zxdecode -v -s -s <t/zxidp-ki-a7n-20100906.xml"); # ***fail canon
CMD('SIG37', 'sig vry', "./zxdecode -v -s -s <t/enve-sigval-err.xml", 2560);
CMD('SIG38', 'sig vry', "./zxdecode -v -s -s <t/default-ns-req-simple.xml");
CMD('SIG39', 'sig vry', "./zxdecode -v -s -s <t/default-ns-req-simple-nons.xml", 2560);
CMD('SIG40', 'sig vry', "./zxdecode -v -s -s <t/default-ns-req.xml");
CMD('SIG41', 'sig vry', "./zxdecode -v -s -s <t/soag-namespace-issue.xml");
CMD('SIG42', 'sig vry shib a7n art',  "./zxdecode -v -s -c AUDIENCE_FATAL=0 -c TIMEOUT_FATAL=0 -c DUP_A7N_FATAL=0 -c DUP_MSG_FATAL=0 <t/shib-a7n-art.xml");
CMD('SIG43', 'sig vry shib a7n art2',  "./zxdecode -v -s -c AUDIENCE_FATAL=0 -c TIMEOUT_FATAL=0 -c DUP_A7N_FATAL=0 -c DUP_MSG_FATAL=0 <t/shib-a7n-art2.xml");
CMD('SIG44', 'sig vry shib a7n art3',  "./zxdecode -v -s -c AUDIENCE_FATAL=0 -c TIMEOUT_FATAL=0 -c DUP_A7N_FATAL=0 -c DUP_MSG_FATAL=0 <t/shib-a7n-art3.xml");

ED('XML1',  'Decode-Encode SO and WO: ns-bug',  1000, 't/default-ns-bug.xml');
ED('XML2',  'Decode-Encode SO and WO: azrq1',   1000, 't/azrq1.xml');
ED('XML3',  'Decode-Encode SO and WO: azrs1',   1000, 't/azrs1.xml');
ED('XML4',  '* Decode-Encode RIS malformed 1',  1,    't/risaris-bad.xml');  # Order of unknown elements gets inverted
ED('XML5',  'Decode-Encode SO and WO: ana7n1',  1000, 't/ana7n1.xml');
ED('XML6',  'Decode-Encode SO and WO: anrq1',   1000, 't/anrq1.xml');
ED('XML7',  'Decode-Encode SO and WO: anrs1',   1000, 't/anrs1.xml');
ED('XML8',  'Decode-Encode SO and WO: dirq1',   1000, 't/dirq1.xml');
ED('XML9',  'Decode-Encode SO and WO: dirs1',   1000, 't/dirs1.xml');
ED('XML10', 'Decode-Encode SO and WO: dirq2',   1000, 't/dirq2.xml');
ED('XML11', 'Decode-Encode SO and WO: dia7n1',  1000, 't/dia7n1.xml');
ED('XML12', 'Decode-Encode SO and WO: epr1',    1000, 't/epr1.xml');
ED('XML13', 'Decode-Encode SO and WO: wsrq1',   1000, 't/wsrq1.xml');
ED('XML14', 'Decode-Encode SO and WO: wsrs1',   1000, 't/wsrs1.xml');
ED('XML15', 'Decode-Encode SO and WO: wsrq2',   1000, 't/wsrq2.xml');
ED('XML16', 'Decode-Encode SO and WO: wsrs2',   1000, 't/wsrs2.xml');
ED('XML17', 'Decode-Encode SO and WO: as-req',  1000, 't/as-req.xml');
ED('XML18', 'Decode-Encode SO and WO: as-resp', 1000, 't/as-resp.xml');
ED('XML19', 'Decode-Encode SO and WO: authnreq',1000, 't/authnreq.xml');
ED('XML20', 'Decode-Encode SO and WO: sun-md',  10, 't/sun-md.xml');
ED('XML21', 'Decode-Encode SO and WO: provisioning-req',  10, 't/pmdreg-req.xml');
ED('XML22', 'Decode-Encode SO and WO: provisioning-resp', 10, 't/pmdreg-resp.xml');
ED('XML23', 'Decode-Encode SO and WO: pds-create-uc1',    10, 't/pds-create-uc1.xml');
ED('XML24', 'Decode-Encode SO and WO: pds-query-uc1',     10, 't/pds-query-uc1.xml');
ED('XML25', 'Decode-Encode SO and WO: AdvClient hoard-trnsnt', 10, 't/ac-hoard-trnsnt.xml');
ED('XML26', 'Decode-Encode SO and WO: AdvClient ming-trnsnt',  10, 't/ac-ming-trnsnt.xml');
ED('XML27', 'Decode-Encode SO and WO: AdvClient ming-prstnt',  10, 't/ac-ming-prstnt.xml');
ED('XML28', 'Decode-Encode SO and WO: AdvClient ming-ntt',     10, 't/ac-ming-ntt.xml');
ED('XML29', 'Decode-Encode SO and WO: AdvClient ntt-fixed',    10, 't/ac-ming-ntt-fixed.xml');
ED('XML30', 'Decode-Encode SO and WO: zx a7n',    10, 't/a7n-len-err.xml');
ED('XML31', 'Decode-Encode SO and WO: covimp',    10, 't/covimp.xml');
ED('XML32', 'Decode-Encode SO and WO: bad-body malformed close',  10, 't/bad-body.xml');
ED('XML33', 'Decode-Encode SO and WO: bad-body2 malformed close', 10, 't/bad-body2.xml');

# *** TODO: add EncDec for all other types of protocol messages
# *** TODO: add specific SSO signature validation tests

# *** TODO: benchmark raw RSA performance using logging w/ zxlogview

# /apps/bin/mini_httpd -p 8081 -c 'zxid*' &   # IdP
# /apps/bin/mini_httpd -p 8082 -c 'zxid*' &   # SP

# *** TODO: set up test IdP using zxcot (for disco registrations and bootstrap) and zxpasswd
# *** TODO: set up test SP
# *** TODO: set up test WSP


ZXC('ZXC-AS1', 'Authentication Service call: SSO + AZ', 1000, "-az ''", '/dev/null');
CMD('ZXC-AS2', 'Authentication Service call: An Fail', "./zxcall -d -a http://idp.tas3.pt:8081/zxididp test:tas -t urn:x-foobar -e '<foobar>Hello</foobar>' -b", 256);

ZXC('ZXC-IM1', 'Identity Mapping Service call', 1000, "-im http://sp.tas3.pt:8081/zxidhrxmlwsp?o=B", '/dev/null');
ZXC('ZXC-IM2', '* SAML NID Map call', 1000, "-nidmap http://sp.tas3.pt:8081/zxidhrxmlwsp?o=B", '/dev/null');  # SEGV
ZXC('ZXC-IM3', 'SSOS call', 1000, "-t urn:liberty:ims:2006-08", 't/ssos-req.xml');

ZXC('ZXC-DI1', 'Discovery Service call', 1000, "-di '' -t urn:x-foobar -nd", '/dev/null');
ZXC('ZXC-DI2', 'List EPR cache', 1, "-l", '/dev/null');

ZXC('ZXC-WS1', 'AS + WSF call: idhrxml',  1000, "-t urn:id-sis-idhrxml:2007-06:dst-2.1", 't/id-hrxml-rq.xml');
ZXC('ZXC-WS2', 'AS + WSF call: x-foobar', 1000, "-t urn:x-foobar", 't/x-foobar-rq.xml');

CMD('ZXC-WS3', 'AS + WSF call leaf (x-recurs)', "./zxcall -d -a http://idp.tas3.pt:8081/zxididp test:foo -t x-recurs -e '<foobar>Hello</foobar>' -b");
CMD('ZXC-WS4', 'AS + WSF call EPR not found', "./zxcall -d -a http://idp.tas3.pt:8081/zxididp test:foo -t x-none -e '<foobar>Hello</foobar>' -b",512);
CMD('ZXC-WS5', 'AS + WSF call bad pw', "./zxcall -d -a http://idp.tas3.pt:8081/zxididp test:bad -t x-none -e '<foobar>Hello</foobar>' -b",256);

CMD('ZXC-WS6', 'AS + WSF call hr-xml bad', "./zxcall -d -a http://idp.tas3.pt:8081/zxididp test:foo -t urn:id-sis-idhrxml:2007-06:dst-2.1 -e '<foobar>Hello</foobar>' -b");

CMD('ZXC-WS7', 'AS + WSF call hr-xml create', "./zxcall -d -a http://idp.tas3.pt:8081/zxididp test:foo -t urn:id-sis-idhrxml:2007-06:dst-2.1 -e '<idhrxml:Create xmlns:idhrxml=\"urn:id-sis-idhrxml:2007-06:dst-2.1\"><idhrxml:CreateItem><idhrxml:NewData><hrxml:Candidate xmlns:hrxml=\"http://ns.hr-xml.org/2007-04-15\">test candidate</hrxml:Candidate></idhrxml:NewData></idhrxml:CreateItem></idhrxml:Create>' -b");
CMD('ZXC-WS8', 'AS + WSF call hr-xml query', "./zxcall -d -a http://idp.tas3.pt:8081/zxididp test:foo -t urn:id-sis-idhrxml:2007-06:dst-2.1 -e '<idhrxml:Query xmlns:idhrxml=\"urn:id-sis-idhrxml:2007-06:dst-2.1\"><idhrxml:QueryItem><idhrxml:Select>test query</idhrxml:Select></idhrxml:QueryItem></idhrxml:Query>' -b");
CMD('ZXC-WS9', 'AS + WSF call hr-xml mod', "./zxcall -d -a http://idp.tas3.pt:8081/zxididp test:foo -t urn:id-sis-idhrxml:2007-06:dst-2.1 -e '<idhrxml:Modify xmlns:idhrxml=\"urn:id-sis-idhrxml:2007-06:dst-2.1\"><idhrxml:ModifyItem><idhrxml:Select>test query</idhrxml:Select><idhrxml:NewData><hrxml:Candidate xmlns:hrxml=\"http://ns.hr-xml.org/2007-04-15\">test mod</hrxml:Candidate></idhrxml:NewData></idhrxml:ModifyItem></idhrxml:Modify>' -b");
CMD('ZXC-WS10', 'AS + WSF call hr-xml mod', "./zxcall -d -a http://idp.tas3.pt:8081/zxididp test:foo -t urn:id-sis-idhrxml:2007-06:dst-2.1 -e '<idhrxml:Delete xmlns:idhrxml=\"urn:id-sis-idhrxml:2007-06:dst-2.1\"><idhrxml:DeleteItem><idhrxml:Select>test query</idhrxml:Select></idhrxml:DeleteItem></idhrxml:Delete>' -b");

### Simulated browsing tests (a bit fragile)

#$idpurl='http://idp.tas3.pt:8081/zxididp';

# sudo ./zxid_httpd -S /var/zxid/pem/enc-nopw-cert.pem -u sampo -c 'zxid*' &
#$idpurl='https://yourhost.example.com/zxididp';
#$spurl='https://yourhost.example.com/zxidhlo';

# ./zxid_httpd -S /var/zxid/pem/enc-nopw-cert.pem -p 8443 -u sampo -c 'zxid*' &
$idpurl='https://yourhost.example.com:8443/zxididp';
$spurl='https://yourhost.example.com:8443/zxidhlo';

CMD('META2', 'IdP meta', "curl -k $idpurl?o=B");
CMD('META3', 'SP meta',  "curl -k $spurl?o=B");
CMD('META4', 'IdP conf', "curl -k $idpurl?o=d");
CMD('META5', 'SP conf',  "curl -k $spurl?o=d");

tA('ST','LOGIN-IDP1', 'IdP Login screen',  "$idpurl?o=F");
tA('ST','LOGIN-IDP2', 'IdP Give password', "$idpurl?au=&alp=+Login+&au=test&ap=foo&fc=1&fn=prstnt&fq=&fy=&fa=&fm=&fp=0&ff=0&ar=&zxapp=");
tA('ST','LOGIN-IDP3', 'IdP Local Logout',  "$idpurl?gl=+Local+Logout+");

tA('ST','SSOHLO1', 'IdP selection screen', "$spurl?o=E");
tA('AR','SSOHLO2', 'Selected IdP', "$spurl?e=&l0http%3A%2F%2Fidp.tas3.pt%3A8081%2Fzxididp=+Login+with+TAS3+Demo+IdP+%28http%3A%2F%2Fidp.tas3.pt%3A8081%2Fzxididp%29+&fc=1&fn=prstnt&fr=&fq=&fy=&fa=&fm=&fp=0&ff=0");

tA('SP','SSOHLO3', 'Login to IdP', "$idpurl?au=&alp=+Login+&au=test&ap=foo&fc=1&fn=prstnt&fq=&fy=&fa=&fm=&fp=0&ff=0&ar=$AR&zxapp=");

pA('ST','SSOHLO4', 'POST to SP',      "$spurl?o=P", "SAMLResponse=$SAMLResponse");
tA('ST','SSOHLO5', 'SP SOAP Az',      "$spurl?gv=1");
tA('ST','SSOHLO6', 'SP SOAP defed',   "$spurl?gu=1");
tA('ST','SSOHLO7', 'SP SOAP defed',   "$spurl?gt=1");
tA('ST','SSOHLO8', 'SP SOAP logout',  "$spurl?gs=1");
tA('ST','SSOHLO9', 'SP local logout', "$spurl?gl=+Local+Logout+");

#tA('ST','javaexit', 'http://sp1.zxidsp.org:8080/appdemo?exit');

# *** TODO: add through GUI testing for SSO
# *** TODO: via zxidhlo
# *** TODO: via mod_auth_saml
# *** TODO: via zxidhlo.php
# *** TODO: via Net::SAML
# *** TODO: via SSO servlet
# http://sp1.zxidsp.org:8081/zxidhlo?o=E
# http://sp1.zxidsp.org:8080/zxidservlet/zxidHLO?o=E
# http://sp.tas3.pt:8080/zxidservlet/appdemo
# http://sp.tas3.pt:8080/zxidservlet/wscprepdemo

###
### UMA and OAUTH2 tests
###
# ./zxid_httpd -p 8081 -c 'zxid*' &

tA('ST','OAZ-JWKS1', 'Java Web Key Set test',  'http://idp.tas3.pt:8081/zxididp?o=j');
CMD('OAZ-DCR1', 'Dynamic CLient Registration', "./zxumacall -u 'http://sp.tas3.pt:8081/zxididp?o=J' -iat foobar-iat -dynclireg");

###
### Audit bus tests
###

# N.B. Although the nonSSL port should be 2228, we use 2229 so we can use same metadata
$busd_conf = "CPATH=/var/zxid/bus/&NON_STANDARD_ENTITYID=stomp://localhost:2229/";
$bus_cli_conf = "CPATH=/var/zxid/buscli/&BUS_URL=stomp://localhost:2229/&BUS_PW=pw123&BURL=https://buscli.zxid.org/";
$bus_cli_conf_badpw = "CPATH=/var/zxid/buscli/&BUS_URL=stomp://localhost:2229/&BUS_PW=pw124&BURL=https://buscli.zxid.org/";
$bus_list_conf = "CPATH=/var/zxid/buslist/&BUS_URL=stomp://localhost:2229/&BUS_PW=pw123&BURL=https://buslist.zxid.org/";
$bus_list2_conf = "CPATH=/var/zxid/buslist2/&BUS_URL=stomp://localhost:2229/&BUS_PW=pw123&BURL=https://buslist2.zxid.org/";

# For SSL tests it is important to NOT supply BUS_PW so that ClientTLS takes precedence.
$bussd_conf = "CPATH=/var/zxid/bus/&NON_STANDARD_ENTITYID=stomps://localhost:2229/";
$buss_cli_conf = "CPATH=/var/zxid/buscli/&BUS_URL=stomps://localhost:2229/&BURL=https://buscli.zxid.org/";
$buss_list_conf = "CPATH=/var/zxid/buslist/&BUS_URL=stomps://localhost:2229/&BURL=https://buslist.zxid.org/";
$buss_list2_conf = "CPATH=/var/zxid/buslist2/&BUS_URL=stomps://localhost:2229/&BURL=https://buslist2.zxid.org/";

# Metadata exchange
#./zxcot -c 'CPATH=/var/zxid/buscli/&BUS_URL=stomp://localhost:2229/&BUS_PW=pw123&BURL=https://buscli.zxid.org/' -dirs
#./zxcot -c 'CPATH=/var/zxid/buslist/&BUS_URL=stomp://localhost:2229/&BUS_PW=pw123&BURL=https://buslist.zxid.org/' -dirs
#./zxcot -c 'CPATH=/var/zxid/buslist2/&BUS_URL=stomp://localhost:2229/&BUS_PW=pw123&BURL=https://buslist2.zxid.org/' -dirs

# Metadata from clients to server
# ./zxcot -c 'CPATH=/var/zxid/buscli/&BUS_URL=stomp://localhost:2229/&BUS_PW=pw123&BURL=https://buscli.zxid.org/' -m | ./zxcot -c 'CPATH=/var/zxid/bus/&NON_STANDARD_ENTITYID=stomp://localhost:2229/' -a
# ./zxcot -c 'CPATH=/var/zxid/buslist/&BUS_URL=stomp://localhost:2229/&BUS_PW=pw123&BURL=https://buslist.zxid.org/' -m | ./zxcot -c 'CPATH=/var/zxid/bus/&NON_STANDARD_ENTITYID=stomp://localhost:2229/' -a
# ./zxcot -c "CPATH=/var/zxid/buslist2/&BUS_URL=stomp://localhost:2229/&BUS_PW=pw123&BURL=https://buslist2.zxid.org/" -m | ./zxcot -c 'CPATH=/var/zxid/bus/&NON_STANDARD_ENTITYID=stomp://localhost:2229/' -a

# Metadata from server to clients
# ./zxcot -c 'CPATH=/var/zxid/bus/&NON_STANDARD_ENTITYID=stomp://localhost:2229/' -m | ./zxcot -c 'CPATH=/var/zxid/buscli/&BUS_URL=stomp://localhost:2229/&BUS_PW=pw123&BURL=https://buscli.zxid.org/' -a
# ./zxcot -c 'CPATH=/var/zxid/bus/&NON_STANDARD_ENTITYID=stomp://localhost:2229/' -m | ./zxcot -c 'CPATH=/var/zxid/buslist/&BUS_URL=stomp://localhost:2229/&BUS_PW=pw123&BURL=https://buslist.zxid.org/' -a
# ./zxcot -c 'CPATH=/var/zxid/bus/&NON_STANDARD_ENTITYID=stomp://localhost:2229/' -m | ./zxcot -c 'CPATH=/var/zxid/buslist2/&BUS_URL=stomp://localhost:2229/&BUS_PW=pw123&BURL=https://buslist2.zxid.org/' -a

# Provision bus users
# echo -n 'pw123' | ./zxpasswd -new 2E_uLovDu748vn9dWEM6tqVzqUQ /var/zxid/bus/uid/  # buslist
# echo -n 'pw123' | ./zxpasswd -new YJCLRHKIxyjlbnwT3bJrjgphlDA /var/zxid/bus/uid/  # buslist2
# echo -n 'pw123' | ./zxpasswd -new RjZmauuglW8TSTZjfGQ5zldszZM /var/zxid/bus/uid/  # buscli

# To create bus users, you should follow these steps
# 0. Create dir: ./zxmkdirs.sh /var/zxid/buslist2/
# 1. Run ./zxbuslist -c 'URL=https://sp.foo.com/' -dc to determine the entity ID
# 2. Convert entity ID to SHA1 hash: ./zxcot -p 'http://sp.foo.com?o=B'
# 3. Create the user: ./zxpasswd -at 'eid: http://sp.foo.com?o=B' -new G2JpTSX_dbdJ7frhYNpKWGiMdTs /var/zxid/bus/uid/ <passwd  # N.B. the default password is pw123
# 4. To enable ClientTLS authentication, determine the subject_hash of
#    the encryption certificate and symlink that to the main account:
#      > openssl x509 -subject_hash -noout </var/zxid/buscli/pem/enc-nopw-cert.pem
#      162553b8
#      > ln -s /var/zxid/bus/uid/G2JpTSX_dbdJ7frhYNpKWGiMdTs /var/zxid/bus/uid/162553b8

### Single client, various numbers of threads at zxbusd

CMD('ZXBUS00', 'Clean', "rm -f /var/zxid/bus/ch/default/*  /var/zxid/bus/ch/default/.del/*  /var/zxid/bus/ch/default/.ack/*");
CMD('ZXBUS01', 'Fail connect tailf', "./zxbustailf -d -d -c '$bus_cli_conf' -e 'failbar'", 256);
CMD('ZXBUS02', 'Fail connect list',  "./zxbuslist -d -d -c '$bus_list_conf'", 256);

tst_nl();
DAEMON('ZXBUS10', 'zxbusd 1', 2229, "./zxbusd -pid tmp/ZXBUS10.pid -c '$busd_conf' -d -d -nthr 1 -nfd 11 -npdu 500 -p stomp:0.0.0.0:2229");
DAEMON('ZXBUS10b', 'zxbuslist 1', -1, "./zxbuslist -pid tmp/ZXBUS10b.pid -d -d -c '$bus_list_conf'");
CMD('ZXBUS11a', 'Bad pw', "./zxbustailf -d -d -c '$bus_cli_conf_badpw' -e 'foo bar'", 256);
CMD('ZXBUS11', 'One shot', "./zxbustailf -d -d -c '$bus_cli_conf' -e 'foo bar'");
STILL('ZXBUS10b', 'zxbuslist 1 still there');
CMD('ZXBUS12', 'zero len', "./zxbustailf -d -d -c '$bus_cli_conf' -e ''");
CMD('ZXBUS13', 'len1',     "./zxbustailf -d -d -c '$bus_cli_conf' -e 'F'");
CMD('ZXBUS14', '10x20 battery', "./zxbustailf -d -d -c '$bus_cli_conf' -e 'foo bar' -i 10 -is 20", 0, 60, 10);
CMD('ZXBUS15', 'len2',     "./zxbustailf -d -d -c '$bus_cli_conf' -e 'F'");
CMD('ZXBUS19', 'dump',     "./zxbustailf -c '$bus_cli_conf' -ctl 'dump'");
KILLD('ZXBUS10b', 'collect zxbuslist 1');
KILLD('ZXBUS10', 'collect zxbusd 1');

# 20 two thread debug

tst_nl();
DAEMON('ZXBUS20', 'zxbusd 2', 2229, "./zxbusd -pid tmp/ZXBUS20.pid -c '$busd_conf' -d -d -nthr 2 -nfd 11 -npdu 700 -p stomp:0.0.0.0:2229");
DAEMON('ZXBUS20b', 'zxbuslist 1', -1, "./zxbuslist -pid tmp/ZXBUS20b.pid -d -d -c '$bus_list_conf'");
CMD('ZXBUS21', 'One shot', "./zxbustailf -d -d -c '$bus_cli_conf' -e 'foo bar'");
CMD('ZXBUS21b','zxbuslist 2 one shot', "./zxbuslist -o 1 -d -d -c '$bus_list2_conf'");
CMD('ZXBUS22', 'zero len', "./zxbustailf -d -d -c '$bus_cli_conf' -e ''");
CMD('ZXBUS23', 'len1',     "./zxbustailf -d -d -c '$bus_cli_conf' -e 'F'");
CMD('ZXBUS24', '10x20 battery', "./zxbustailf -d -d -c '$bus_cli_conf' -e 'foo bar' -i 10 -is 20", 0, 40, 10);
CMD('ZXBUS25', 'len2',     "./zxbustailf -d -d -c '$bus_cli_conf' -e 'F'");
CMD('ZXBUS29', 'dump',     "./zxbustailf -c '$bus_cli_conf' -ctl 'dump'");
KILLD('ZXBUS20b', 'collect zxbuslist 1');
KILLD('ZXBUS20', 'collect zxbusd 2');

# 30 single thread nodebug, two listeners

tst_nl();
DAEMON('ZXBUS30', 'zxbusd 3', 2229, "./zxbusd -pid tmp/ZXBUS30.pid -c '$busd_conf' -nthr 1 -nfd 1000 -npdu 5000 -p stomp:0.0.0.0:2229");
DAEMON('ZXBUS30b','zxbuslist 1',-1,"./zxbuslist -pid tmp/ZXBUS30b.pid -c '$bus_list_conf'");
CMD('ZXBUS31', 'One shot', "./zxbustailf -c '$bus_cli_conf' -e 'foo bar'");
DAEMON('ZXBUS31b','zxbuslist 2',-1,"./zxbuslist -pid tmp/ZXBUS31b.pid -c '$bus_list2_conf'");
CMD('ZXBUS32', 'zero len', "./zxbustailf -c '$bus_cli_conf' -e ''");
CMD('ZXBUS33', 'len1',     "./zxbustailf -c '$bus_cli_conf' -e 'F'");
CMD('ZXBUS34', '10x20 battery', "./zxbustailf -c '$bus_cli_conf' -e 'foo bar' -i 10 -is 20", 0, 40, 10);
CMD('ZXBUS35', 'len2',     "./zxbustailf -c '$bus_cli_conf' -e 'F'");
CMD('ZXBUS39', 'dump',     "./zxbustailf -c '$bus_cli_conf' -ctl 'dump'");
KILLD('ZXBUS30b', 'collect zxbuslist 1');
KILLD('ZXBUS31b', 'collect zxbuslist 2');
KILLD('ZXBUS30', 'collect zxbusd 3');

# 40 two thread nodebug, two listeners

tst_nl();
DAEMON('ZXBUS40', 'zxbusd 4', 2229, "./zxbusd -pid tmp/ZXBUS40.pid -c '$busd_conf' -nthr 2 -nfd 1000 -npdu 5000 -p stomp:0.0.0.0:2229");
DAEMON('ZXBUS40b','zxbuslist 1',-1,"./zxbuslist -pid tmp/ZXBUS40b.pid -c '$bus_list_conf'");
CMD('ZXBUS41', 'One shot', "./zxbustailf -c '$bus_cli_conf' -e 'foo bar'");
sleep(1);
CMD('ZXBUS41b','zxbuslist 2 one shot', "./zxbuslist -o 1 -d -d -c '$bus_list2_conf'", 0, 10, 1);
CMD('ZXBUS42', 'zero len', "./zxbustailf -c '$bus_cli_conf' -e ''");
DAEMON('ZXBUS42b','zxbuslist 2',-1,"./zxbuslist -pid tmp/ZXBUS42b.pid -c '$bus_list2_conf'");
CMD('ZXBUS43', 'len1',     "./zxbustailf -c '$bus_cli_conf' -e 'F'");
CMD('ZXBUS44', '10x20 battery', "./zxbustailf -c '$bus_cli_conf' -e 'foo bar' -i 10 -is 20", 0, 60, 10);
CMD('ZXBUS45', 'len2',     "./zxbustailf -c '$bus_cli_conf' -e 'F'");
CMD('ZXBUS49', 'dump',     "./zxbustailf -c '$bus_cli_conf' -ctl 'dump'");
KILLD('ZXBUS40b', 'collect zxbuslist 1');
KILLD('ZXBUS42b', 'collect zxbuslist 2');
KILLD('ZXBUS40', 'collect zxbusd 4');

# *** add tests with some listeners offline and coming back online later

# 50 three thread debug

tst_nl();
DAEMON('ZXBUS50', 'zxbusd 5', 2229, "./zxbusd -pid tmp/ZXBUS50.pid -c '$busd_conf' -d -d -nthr 3 -nfd 1000 -npdu 5000 -p stomp:0.0.0.0:2229");
DAEMON('ZXBUS50b','zxbuslist 1',-1,"./zxbuslist -pid tmp/ZXBUS50b.pid -d -d -c '$bus_list_conf'");
CMD('ZXBUS51', 'One shot', "./zxbustailf -d -d -c '$bus_cli_conf' -e 'foo bar'");
CMD('ZXBUS52', 'zero len', "./zxbustailf -d -d -c '$bus_cli_conf' -e ''");
CMD('ZXBUS52b','zxbuslist 2 one shot',  "./zxbuslist -o 1 -d -d -c '$bus_list2_conf'", 0, 10, 1);
CMD('ZXBUS52c','zxbuslist 2 one shot2', "./zxbuslist -o -1 -d -d -c '$bus_list2_conf'", 0, 10, 1);
CMD('ZXBUS53', 'len1',     "./zxbustailf -d -d -c '$bus_cli_conf' -e 'F'");
DAEMON('ZXBUS53b','zxbuslist 2',-1,"./zxbuslist -pid tmp/ZXBUS53b.pid -d -d -c '$bus_list2_conf'");
CMD('ZXBUS54', '10x20 battery', "./zxbustailf -d -d -c '$bus_cli_conf' -e 'foo bar' -i 10 -is 20", 0, 40, 10);
CMD('ZXBUS55', 'len2',     "./zxbustailf -d -d -c '$bus_cli_conf' -e 'F'");
CMD('ZXBUS59', 'dump',     "./zxbustailf -c '$bus_cli_conf' -ctl 'dump'");
KILLD('ZXBUS50b', 'collect zxbuslist 1');
KILLD('ZXBUS53b', 'collect zxbuslist 2');
KILLD('ZXBUS50', 'collect zxbusd 5');

# 60 three thread nodebug

tst_nl();
DAEMON('ZXBUS60', 'zxbusd 6', 2229, "./zxbusd -pid tmp/ZXBUS60.pid -c '$busd_conf' -nthr 3 -nfd 1000 -npdu 5000 -p stomp:0.0.0.0:2229");
DAEMON('ZXBUS60b','zxbuslist 1',-1,"./zxbuslist -pid tmp/ZXBUS60b.pid -d -d -c '$bus_list_conf'");
CMD('ZXBUS61', 'One shot', "./zxbustailf -c '$bus_cli_conf' -e 'foo bar'");
CMD('ZXBUS62', 'zero len', "./zxbustailf -c '$bus_cli_conf' -e ''");
CMD('ZXBUS62b','zxbuslist 2 one shot',  "./zxbuslist -o 1 -d -d -c '$bus_list2_conf'", 0, 10, 1);
CMD('ZXBUS63', 'len1',     "./zxbustailf -c '$bus_cli_conf' -e 'F'");
DAEMON('ZXBUS63b','zxbuslist 2',-1,"./zxbuslist -pid tmp/ZXBUS63b.pid -d -d -c '$bus_list2_conf'");
CMD('ZXBUS64', '10x20 battery', "./zxbustailf -c '$bus_cli_conf' -e 'foo bar' -i 10 -is 20", 0, 40, 10);
CMD('ZXBUS65', 'len2',     "./zxbustailf -c '$bus_cli_conf' -e 'F'");
CMD('ZXBUS69', 'dump',     "./zxbustailf -c '$bus_cli_conf' -ctl 'dump'");
KILLD('ZXBUS60b', 'collect zxbuslist 1');
KILLD('ZXBUS63b', 'collect zxbuslist 2');
KILLD('ZXBUS60', 'collect zxbusd 6');

# 70 ten thread debug

tst_nl();
DAEMON('ZXBUS70', 'zxbusd 7', 2229, "./zxbusd -pid tmp/ZXBUS70.pid -c '$busd_conf' -d -d -nthr 10 -nfd 1000 -npdu 5000 -p stomp:0.0.0.0:2229");
DAEMON('ZXBUS70b','zxbuslist 1',-1,"./zxbuslist -pid tmp/ZXBUS70b.pid -d -d -c '$bus_list_conf'");
CMD('ZXBUS71', 'One shot', "./zxbustailf -d -d -c '$bus_cli_conf' -e 'foo bar'");
CMD('ZXBUS72', 'zero len', "./zxbustailf -d -d -c '$bus_cli_conf' -e ''");
CMD('ZXBUS72b','zxbuslist 2 one shot',  "./zxbuslist -o 1 -d -d -c '$bus_list2_conf'", 0, 10, 1);
CMD('ZXBUS73', 'len1',     "./zxbustailf -d -d -c '$bus_cli_conf' -e 'F'");
DAEMON('ZXBUS73b','zxbuslist 2',-1,"./zxbuslist -pid tmp/ZXBUS73b.pid -d -d -c '$bus_list2_conf'");
CMD('ZXBUS74', '10x20 battery', "./zxbustailf -d -d -c '$bus_cli_conf' -e 'foo bar' -i 10 -is 20", 0, 40, 10);
CMD('ZXBUS75', 'len2',     "./zxbustailf -d -d -c '$bus_cli_conf' -e 'F'");
CMD('ZXBUS79', 'dump',     "./zxbustailf -c '$bus_cli_conf' -ctl 'dump'");
KILLD('ZXBUS70b', 'collect zxbuslist 1');
KILLD('ZXBUS73b', 'collect zxbuslist 2');
KILLD('ZXBUS70', 'collect zxbusd 7');

# 80 ten thread nodebug

tst_nl();
DAEMON('ZXBUS80', 'zxbusd 8', 2229, "./zxbusd -pid tmp/ZXBUS80.pid -c '$busd_conf' -nthr 10 -nfd 1000 -npdu 5000 -p stomp:0.0.0.0:2229");
DAEMON('ZXBUS80b','zxbuslist 1',-1,"./zxbuslist -pid tmp/ZXBUS80b.pid -d -d -c '$bus_list_conf'");
CMD('ZXBUS81', 'One shot', "./zxbustailf -c '$bus_cli_conf' -e 'foo bar'");
CMD('ZXBUS82', 'zero len', "./zxbustailf -c '$bus_cli_conf' -e ''");
CMD('ZXBUS82b','zxbuslist 2 one shot',  "./zxbuslist -o 1 -d -d -c '$bus_list2_conf'", 0, 10, 1);
CMD('ZXBUS83', 'len1',     "./zxbustailf -c '$bus_cli_conf' -e 'F'");
DAEMON('ZXBUS83b','zxbuslist 2',-1,"./zxbuslist -pid tmp/ZXBUS83b.pid -d -d -c '$bus_list2_conf'");
CMD('ZXBUS84', '10x20 battery', "./zxbustailf -c '$bus_cli_conf' -e 'foo bar' -i 10 -is 20", 0, 40, 10);
CMD('ZXBUS85', 'len2',     "./zxbustailf -c '$bus_cli_conf' -e 'F'");
CMD('ZXBUS89', 'dump',     "./zxbustailf -c '$bus_cli_conf' -ctl 'dump'");
KILLD('ZXBUS80b', 'collect zxbuslist 1');
KILLD('ZXBUS83b', 'collect zxbuslist 2');
KILLD('ZXBUS80', 'collect zxbusd 8');

### Single client using SSL, various numbers of threads at zxbusd

tst_nl();
CMD('ZXBUSS00', 'Clean', "rm -f /var/zxid/bus/ch/default/*  /var/zxid/bus/ch/default/.del/*  /var/zxid/bus/ch/default/.ack/*");
CMD('ZXBUSS01', 'Fail connect tailf', "./zxbustailf -d -d -c '$buss_cli_conf' -e 'failbar'", 256);
CMD('ZXBUSS02', 'Fail connect list',  "./zxbuslist -d -d -c '$buss_list_conf'", 256);

DAEMON('ZXBUSS10', 'zxbusd 1', 2229, "./zxbusd -pid tmp/ZXBUSS10.pid -c '$bussd_conf' -d -d -nthr 1 -nfd 13 -npdu 500 -p stomps:0.0.0.0:2229");
# *** The current version (20120911) has a bug in that first SSL connection fails.
# *** Thus we send this priming connection to enable all the rest work.
#CMD('ZXBUSS10a','zxbuslist 1 prime-bug', "./zxbuslist -o -1 -d -d -c '$buss_list_conf'", 36096);
DAEMON('ZXBUSS10b', 'zxbuslist 1', -1, "./zxbuslist -pid tmp/ZXBUSS10b.pid -d -d -c '$buss_list_conf'");
CMD('ZXBUSS11', 'One shot', "./zxbustailf -d -d -c '$buss_cli_conf' -e 'foo bar'");
STILL('ZXBUSS10b', 'zxbuslist 1 still there');
CMD('ZXBUSS12', 'zero len', "./zxbustailf -d -d -c '$buss_cli_conf' -e ''");
CMD('ZXBUSS13', 'len1',     "./zxbustailf -d -d -c '$buss_cli_conf' -e 'F'");
CMD('ZXBUSS14', '10x20 battery', "./zxbustailf -d -d -c '$buss_cli_conf' -e 'foo bar' -i 10 -is 20", 0, 60, 10);
CMD('ZXBUSS15', 'len2',     "./zxbustailf -d -d -c '$buss_cli_conf' -e 'F'");
CMD('ZXBUSS19', 'dump',     "./zxbustailf -c '$buss_cli_conf' -ctl 'dump'");
KILLD('ZXBUSS10b', 'collect zxbuslist 1');
KILLD('ZXBUSS10', 'collect zxbusd 1');

# 20 two thread debug

tst_nl();
DAEMON('ZXBUSS20', 'zxbusd 2', 2229, "./zxbusd -pid tmp/ZXBUSS20.pid -c '$bussd_conf' -d -d -nthr 2 -nfd 13 -npdu 900 -p stomps:0.0.0.0:2229");
#CMD('ZXBUSS20a','zxbuslist 1 prime-bug', "./zxbuslist -o -1 -d -d -c '$buss_list_conf'", 36096);
DAEMON('ZXBUSS20b', 'zxbuslist 1', -1, "./zxbuslist -pid tmp/ZXBUSS20b.pid -d -d -c '$buss_list_conf'");
CMD('ZXBUSS21', 'One shot', "./zxbustailf -d -d -c '$buss_cli_conf' -e 'foo bar'");
CMD('ZXBUSS21b','zxbuslist 2 one shot', "./zxbuslist -o 1 -d -d -c '$buss_list2_conf'");
CMD('ZXBUSS22', 'zero len', "./zxbustailf -d -d -c '$buss_cli_conf' -e ''");
CMD('ZXBUSS23', 'len1',     "./zxbustailf -d -d -c '$buss_cli_conf' -e 'F'");
CMD('ZXBUSS24', '10x20 battery', "./zxbustailf -d -d -c '$buss_cli_conf' -e 'foo bar' -i 10 -is 20", 0, 60, 10);
CMD('ZXBUSS25', 'len2',     "./zxbustailf -d -d -c '$buss_cli_conf' -e 'F'");
CMD('ZXBUSS29', 'dump',     "./zxbustailf -c '$buss_cli_conf' -ctl 'dump'");
KILLD('ZXBUSS20b', 'collect zxbuslist 1');
KILLD('ZXBUSS20', 'collect zxbusd 2');

# 30 single thread nodebug, two listener clients

tst_nl();
DAEMON('ZXBUSS30', 'zxbusd 3', 2229, "./zxbusd -pid tmp/ZXBUSS30.pid -c '$bussd_conf' -nthr 1 -nfd 1000 -npdu 5000 -p stomps:0.0.0.0:2229");
#CMD('ZXBUSS30a','zxbuslist 1 prime-bug', "./zxbuslist -o -1 -d -d -c '$buss_list_conf'", 36096);
DAEMON('ZXBUSS30b','zxbuslist 1',-1,"./zxbuslist -pid tmp/ZXBUSS30b.pid -c '$buss_list_conf'");
CMD('ZXBUSS31', 'One shot', "./zxbustailf -c '$buss_cli_conf' -e 'foo bar'");
DAEMON('ZXBUSS31b','zxbuslist 2',-1,"./zxbuslist -pid tmp/ZXBUSS31b.pid -c '$buss_list2_conf'");
CMD('ZXBUSS32', 'zero len', "./zxbustailf -c '$buss_cli_conf' -e ''");
CMD('ZXBUSS33', 'len1',     "./zxbustailf -c '$buss_cli_conf' -e 'F'");
CMD('ZXBUSS34', '10x20 battery', "./zxbustailf -c '$buss_cli_conf' -e 'foo bar' -i 10 -is 20", 0, 60, 10);
CMD('ZXBUSS35', 'len2',     "./zxbustailf -c '$buss_cli_conf' -e 'F'");
CMD('ZXBUSS39', 'dump',     "./zxbustailf -c '$buss_cli_conf' -ctl 'dump'");
KILLD('ZXBUSS30b', 'collect zxbuslist 1');
KILLD('ZXBUSS31b', 'collect zxbuslist 2');
KILLD('ZXBUSS30', 'collect zxbusd 3');

# 40 two thread nodebug, two listeners

tst_nl();
DAEMON('ZXBUSS40', 'zxbusd 4', 2229, "./zxbusd -pid tmp/ZXBUSS40.pid -c '$bussd_conf' -nthr 2 -nfd 1000 -npdu 5000 -p stomps:0.0.0.0:2229");
#CMD('ZXBUSS40a','zxbuslist 1 prime-bug', "./zxbuslist -o -1 -d -d -c '$buss_list_conf'", 36096);
DAEMON('ZXBUSS40b','zxbuslist 1',-1,"./zxbuslist -pid tmp/ZXBUSS40b.pid -c '$buss_list_conf'");
CMD('ZXBUSS41', 'One shot', "./zxbustailf -c '$buss_cli_conf' -e 'foo bar'");
sleep(1);
CMD('ZXBUSS41b','zxbuslist 2 one shot', "./zxbuslist -o 1 -d -d -c '$buss_list2_conf'", 0, 10, 1);
CMD('ZXBUSS42', 'zero len', "./zxbustailf -c '$buss_cli_conf' -e ''");
DAEMON('ZXBUSS42b','zxbuslist 2',-1,"./zxbuslist -pid tmp/ZXBUSS42b.pid -c '$buss_list2_conf'");
CMD('ZXBUSS43', 'len1',     "./zxbustailf -c '$buss_cli_conf' -e 'F'");
CMD('ZXBUSS44', '10x20 battery', "./zxbustailf -c '$buss_cli_conf' -e 'foo bar' -i 10 -is 20", 0, 60, 10);
CMD('ZXBUSS45', 'len2',     "./zxbustailf -c '$buss_cli_conf' -e 'F'");
CMD('ZXBUSS49', 'dump',     "./zxbustailf -c '$buss_cli_conf' -ctl 'dump'");
KILLD('ZXBUSS40b', 'collect zxbuslist 1');
KILLD('ZXBUSS42b', 'collect zxbuslist 2');
KILLD('ZXBUSS40', 'collect zxbusd 4');

# *** add tests with some listeners offline and coming back online later

# 50 three thread debug

tst_nl();
DAEMON('ZXBUSS50', 'zxbusd 5', 2229, "./zxbusd -pid tmp/ZXBUSS50.pid -c '$bussd_conf' -d -d -nthr 3 -nfd 1000 -npdu 5000 -p stomps:0.0.0.0:2229");
#CMD('ZXBUSS50a','zxbuslist 1 prime-bug', "./zxbuslist -o -1 -d -d -c '$buss_list_conf'", 36096);
DAEMON('ZXBUSS50b','zxbuslist 1',-1,"./zxbuslist -pid tmp/ZXBUSS50b.pid -d -d -c '$buss_list_conf'");
CMD('ZXBUSS51', 'One shot', "./zxbustailf -d -d -c '$buss_cli_conf' -e 'foo bar'");
CMD('ZXBUSS52', 'zero len', "./zxbustailf -d -d -c '$buss_cli_conf' -e ''");
CMD('ZXBUSS52b','zxbuslist 2 one shot',  "./zxbuslist -o 1 -d -d -c '$buss_list2_conf'", 0, 10, 1);
CMD('ZXBUSS52c','zxbuslist 2 one shot2', "./zxbuslist -o -1 -d -d -c '$buss_list2_conf'", 0, 10, 1);
CMD('ZXBUSS53', 'len1',     "./zxbustailf -d -d -c '$buss_cli_conf' -e 'F'");
DAEMON('ZXBUSS53b','zxbuslist 2',-1,"./zxbuslist -pid tmp/ZXBUSS53b.pid -d -d -c '$buss_list2_conf'");
CMD('ZXBUSS54', '10x20 battery', "./zxbustailf -d -d -c '$buss_cli_conf' -e 'foo bar' -i 10 -is 20", 0, 60, 10);
CMD('ZXBUSS55', 'len2',     "./zxbustailf -d -d -c '$buss_cli_conf' -e 'F'");
CMD('ZXBUSS59', 'dump',     "./zxbustailf -c '$buss_cli_conf' -ctl 'dump'");
KILLD('ZXBUSS50b', 'collect zxbuslist 1');
KILLD('ZXBUSS53b', 'collect zxbuslist 2');
KILLD('ZXBUSS50', 'collect zxbusd 5');

# 60 three thread nodebug

tst_nl();
DAEMON('ZXBUSS60', 'zxbusd 6', 2229, "./zxbusd -pid tmp/ZXBUSS60.pid -c '$bussd_conf' -nthr 3 -nfd 1000 -npdu 5000 -p stomps:0.0.0.0:2229");
#CMD('ZXBUSS60a','zxbuslist 1 prime-bug', "./zxbuslist -o -1 -d -d -c '$buss_list_conf'", 36096);
DAEMON('ZXBUSS60b','zxbuslist 1',-1,"./zxbuslist -pid tmp/ZXBUSS60b.pid -d -d -c '$buss_list_conf'");
CMD('ZXBUSS61', 'One shot', "./zxbustailf -c '$buss_cli_conf' -e 'foo bar'");
CMD('ZXBUSS62', 'zero len', "./zxbustailf -c '$buss_cli_conf' -e ''");
CMD('ZXBUSS62b','zxbuslist 2 one shot',  "./zxbuslist -o 1 -d -d -c '$buss_list2_conf'", 0, 10, 1);
CMD('ZXBUSS63', 'len1',     "./zxbustailf -c '$buss_cli_conf' -e 'F'");
DAEMON('ZXBUSS63b','zxbuslist 2',-1,"./zxbuslist -pid tmp/ZXBUSS63b.pid -d -d -c '$buss_list2_conf'");
CMD('ZXBUSS64', '10x20 battery', "./zxbustailf -c '$buss_cli_conf' -e 'foo bar' -i 10 -is 20", 0, 60, 10);
CMD('ZXBUSS65', 'len2',     "./zxbustailf -c '$buss_cli_conf' -e 'F'");
CMD('ZXBUSS69', 'dump',     "./zxbustailf -c '$buss_cli_conf' -ctl 'dump'");
KILLD('ZXBUSS60b', 'collect zxbuslist 1');
KILLD('ZXBUSS63b', 'collect zxbuslist 2');
KILLD('ZXBUSS60', 'collect zxbusd 6');

# 70 ten thread debug

tst_nl();
DAEMON('ZXBUSS70', 'zxbusd 7', 2229, "./zxbusd -pid tmp/ZXBUSS70.pid -c '$bussd_conf' -d -d -nthr 10 -nfd 1000 -npdu 5000 -p stomps:0.0.0.0:2229");
#CMD('ZXBUSS70a','zxbuslist 1 prime-bug', "./zxbuslist -o -1 -d -d -c '$buss_list_conf'", 36096);
DAEMON('ZXBUSS70b','zxbuslist 1',-1,"./zxbuslist -pid tmp/ZXBUSS70b.pid -d -d -c '$buss_list_conf'");
CMD('ZXBUSS71', 'One shot', "./zxbustailf -d -d -c '$buss_cli_conf' -e 'foo bar'");
CMD('ZXBUSS72', 'zero len', "./zxbustailf -d -d -c '$buss_cli_conf' -e ''");
CMD('ZXBUSS72b','zxbuslist 2 one shot',  "./zxbuslist -o 1 -d -d -c '$buss_list2_conf'", 0, 10, 1);
CMD('ZXBUSS73', 'len1',     "./zxbustailf -d -d -c '$buss_cli_conf' -e 'F'");
DAEMON('ZXBUSS73b','zxbuslist 2',-1,"./zxbuslist -pid tmp/ZXBUSS73b.pid -d -d -c '$buss_list2_conf'");
CMD('ZXBUSS74', '10x20 battery', "./zxbustailf -d -d -c '$buss_cli_conf' -e 'foo bar' -i 10 -is 20", 0, 60, 10);
CMD('ZXBUSS75', 'len2',     "./zxbustailf -d -d -c '$buss_cli_conf' -e 'F'");
CMD('ZXBUSS79', 'dump',     "./zxbustailf -c '$buss_cli_conf' -ctl 'dump'");
KILLD('ZXBUSS70b', 'collect zxbuslist 1');
KILLD('ZXBUSS73b', 'collect zxbuslist 2');
KILLD('ZXBUSS70', 'collect zxbusd 7');

# 80 ten thread nodebug

tst_nl();
DAEMON('ZXBUSS80', 'zxbusd 8', 2229, "./zxbusd -pid tmp/ZXBUSS80.pid -c '$bussd_conf' -nthr 10 -nfd 1000 -npdu 5000 -p stomps:0.0.0.0:2229");
#CMD('ZXBUSS80a','zxbuslist 1 prime-bug', "./zxbuslist -o -1 -d -d -c '$buss_list_conf'", 36096);
DAEMON('ZXBUSS80b','zxbuslist 1',-1,"./zxbuslist -pid tmp/ZXBUSS80b.pid -d -d -c '$buss_list_conf'");
CMD('ZXBUSS81', 'One shot', "./zxbustailf -c '$buss_cli_conf' -e 'foo bar'");
CMD('ZXBUSS82', 'zero len', "./zxbustailf -c '$buss_cli_conf' -e ''");
CMD('ZXBUSS82b','zxbuslist 2 one shot',  "./zxbuslist -o 1 -d -d -c '$buss_list2_conf'", 0, 10, 1);
CMD('ZXBUSS83', 'len1',     "./zxbustailf -c '$buss_cli_conf' -e 'F'");
DAEMON('ZXBUSS83b','zxbuslist 2',-1,"./zxbuslist -pid tmp/ZXBUSS83b.pid -d -d -c '$buss_list2_conf'");
CMD('ZXBUSS84', '10x20 battery', "./zxbustailf -c '$buss_cli_conf' -e 'foo bar' -i 10 -is 20", 0, 60, 10);
CMD('ZXBUSS85', 'len2',     "./zxbustailf -c '$buss_cli_conf' -e 'F'");
CMD('ZXBUSS89', 'dump',     "./zxbustailf -c '$buss_cli_conf' -ctl 'dump'");
KILLD('ZXBUSS80b', 'collect zxbuslist 1');
KILLD('ZXBUSS83b', 'collect zxbuslist 2');
KILLD('ZXBUSS80', 'collect zxbusd 8');

### Dual threaded client, various numbers of threads at zxbusd

tst_nl();
CMD('ZXBUSD00', 'Clean', "rm -f /var/zxid/bus/ch/default/*  /var/zxid/bus/ch/default/.del/*  /var/zxid/bus/ch/default/.ack/*");

tst_nl();
DAEMON('ZXBUSD10', 'zxbusd 1', 2229, "./zxbusd -pid tmp/ZXBUSD10.pid -c '$busd_conf' -d -d -nthr 1 -nfd 30 -npdu 1000 -p stomp:0.0.0.0:2229");
DAEMON('ZXBUSD10b','zxbuslist 1',-1,"./zxbuslist -pid tmp/ZXBUSD10b.pid -d -d -c '$bus_list_conf'");
DAEMON('ZXBUSD10c','zxbuslist 2',-1,"./zxbuslist -pid tmp/ZXBUSD10c.pid -d -d -c '$bus_list2_conf'");
CMD('ZXBUSD12', 'zxbuslist 2 fail one shot',  "./zxbuslist -o 1 -d -d -c '$buss_list2_conf'", 256, 10, 1);
CMD('ZXBUSD14', '2x10x20 battery', "./zxbustailf -d -d -c '$bus_cli_conf' -e 'foo bar' -it 2 -i 10 -is 20", 0, 90, 10);
CMD('ZXBUSD19', 'dump',     "./zxbustailf -c '$bus_cli_conf' -ctl 'dump'");
KILLD('ZXBUSD10b', 'collect zxbuslist 1');
KILLD('ZXBUSD10c', 'collect zxbuslist 2');
KILLD('ZXBUSD10',  'collect zxbusd 1');

tst_nl();
DAEMON('ZXBUSD20', 'zxbusd 2', 2229, "./zxbusd -pid tmp/ZXBUSD20.pid -c '$busd_conf' -d -d -nthr 2 -nfd 30 -npdu 1000 -p stomp:0.0.0.0:2229");
DAEMON('ZXBUSD20b','zxbuslist 1',-1,"./zxbuslist -pid tmp/ZXBUSD20b.pid -d -d -c '$bus_list_conf'");
DAEMON('ZXBUSD20c','zxbuslist 2',-1,"./zxbuslist -pid tmp/ZXBUSD20c.pid -d -d -c '$bus_list2_conf'");
CMD('ZXBUSD24', '2x10x20 battery', "./zxbustailf -d -d -c '$bus_cli_conf' -e 'foo bar' -it 2 -i 10 -is 20", 0, 180, 10);
CMD('ZXBUSD29', 'dump',     "./zxbustailf -c '$bus_cli_conf' -ctl 'dump'");
KILLD('ZXBUSD20b', 'collect zxbuslist 1');
KILLD('ZXBUSD20c', 'collect zxbuslist 2');
KILLD('ZXBUSD20', 'collect zxbusd 2');

tst_nl();
DAEMON('ZXBUSD30', 'zxbusd 3', 2229, "./zxbusd -pid tmp/ZXBUSD30.pid -c '$busd_conf' -nthr 1 -nfd 30 -npdu 1000 -p stomp:0.0.0.0:2229");
DAEMON('ZXBUSD30b','zxbuslist 1',-1,"./zxbuslist -pid tmp/ZXBUSD30b.pid -d -d -c '$bus_list_conf'");
DAEMON('ZXBUSD30c','zxbuslist 2',-1,"./zxbuslist -pid tmp/ZXBUSD30c.pid -d -d -c '$bus_list2_conf'");
CMD('ZXBUSD34', '2x10x20 battery', "./zxbustailf -c '$bus_cli_conf' -e 'foo bar' -it 2 -i 10 -is 20", 0, 120, 10);
CMD('ZXBUSD39', 'dump',     "./zxbustailf -c '$bus_cli_conf' -ctl 'dump'");
KILLD('ZXBUSD30b', 'collect zxbuslist 1');
KILLD('ZXBUSD30c', 'collect zxbuslist 2');
KILLD('ZXBUSD30', 'collect zxbusd 3');

tst_nl();
DAEMON('ZXBUSD40', 'zxbusd 4', 2229, "./zxbusd -pid tmp/ZXBUSD40.pid -c '$busd_conf' -nthr 2 -nfd 30 -npdu 1000 -p stomp:0.0.0.0:2229");
DAEMON('ZXBUSD40b','zxbuslist 1',-1,"./zxbuslist -pid tmp/ZXBUSD40b.pid -d -d -c '$bus_list_conf'");
DAEMON('ZXBUSD40c','zxbuslist 2',-1,"./zxbuslist -pid tmp/ZXBUSD40c.pid -d -d -c '$bus_list2_conf'");
CMD('ZXBUSD44', '2x10x20 battery', "./zxbustailf -c '$bus_cli_conf' -e 'foo bar' -it 2 -i 10 -is 20", 0, 120, 10);
CMD('ZXBUSD49', 'dump',     "./zxbustailf -c '$bus_cli_conf' -ctl 'dump'");
KILLD('ZXBUSD40b', 'collect zxbuslist 1');
KILLD('ZXBUSD40c', 'collect zxbuslist 2');
KILLD('ZXBUSD40', 'collect zxbusd 4');

tst_nl();
DAEMON('ZXBUSD50', 'zxbusd 5', 2229, "./zxbusd -pid tmp/ZXBUSD50.pid -c '$busd_conf' -d -d -nthr 3 -nfd 30 -npdu 1000 -p stomp:0.0.0.0:2229");
DAEMON('ZXBUSD50b','zxbuslist 1',-1,"./zxbuslist -pid tmp/ZXBUSD50b.pid -d -d -c '$bus_list_conf'");
DAEMON('ZXBUSD50c','zxbuslist 2',-1,"./zxbuslist -pid tmp/ZXBUSD50c.pid -d -d -c '$bus_list2_conf'");
CMD('ZXBUSD54', '2x10x20 battery', "./zxbustailf -d -d -c '$bus_cli_conf' -e 'foo bar' -it 2 -i 10 -is 20", 0, 120, 10);
CMD('ZXBUSD59', 'dump',     "./zxbustailf -c '$bus_cli_conf' -ctl 'dump'");
KILLD('ZXBUSD50b', 'collect zxbuslist 1');
KILLD('ZXBUSD50c', 'collect zxbuslist 2');
KILLD('ZXBUSD50', 'collect zxbusd 5');

tst_nl();
DAEMON('ZXBUSD60', 'zxbusd 6', 2229, "./zxbusd -pid tmp/ZXBUSD60.pid -c '$busd_conf' -nthr 3 -nfd 30 -npdu 1000 -p stomp:0.0.0.0:2229");
DAEMON('ZXBUSD60b','zxbuslist 1',-1,"./zxbuslist -pid tmp/ZXBUSD60b.pid -d -d -c '$bus_list_conf'");
DAEMON('ZXBUSD60c','zxbuslist 2',-1,"./zxbuslist -pid tmp/ZXBUSD60c.pid -d -d -c '$bus_list2_conf'");
CMD('ZXBUSD64', '2x10x20 battery', "./zxbustailf -c '$bus_cli_conf' -e 'foo bar' -it 2 -i 10 -is 20", 0, 120, 10);
CMD('ZXBUSD69', 'dump',     "./zxbustailf -c '$bus_cli_conf' -ctl 'dump'");
KILLD('ZXBUSD60b', 'collect zxbuslist 1');
KILLD('ZXBUSD60c', 'collect zxbuslist 2');
KILLD('ZXBUSD60', 'collect zxbusd 6');

tst_nl();
DAEMON('ZXBUSD70', 'zxbusd 7', 2229, "./zxbusd -pid tmp/ZXBUSD70.pid -c '$busd_conf' -d -d -nthr 10 -nfd 30 -npdu 1000 -p stomp:0.0.0.0:2229");
DAEMON('ZXBUSD70b','zxbuslist 1',-1,"./zxbuslist -pid tmp/ZXBUSD70b.pid -d -d -c '$bus_list_conf'");
DAEMON('ZXBUSD70c','zxbuslist 2',-1,"./zxbuslist -pid tmp/ZXBUSD70c.pid -d -d -c '$bus_list2_conf'");
CMD('ZXBUSD74', '2x10x20 battery', "./zxbustailf -d -d -c '$bus_cli_conf' -e 'foo bar' -it 2 -i 10 -is 20", 0, 120, 10);
CMD('ZXBUSD79', 'dump',     "./zxbustailf -c '$bus_cli_conf' -ctl 'dump'");
KILLD('ZXBUSD70b', 'collect zxbuslist 1');
KILLD('ZXBUSD70c', 'collect zxbuslist 2');
KILLD('ZXBUSD70', 'collect zxbusd 7');

tst_nl();
DAEMON('ZXBUSD80', 'zxbusd 8', 2229, "./zxbusd -pid tmp/ZXBUSD80.pid -c '$busd_conf' -nthr 10 -nfd 30 -npdu 1000 -p stomp:0.0.0.0:2229");
DAEMON('ZXBUSD80b','zxbuslist 1',-1,"./zxbuslist -pid tmp/ZXBUSD80b.pid -d -d -c '$bus_list_conf'");
DAEMON('ZXBUSD80c','zxbuslist 2',-1,"./zxbuslist -pid tmp/ZXBUSD80c.pid -d -d -c '$bus_list2_conf'");
CMD('ZXBUSD84', '2x10x20 battery', "./zxbustailf -c '$bus_cli_conf' -e 'foo bar' -it 2 -i 10 -is 20", 0, 120, 10);
CMD('ZXBUSD89', 'dump',     "./zxbustailf -c '$bus_cli_conf' -ctl 'dump'");
KILLD('ZXBUSD80b', 'collect zxbuslist 1');
KILLD('ZXBUSD80c', 'collect zxbuslist 2');
KILLD('ZXBUSD80', 'collect zxbusd 8');

### Triple threaded client, various numbers of threads at zxbusd

tst_nl();
CMD('ZXBUST00', 'Clean', "rm -f /var/zxid/bus/ch/default/*  /var/zxid/bus/ch/default/.del/*  /var/zxid/bus/ch/default/.ack/*");

tst_nl();
DAEMON('ZXBUST10', 'zxbusd 1', 2229, "./zxbusd -pid tmp/ZXBUST10.pid -c '$busd_conf' -d -d -nthr 1 -nfd 30 -npdu 1500 -p stomp:0.0.0.0:2229");
DAEMON('ZXBUST10b','zxbuslist 1',-1,"./zxbuslist -pid tmp/ZXBUST10b.pid -d -d -c '$bus_list_conf'");
DAEMON('ZXBUST10c','zxbuslist 2',-1,"./zxbuslist -pid tmp/ZXBUST10c.pid -d -d -c '$bus_list2_conf'");
CMD('ZXBUST12', 'zxbuslist 2 fail one shot',  "./zxbuslist -o 1 -d -d -c '$buss_list2_conf'", 256, 10, 1);
CMD('ZXBUST14', '3x10x20 battery', "./zxbustailf -d -d -c '$bus_cli_conf' -e 'foo bar' -it 3 -i 10 -is 20", 0, 240, 10);
CMD('ZXBUST19', 'dump',     "./zxbustailf -c '$bus_cli_conf' -ctl 'dump'");
KILLD('ZXBUST10b', 'collect zxbuslist 1');
KILLD('ZXBUST10c', 'collect zxbuslist 2');
KILLD('ZXBUST10',  'collect zxbusd 1');

tst_nl();
DAEMON('ZXBUST20', 'zxbusd 2', 2229, "./zxbusd -pid tmp/ZXBUST20.pid -c '$busd_conf' -d -d -nthr 2 -nfd 30 -npdu 1500 -p stomp:0.0.0.0:2229");
DAEMON('ZXBUST20b','zxbuslist 1',-1,"./zxbuslist -pid tmp/ZXBUST20b.pid -d -d -c '$bus_list_conf'");
DAEMON('ZXBUST20c','zxbuslist 2',-1,"./zxbuslist -pid tmp/ZXBUST20c.pid -d -d -c '$bus_list2_conf'");
CMD('ZXBUST24', '3x10x20 battery', "./zxbustailf -d -d -c '$bus_cli_conf' -e 'foo bar' -it 3 -i 10 -is 20", 0, 240, 10);
CMD('ZXBUST29', 'dump',     "./zxbustailf -c '$bus_cli_conf' -ctl 'dump'");
KILLD('ZXBUST20b', 'collect zxbuslist 1');
KILLD('ZXBUST20c', 'collect zxbuslist 2');
KILLD('ZXBUST20', 'collect zxbusd 2');

tst_nl();
DAEMON('ZXBUST30', 'zxbusd 3', 2229, "./zxbusd -pid tmp/ZXBUST30.pid -c '$busd_conf' -nthr 1 -nfd 30 -npdu 1500 -p stomp:0.0.0.0:2229");
DAEMON('ZXBUST30b','zxbuslist 1',-1,"./zxbuslist -pid tmp/ZXBUST30b.pid -d -d -c '$bus_list_conf'");
DAEMON('ZXBUST30c','zxbuslist 2',-1,"./zxbuslist -pid tmp/ZXBUST30c.pid -d -d -c '$bus_list2_conf'");
CMD('ZXBUST34', '3x10x20 battery', "./zxbustailf -c '$bus_cli_conf' -e 'foo bar' -it 3 -i 10 -is 20", 0, 240, 10);
CMD('ZXBUST39', 'dump',     "./zxbustailf -c '$bus_cli_conf' -ctl 'dump'");
KILLD('ZXBUST30b', 'collect zxbuslist 1');
KILLD('ZXBUST30c', 'collect zxbuslist 2');
KILLD('ZXBUST30', 'collect zxbusd 3');

tst_nl();
DAEMON('ZXBUST40', 'zxbusd 4', 2229, "./zxbusd -pid tmp/ZXBUST40.pid -c '$busd_conf' -nthr 2 -nfd 30 -npdu 1500 -p stomp:0.0.0.0:2229");
DAEMON('ZXBUST40b','zxbuslist 1',-1,"./zxbuslist -pid tmp/ZXBUST40b.pid -d -d -c '$bus_list_conf'");
DAEMON('ZXBUST40c','zxbuslist 2',-1,"./zxbuslist -pid tmp/ZXBUST40c.pid -d -d -c '$bus_list2_conf'");
CMD('ZXBUST44', '3x10x20 battery', "./zxbustailf -c '$bus_cli_conf' -e 'foo bar' -it 3 -i 10 -is 20", 0, 240, 10);
CMD('ZXBUST49', 'dump',     "./zxbustailf -c '$bus_cli_conf' -ctl 'dump'");
KILLD('ZXBUST40b', 'collect zxbuslist 1');
KILLD('ZXBUST40c', 'collect zxbuslist 2');
KILLD('ZXBUST40', 'collect zxbusd 4');

tst_nl();
DAEMON('ZXBUST50', 'zxbusd 5', 2229, "./zxbusd -pid tmp/ZXBUST50.pid -c '$busd_conf' -d -d -nthr 3 -nfd 30 -npdu 1500 -p stomp:0.0.0.0:2229");
DAEMON('ZXBUST50b','zxbuslist 1',-1,"./zxbuslist -pid tmp/ZXBUST50b.pid -d -d -c '$bus_list_conf'");
DAEMON('ZXBUST50c','zxbuslist 2',-1,"./zxbuslist -pid tmp/ZXBUST50c.pid -d -d -c '$bus_list2_conf'");
CMD('ZXBUST54', '3x10x20 battery', "./zxbustailf -d -d -c '$bus_cli_conf' -e 'foo bar' -it 3 -i 10 -is 20", 0, 240, 10);
CMD('ZXBUST59', 'dump',     "./zxbustailf -c '$bus_cli_conf' -ctl 'dump'");
KILLD('ZXBUST50b', 'collect zxbuslist 1');
KILLD('ZXBUST50c', 'collect zxbuslist 2');
KILLD('ZXBUST50', 'collect zxbusd 5');

tst_nl();
DAEMON('ZXBUST60', 'zxbusd 6', 2229, "./zxbusd -pid tmp/ZXBUST60.pid -c '$busd_conf' -nthr 3 -nfd 30 -npdu 1500 -p stomp:0.0.0.0:2229");
DAEMON('ZXBUST60b','zxbuslist 1',-1,"./zxbuslist -pid tmp/ZXBUST60b.pid -d -d -c '$bus_list_conf'");
DAEMON('ZXBUST60c','zxbuslist 2',-1,"./zxbuslist -pid tmp/ZXBUST60c.pid -d -d -c '$bus_list2_conf'");
CMD('ZXBUST64', '3x10x20 battery', "./zxbustailf -c '$bus_cli_conf' -e 'foo bar' -it 3 -i 10 -is 20", 0, 240, 10);
CMD('ZXBUST69', 'dump',     "./zxbustailf -c '$bus_cli_conf' -ctl 'dump'");
KILLD('ZXBUST60b', 'collect zxbuslist 1');
KILLD('ZXBUST60c', 'collect zxbuslist 2');
KILLD('ZXBUST60', 'collect zxbusd 6');

tst_nl();
DAEMON('ZXBUST70', 'zxbusd 7', 2229, "./zxbusd -pid tmp/ZXBUST70.pid -c '$busd_conf' -d -d -nthr 10 -nfd 30 -npdu 1500 -p stomp:0.0.0.0:2229");
DAEMON('ZXBUST70b','zxbuslist 1',-1,"./zxbuslist -pid tmp/ZXBUST70b.pid -d -d -c '$bus_list_conf'");
DAEMON('ZXBUST70c','zxbuslist 2',-1,"./zxbuslist -pid tmp/ZXBUST70c.pid -d -d -c '$bus_list2_conf'");
CMD('ZXBUST74', '3x10x20 battery', "./zxbustailf -d -d -c '$bus_cli_conf' -e 'foo bar' -it 3 -i 10 -is 20", 0, 240, 10);
CMD('ZXBUST79', 'dump',     "./zxbustailf -c '$bus_cli_conf' -ctl 'dump'");
KILLD('ZXBUST70b', 'collect zxbuslist 1');
KILLD('ZXBUST70c', 'collect zxbuslist 2');
KILLD('ZXBUST70', 'collect zxbusd 7');

tst_nl();
DAEMON('ZXBUST80', 'zxbusd 8', 2229, "./zxbusd -pid tmp/ZXBUST80.pid -c '$busd_conf' -nthr 10 -nfd 30 -npdu 1500 -p stomp:0.0.0.0:2229");
DAEMON('ZXBUST80b','zxbuslist 1',-1,"./zxbuslist -pid tmp/ZXBUST80b.pid -d -d -c '$bus_list_conf'");
DAEMON('ZXBUST80c','zxbuslist 2',-1,"./zxbuslist -pid tmp/ZXBUST80c.pid -d -d -c '$bus_list2_conf'");
CMD('ZXBUST84', '3x10x20 battery', "./zxbustailf -c '$bus_cli_conf' -e 'foo bar' -it 3 -i 10 -is 20", 0, 240, 10);
CMD('ZXBUST89', 'dump',     "./zxbustailf -c '$bus_cli_conf' -ctl 'dump'");
KILLD('ZXBUST80b', 'collect zxbuslist 1');
KILLD('ZXBUST80c', 'collect zxbuslist 2');
KILLD('ZXBUST80', 'collect zxbusd 8');

### Multi threaded (10) client, various numbers of threads at zxbusd

tst_nl();
CMD('ZXBUSM00', 'Clean', "rm -f /var/zxid/bus/ch/default/*  /var/zxid/bus/ch/default/.del/*  /var/zxid/bus/ch/default/.ack/*");

tst_nl();
DAEMON('ZXBUSM10', 'zxbusd 1', 2229, "./zxbusd -pid tmp/ZXBUSM10.pid -c '$busd_conf' -d -d -nthr 1 -nfd 50 -npdu 5000 -p stomp:0.0.0.0:2229");
DAEMON('ZXBUSM10b','zxbuslist 1',-1,"./zxbuslist -pid tmp/ZXBUSM10b.pid -d -d -c '$bus_list_conf'");
DAEMON('ZXBUSM10c','zxbuslist 2',-1,"./zxbuslist -pid tmp/ZXBUSM10c.pid -d -d -c '$bus_list2_conf'");
CMD('ZXBUSM12', 'zxbuslist 2 fail one shot',  "./zxbuslist -o 1 -d -d -c '$buss_list2_conf'", 256, 10, 1);
CMD('ZXBUSM14', '10x10x20 battery', "./zxbustailf -d -d -c '$bus_cli_conf' -e 'foo bar' -it 10 -i 10 -is 20", 0, 3600, 10);
CMD('ZXBUSM19', 'dump',     "./zxbustailf -c '$bus_cli_conf' -ctl 'dump'");
KILLD('ZXBUSM10b', 'collect zxbuslist 1');
KILLD('ZXBUSM10c', 'collect zxbuslist 2');
KILLD('ZXBUSM10',  'collect zxbusd 1');

tst_nl();
DAEMON('ZXBUSM20', 'zxbusd 2', 2229, "./zxbusd -pid tmp/ZXBUSM20.pid -c '$busd_conf' -d -d -nthr 2 -nfd 50 -npdu 5000 -p stomp:0.0.0.0:2229");
DAEMON('ZXBUSM20b','zxbuslist 1',-1,"./zxbuslist -pid tmp/ZXBUSM20b.pid -d -d -c '$bus_list_conf'");
DAEMON('ZXBUSM20c','zxbuslist 2',-1,"./zxbuslist -pid tmp/ZXBUSM20c.pid -d -d -c '$bus_list2_conf'");
CMD('ZXBUSM24', '10x10x20 battery', "./zxbustailf -d -d -c '$bus_cli_conf' -e 'foo bar' -it 10 -i 10 -is 20", 0, 3600, 10);
CMD('ZXBUSM29', 'dump',     "./zxbustailf -c '$bus_cli_conf' -ctl 'dump'");
KILLD('ZXBUSM20b', 'collect zxbuslist 1');
KILLD('ZXBUSM20c', 'collect zxbuslist 2');
KILLD('ZXBUSM20', 'collect zxbusd 2');

tst_nl();
DAEMON('ZXBUSM30', 'zxbusd 3', 2229, "./zxbusd -pid tmp/ZXBUSM30.pid -c '$busd_conf' -nthr 1 -nfd 50 -npdu 5000 -p stomp:0.0.0.0:2229");
DAEMON('ZXBUSM30b','zxbuslist 1',-1,"./zxbuslist -pid tmp/ZXBUSM30b.pid -d -d -c '$bus_list_conf'");
DAEMON('ZXBUSM30c','zxbuslist 2',-1,"./zxbuslist -pid tmp/ZXBUSM30c.pid -d -d -c '$bus_list2_conf'");
CMD('ZXBUSM34', '10x10x20 battery', "./zxbustailf -c '$bus_cli_conf' -e 'foo bar' -it 10 -i 10 -is 20", 0, 3600, 10);
CMD('ZXBUSM39', 'dump',     "./zxbustailf -c '$bus_cli_conf' -ctl 'dump'");
KILLD('ZXBUSM30b', 'collect zxbuslist 1');
KILLD('ZXBUSM30c', 'collect zxbuslist 2');
KILLD('ZXBUSM30', 'collect zxbusd 3');

tst_nl();
DAEMON('ZXBUSM40', 'zxbusd 4', 2229, "./zxbusd -pid tmp/ZXBUSM40.pid -c '$busd_conf' -nthr 2 -nfd 50 -npdu 5000 -p stomp:0.0.0.0:2229");
DAEMON('ZXBUSM40b','zxbuslist 1',-1,"./zxbuslist -pid tmp/ZXBUSM40b.pid -d -d -c '$bus_list_conf'");
DAEMON('ZXBUSM40c','zxbuslist 2',-1,"./zxbuslist -pid tmp/ZXBUSM40c.pid -d -d -c '$bus_list2_conf'");
CMD('ZXBUSM44', '10x10x20 battery', "./zxbustailf -c '$bus_cli_conf' -e 'foo bar' -it 10 -i 10 -is 20", 0, 3600, 10);
CMD('ZXBUSM49', 'dump',     "./zxbustailf -c '$bus_cli_conf' -ctl 'dump'");
KILLD('ZXBUSM40b', 'collect zxbuslist 1');
KILLD('ZXBUSM40c', 'collect zxbuslist 2');
KILLD('ZXBUSM40', 'collect zxbusd 4');

tst_nl();
DAEMON('ZXBUSM50', 'zxbusd 5', 2229, "./zxbusd -pid tmp/ZXBUSM50.pid -c '$busd_conf' -d -d -nthr 3 -nfd 50 -npdu 5000 -p stomp:0.0.0.0:2229");
DAEMON('ZXBUSM50b','zxbuslist 1',-1,"./zxbuslist -pid tmp/ZXBUSM50b.pid -d -d -c '$bus_list_conf'");
DAEMON('ZXBUSM50c','zxbuslist 2',-1,"./zxbuslist -pid tmp/ZXBUSM50c.pid -d -d -c '$bus_list2_conf'");
CMD('ZXBUSM54', '10x10x20 battery', "./zxbustailf -d -d -c '$bus_cli_conf' -e 'foo bar' -it 10 -i 10 -is 20", 0, 3600, 10);
CMD('ZXBUSM59', 'dump',     "./zxbustailf -c '$bus_cli_conf' -ctl 'dump'");
KILLD('ZXBUSM50b', 'collect zxbuslist 1');
KILLD('ZXBUSM50c', 'collect zxbuslist 2');
KILLD('ZXBUSM50', 'collect zxbusd 5');

tst_nl();
DAEMON('ZXBUSM60', 'zxbusd 6', 2229, "./zxbusd -pid tmp/ZXBUSM60.pid -c '$busd_conf' -nthr 3 -nfd 50 -npdu 5000 -p stomp:0.0.0.0:2229");
DAEMON('ZXBUSM60b','zxbuslist 1',-1,"./zxbuslist -pid tmp/ZXBUSM60b.pid -d -d -c '$bus_list_conf'");
DAEMON('ZXBUSM60c','zxbuslist 2',-1,"./zxbuslist -pid tmp/ZXBUSM60c.pid -d -d -c '$bus_list2_conf'");
CMD('ZXBUSM64', '10x10x20 battery', "./zxbustailf -c '$bus_cli_conf' -e 'foo bar' -it 10 -i 10 -is 20", 0, 3600, 10);
CMD('ZXBUSM69', 'dump',     "./zxbustailf -c '$bus_cli_conf' -ctl 'dump'");
KILLD('ZXBUSM60b', 'collect zxbuslist 1');
KILLD('ZXBUSM60c', 'collect zxbuslist 2');
KILLD('ZXBUSM60', 'collect zxbusd 6');

tst_nl();
DAEMON('ZXBUSM70', 'zxbusd 7', 2229, "./zxbusd -pid tmp/ZXBUSM70.pid -c '$busd_conf' -d -d -nthr 10 -nfd 50 -npdu 5000 -p stomp:0.0.0.0:2229");
DAEMON('ZXBUSM70b','zxbuslist 1',-1,"./zxbuslist -pid tmp/ZXBUSM70b.pid -d -d -c '$bus_list_conf'");
DAEMON('ZXBUSM70c','zxbuslist 2',-1,"./zxbuslist -pid tmp/ZXBUSM70c.pid -d -d -c '$bus_list2_conf'");
CMD('ZXBUSM74', '10x10x20 battery', "./zxbustailf -d -d -c '$bus_cli_conf' -e 'foo bar' -it 10 -i 10 -is 20", 0, 3600, 10);
CMD('ZXBUSM79', 'dump',     "./zxbustailf -c '$bus_cli_conf' -ctl 'dump'");
KILLD('ZXBUSM70b', 'collect zxbuslist 1');
KILLD('ZXBUSM70c', 'collect zxbuslist 2');
KILLD('ZXBUSM70', 'collect zxbusd 7');

tst_nl();
DAEMON('ZXBUSM80', 'zxbusd 8', 2229, "./zxbusd -pid tmp/ZXBUSM80.pid -c '$busd_conf' -nthr 10 -nfd 1000 -npdu 7000 -p stomp:0.0.0.0:2229");
DAEMON('ZXBUSM80b','zxbuslist 1',-1,"./zxbuslist -pid tmp/ZXBUSM80b.pid -d -d -c '$bus_list_conf'");
DAEMON('ZXBUSM80c','zxbuslist 2',-1,"./zxbuslist -pid tmp/ZXBUSM80c.pid -d -d -c '$bus_list2_conf'");
CMD('ZXBUSM84', '10x10x20 battery', "./zxbustailf -c '$bus_cli_conf' -e 'foo bar' -it 10 -i 10 -is 20", 0, 3600, 10);
CMD('ZXBUSM89', 'dump',     "./zxbustailf -c '$bus_cli_conf' -ctl 'dump'");
KILLD('ZXBUSM80b', 'collect zxbuslist 1');
KILLD('ZXBUSM80c', 'collect zxbuslist 2');
KILLD('ZXBUSM80', 'collect zxbusd 8');

### Unit test code that did not get tested otherwise

tst_nl();
CMD('COVIMP1', 'Silly tests just to improve test coverage', "./zxcovimp.sh", 0, 60, 10);

if (0) {
#C('DBG1', 'Test exit value', 0.5, 0.1, "echo foo");
C('SRV1', 'mini_http -p 2301 idp', 5, 0.5, "");

tA('ST', 'ST1', 'static content bypass svn.zxid.org', 5, 0.5, "http://svn.zxid.org/wr/redx.png");
tP('ST', 'ST2', 'static content bypass zxid.org', 5, 0.5, "http://zxid.org/favicon.ico");
}

$success_ratio = $n_tst ? sprintf("=== Test success %d/%d (%.1f%%) ===\n", $n_tst_ok, $n_tst, $n_tst_ok*100.0/$n_tst) : "No tests run.\n";

print $success_ratio if $ascii;

syswrite STDOUT, <<HTML if !$ascii;
</table>
<p><i>Hint: Click on test name to run just that test.</i>

<p><b>$success_ratio</b>

[ <a href="zxtest.pl">zxtest.pl</a> 
| <a href="zxtest.pl?tst=XML">XML Encoding and Decoding</a> 
| <a href="zxtest.pl?tst=ZXC-WS">Web Service calls</a> ]

<hr>
<i>$cvsid</i>
HTML
    ;

__END__
#EOF
