#!/usr/bin/perl -w

#Automagically generated from SMSSplitter scripts
#Credits goes to Aleph0 Edition! http://www.aleph0.f2s.com for the original
#implementation as a SMSsplitter script
#Simply reimplemented by Giulio Motta

package WWW::SMS::GoldenTelecom;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw(@PREFIXES _send MAXLENGTH);
undef @PREFIXES;
$VERSION = '1.00';

sub MAXLENGTH ()	{160}

sub hnd_error {
	$_ = shift;
	$WWW::SMS::Error = "Failed at step $_ of module GoldenTelecom.pm\n";
	return 0;
}

sub _send {
	my $self = shift;

	use HTTP::Request::Common qw(GET POST);
	use HTTP::Cookies;
	use LWP::UserAgent;

	$ua = LWP::UserAgent->new;
	$ua->agent('Mozilla/5.0');
	$ua->proxy('http', $self->{proxy}) if ($self->{proxy});
	$ua->cookie_jar(HTTP::Cookies->new(
						file => $self->{cookie_jar},
						autosave => 1
					)
	);

	$self->{smstext} = substr($self->{smstext}, 0, MAXLENGTH - 1) if (length($self->{smstext})>MAXLENGTH);

	#STEP 1
	my $step = 1;
	$req = POST 'http://sms.gt.com.ua:8080/SendSM.htm',
		[
		'SM' => $self->{smstext} ,
		'num' => (MAXLENGTH - length($self->{smstext})) ,
		'MN' => '+' . $self->{intpref} . $self->{prefix} . $self->{telnum} ,
		'CS' => 'S' ,
		];
	$req->headers->referer('http://sms.gt.com.ua/index.htm');
	$file = $ua->simple_request($req)->as_string;
	return &hnd_error($step) unless ($file =~ /Message sent/s);
	#STEP 1
	$ua->cookie_jar->clear('sms.gt.com.ua');
	1;
}

1;
