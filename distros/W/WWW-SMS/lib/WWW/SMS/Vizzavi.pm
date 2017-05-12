#!/usr/bin/perl -w

#Automagically generated from SMSSplitter scripts
#Credits goes to Aleph0 Edition! http://www.aleph0.f2s.com for the original
#implementation as a SMSsplitter script
#Simply reimplemented by Giulio Motta

package WWW::SMS::Vizzavi;
use Telephone::Number;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw(@PREFIXES _send MAXLENGTH);

@PREFIXES = (Telephone::Number->new('39', [
              	qw(333 335 338 339 340 347 348 349 328 329 380 388 389)
            	], undef)
);

$VERSION = '1.01';
sub MAXLENGTH ()	{140}

sub hnd_error {
	$_ = shift;
	$WWW::SMS::Error = "Failed at step $_ of module Vizzavi.pm\n";
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

	$self->{smstext} = substr($self->{smstext}, 0, MAXLENGTH - 1) 
		if (length($self->{smstext})>MAXLENGTH);

	$req = POST 'http://sms.vizzavi.it/global.asp', 
			[
			'txtMsg' => $self->{smstext} ,'selPref' => $self->{prefix},
			'TypeOpen' => '1' ,'txtTel' => $self->{telnum} ,
			'Counter' => '' 
			];
	$req->headers->referer('http://sms.vizzavi.it/freesms_conf.asp');
	my $step = 1;
	$file = $ua->simple_request($req)->as_string;
	return &hnd_error($step) unless ($file =~ m'Messaggio\+accodato\+con\+successo's);
	$ua->cookie_jar->clear('sms.vizzavi.it');
	1;
}

1;
