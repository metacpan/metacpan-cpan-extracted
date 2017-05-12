#!/usr/bin/perl -w

#Copyright (c) 2001 Dmitry Dmitriev. All rights reserved.
#http://www-sms.sourceforge.net/
#This program is free software; you can redistribute it and/or
#modify it under the same terms as Perl itself.

package WWW::SMS::MTS;
use Telephone::Number;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw(@PREFIXES _send MAXLENGTH);

@PREFIXES = (Telephone::Number->new('7', [
                qw(095 902 910)
		], undef)
);

$VERSION = '1.03';

sub MAXLENGTH () {155} # maximum message length

sub hnd_error {
	$_ = shift;
	$WWW::SMS::Error = "Failed at step $_ of module MTS.pm\n";
	return 0;
}

sub _send {
	my $self = shift;
	
	# now useless with @PREFIXES
	#if ( $self->{intpref} ne '7' ) {
		#  $WWW::SMS::Error = "Int. prefix $self->{intpref} not supported by MTS gateway\n";
	#  return 0;}
	
        use LWP::UserAgent;
	use HTTP::Request::Common qw(GET POST);
	
	
	
	$self->{smstext} = substr($self->{smstext}, 0, MAXLENGTH - 1) if (length($self->{smstext})>MAXLENGTH);

	  my $ua = LWP::UserAgent->new;
	  $ua->agent('Mozilla/5.0');
	  $ua->proxy('http', $self->{proxy}) if ($self->{proxy});


          #STEP 1
	  my $step = 1;	
          ### define SMS expiration date
	  my ($day,$mon,$year)=(localtime time)[3,4,5];
	  if ($day > 27) {$day=2;$mon++;
                if ($mon > 11) {$mon=0;$year++}
		}
          else {$day+=2;}		
          $year=1900+$year;
	  
          $req = POST 'http://www.mtsgsm.com/sms/sent.html',
	                    [   Posted => '1',
				To => $self->{intpref} . $self->{prefix} . $self->{telnum},
				Msg => $self->{smstext},
				count => length($self->{smstext}),
				SMSHour => '23',
				SMSMinute => '59',
				SMSDay => $day,
				SMSMonth => $mon,
				SMSYear => $year		
			    ];
	  my $file=$req->content;
	  $req = GET 'http://www.mtsgsm.com/sms/sent.html?'.$file;
	  $req->content_type('application/x-www-form-urlencoded');
          $req->referer('http://www.mtsgsm.com/sms');
	  $res = $ua->request($req);
	  $res->is_success() || (return &hnd_error($step));
	  #STEP 1
          
	  #STEP 2
          $step++;
	  ($res->content =~ /<b>(чБЫЕ УППВЭЕОЙЕ ПФРТБЧМЕОП|Ваше сообщение отправлено|Message sent)<\/b>/)
	  || (return &hnd_error($step));
	  #STEP 2
	  1;      
 
}
1;
