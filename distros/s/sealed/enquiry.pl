#!/usr/local/bin/perl -T -I/x1/cms/build/lib
use Apache2::RequestRec;
use Apache2::RequestUtil;
use Apache2::RequestIO;
use APR::Request::Apache2;
use Dotiac::DTL qw/Template *TEMPLATE_DIRS/;
use Dotiac::DTL::Addon::markup;
use File::Basename;
use strict;
use warnings;
use sealed 'deparse';

my Apache2::RequestRec $r = shift;

my $DOMAIN = q/sunstarsys.com/;
my $to     = q/sales@sunstarsys.com/;
my $date   = gmtime;

sub render :Sealed {
    my Dotiac::DTL::Template $template = shift;
    my Apache2::RequestRec $r = shift;
    my APR::Request::Apache2 $apreq_class = "APR::Request::Apache2";
    my APR::Request $apreq = $apreq_class->handle($r);
    my APR::Request::Param::Table $params = $apreq->param // {};
    my %args = (%$params, @_);
    $r->content_type("text/html; charset='utf-8'");
    local our @TEMPLATE_DIRS = dirname($0) . "/templates";
    $template = Template($template);
    $r->print($template->render(\%args));
    exit 0;
}

if ($r->method eq "POST") {
    my APR::Request::Apache2 $apreq_class = "APR::Request::Apache2";
    my APR::Request $apreq = $apreq_class->handle($r);
    my APR::Request::Param::Table $body = $apreq->body;
    my ($name, $email, $subject, $content, $site, $hosting, $plang) = @{$body}{qw/name email subject content site hosting plang/};
    s/\r//g for $name, $email, $subject, $content, $site, $hosting, $plang;
    s/\n//g for $name, $email, $subject, $hosting, $site, $plang;

    my ($cn, $srs_sender) = ($name, $email);

    for ($cn, $subject) {
        if (s/([^^A-Za-z0-9\-_.,!~*' ])/sprintf "=%02X", ord $1/ge) {
            tr/ /_/;
            $_ = "=?utf-8?Q?$_?=";
        }
    }

    if ($subject =~ /^cms/i) {
	s/^(.*)\@(.*)$/SRS0=999=99=$2=$1/, y/A-Za-z0-9._=-//dc for $srs_sender;
	$srs_sender =~ /(.*)/;
	length $1 or die "BAD EMAIL: $email";
	%ENV = ();

	open my $sendmail, "|-", "/usr/sbin/sendmail", qw/-t -oi -odq -f/, "$1\@$DOMAIN";
	print $sendmail <<EOT;
To: $to
From: $cn <$srs_sender\@$DOMAIN>
Reply-To: $cn <$email>
Subject: $subject
Date: $date +0000
Content-Type: text/plain; charset="utf-8"

$content

WEBSITE: $site
HOSTING: $hosting
LANGUAGE: $plang
EOT

   	close $sendmail or die "sendmail failed: " . ($! || $? >> 8) . "\n";
    }

    render "enquiry_post.html", $r,
        content => "## Thank You!\n\nOur Sales Team will get back to you shortly.\n",
        headers => { title => "CMS Sales Enquiry" };
}

render "enquiry_get.html", $r;
