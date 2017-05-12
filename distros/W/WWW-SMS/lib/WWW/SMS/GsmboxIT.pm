#!/usr/bin/perl

#Copyright (c) 2001 Giulio Motta. All rights reserved.
#http://www-sms.sourceforge.net/
#This program is free software; you can redistribute it and/or
#modify it under the same terms as Perl itself.

package WWW::SMS::GsmboxIT;
use Telephone::Number;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw(@PREFIXES _send MAXLENGTH);

@PREFIXES = (Telephone::Number->new('39', [
		qw(333 334 335 338 339 330 336 337 360 368 340 347 348 349 328 329 380 388 389)
		], undef)
);

$VERSION = '1.00';

sub MAXLENGTH () {120} # maximum message length

sub hnd_error {
	$_ = shift;
	$WWW::SMS::Error = "Failed at step $_ of module GsmboxIT.pm\n";
	return 0;
}

sub _send {
	my $self = shift;

	use HTTP::Request::Common qw(GET POST);
	use HTTP::Cookies;
	use LWP::UserAgent;
	
	$self->{smstext} = substr($self->{smstext}, 0, MAXLENGTH - 1) if (length($self->{smstext})>MAXLENGTH);

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
		my $req = POST 'http://it.gsmbox.com/freesms/preview.gsmbox',
					[
						messaggio => $self->{smstext},
						country => 'it',
						prefisso => $self->{prefix},
						telefono => $self->{telnum},
					];

		my $file = $ua->simple_request($req)->as_string;
		($file =~ /<input type=hidden name=\"(\w{32})\" value=\"(\w{32})\">/) || (return &hnd_error($step));
		$hidname = $1;
		$hidval = $2;
		#STEP 1

		#STEP 2
		$step++;
		$req = POST 'http://it.gsmbox.com/freesms/conf_invio.gsmbox',
					[
						sponsor_id => '0',
						messaggio => $self->{smstext},
						telefono => $self->{telnum},
						prefisso => $self->{prefix},
						country => $self->{it},
						$hidname => $hidval,
					];

		$file = $ua->simple_request($req)->as_string;
		($file !~ /BATTERIA IN CARICA/i) || (return &hnd_error($step));
		#STEP 2

	1;
}

1;
