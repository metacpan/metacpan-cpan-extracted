#!/usr/bin/perl -w

#Copyright (c) 2001 Dmitry Dmitriev. All rights reserved.
#http://www-sms.sourceforge.net/
#This program is free software; you can redistribute it and/or
#modify it under the same terms as Perl itself.

package WWW::SMS::Beeline;
use Telephone::Number;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw(@PREFIXES _send MAXLENGTH);

@PREFIXES = (Telephone::Number->new('7', [
                qw(095 901 903)
		], undef)
);

$VERSION = '1.01';

sub MAXLENGTH () {156} # maximum message length

sub hnd_error {
	$_ = shift;
	$WWW::SMS::Error = "Failed at step $_ of module Beeline.pm\n";
	return 0;
}

sub _send {
	my $self = shift;
	
	use LWP::UserAgent;
	use HTTP::Request::Common qw(GET POST);
	
	$self->{smstext} = substr($self->{smstext}, 0, MAXLENGTH - 1) if (length($self->{smstext})>MAXLENGTH);

	  my $ua = LWP::UserAgent->new;
	  $ua->agent('Mozilla/5.0');
	  $ua->proxy('http', $self->{proxy}) if ($self->{proxy});


          #STEP 1
	  my $step = 1;	
	 
	  $req = POST 'http://www.beeonline.ru/mini-site/xt_sendsms_msg.xsp',
	                    [ phone => $self->{telnum},
			      smpl_phone => $self->{telnum},
			      service => '1',
			      number_sms => 'name_sms_send',
			      prf => $self->{intpref} . $self->{prefix},
			      termtype => 'G',
			      message => $self->{smstext},
			      mlength => "156"
			     ]; 
			     
          my $file=$req->content;
	  $req = GET 'http://www.beeonline.ru/mini-site/xt_sendsms_msg.xsp?'.$file.'&y=%36&x=%33%34';
	  $req->content_type('application/x-www-form-urlencoded');
          $req->referer('http://www.beeonline.ru/mini-site/sendsms.xsp');
	  $res = $ua->request($req);
	  $res->is_success() || (return &hnd_error($step));
	  #STEP 1
          
	  #STEP 2
          $step++;
	  ($res->content =~ /Ваше сообщение отправлено!/) || (return &hnd_error($step));
	  #STEP 2
	  1;      
 
}
1;
