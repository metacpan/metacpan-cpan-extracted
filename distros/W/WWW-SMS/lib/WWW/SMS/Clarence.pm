#!/usr/bin/perl

#Copyright (c) 2001 Giulio Motta. All rights reserved.
#http://www-sms.sourceforge.net/
#This program is free software; you can redistribute it and/or
#modify it under the same terms as Perl itself.

package WWW::SMS::Clarence;
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

sub MAXLENGTH () {120} # maximum message length

sub hnd_error {
	$_ = shift;
	$WWW::SMS::Error = "Failed at step $_ of module Clarence.pm\n";
	return 0;
}

sub _send {
	my $self = shift;

	use HTTP::Request::Common qw(GET POST);
	use HTTP::Cookies;
	use LWP::UserAgent;
	
	$self->{smstext} = substr($self->{smstext}, 0, MAXLENGTH - 1) if (length($self->{smstext})>MAXLENGTH);

		SWITCH: for ($self->{prefix}) {
					/^33/	&& do {$wholeprefix = "$self->{prefix}+22201"; last;};
					/^34/	&& do {$wholeprefix = "$self->{prefix}+22210"; last;};
					/^32/	&& do {$wholeprefix = "$self->{prefix}+22288"; last;};
					/^38/	&& do {$wholeprefix = "$self->{prefix}+22298"; last;};
					die "Prefix not supported...\n";
		}

		my $ua = LWP::UserAgent->new;
		$ua->agent('Mozilla/5.0');
		$ua->proxy('http', $self->{proxy}) if ($self->{proxy});
		$ua->cookie_jar(HTTP::Cookies->new(
						file => $self->{cookie_jar},
						autosave => 1
						)
				);

		#STEP 1
		my $step = 1;
		my $req = POST 'http://sms.clarence.com/sms2.php3',
					[
						testosms => $self->{smstext}, smartype => "1tx1",
						chiave => "", shortid => "",
						submit => "Invia il tuo messaggio"
					];

		my $res = $ua->request($req);
		$res->is_success() || (return &hnd_error($step));
		#STEP 1

		#STEP 2
		$step++;
		$req = POST 'http://sms.clarence.com/sms3.php3',
					[
						testosms => $self->{smstext}, prefix => $wholeprefix,
						nrotel => $self->{telnum}, binvio => "Invia"
					];

		$file = $ua->simple_request($req)->as_string;
		($file =~ /Location: (.+?)\n/) || (return &hnd_error($step));
		#STEP 2

		#STEP 3
		$step++;
		$req = GET "http://sms.clarence.com/$1";
		$file = $ua->simple_request($req)->as_string;
		($file =~ /Location: (.+?)\n/) || (return &hnd_error($step));
		#STEP 3
		
		#STEP 4
		$step++;
		$temp = $1;
		$temp =~ s/\ /\%20/g;
		$req = GET $temp;
		$file = $ua->simple_request($req)->as_string;
		return &hnd_error($step) unless
			($file =~ /<input type=hidden name=\"sessionid\" value=\"([^\"]+)\">.*<input type=hidden name=\"mittente\" value=\"([^\"]+)\">/s);
		#STEP 4
	
		#STEP 5
		$step++;
		my $sessionid = $1;
		my $ip = $2;
		$req = POST 'http://freesms.supereva.it/cgi-bin/clarence/sendsms.chm',
					[
						sessionid => $sessionid, mittente => $ip,
						prefix => $self->{prefix}, numtel => $self->{telnum},
						messagetext => $self->{smstext}, flash => "0",
						Submit => " Invia "
					];
		$req->headers->referer($temp);
		$file = $ua->request($req)->as_string;
		return &hnd_error($step) if ($file =~ /spiacente/i);
		#STEP 5
	1;
}

1;
