#!/usr/bin/perl -w
#Copyright (c) 2001 Giulio Motta. All rights reserved.
#http://www-sms.sourceforge.net/
#This program is free software; you can redistribute it and/or
#modify it under the same terms as Perl itself.
#
# required are openssl and NET::SSL; more details in the help prepended below
# you have to sign up with O2 (previous genie) as well
# which is free at the moment and you can send 100 sms/month free
# you have to pass the username/password or the file which contains it
# dunno all the sim cards provided yet: o2 and vodafone work
# Sat Nov  2 13:01:57 GMT 2002, Andre Howe, perl@andreh.de

package WWW::SMS::o2UK;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw(@PREFIXES _send MAXLENGTH);
undef @PREFIXES;
$VERSION = '1.00';

@PREFIXES = (Telephone::Number->new('44', undef, undef));

my $debug = 0;    # to switch on more debug output - is handled in levels 0 = no, 1 = low, n= high
my $send_sms = 1; # set this to one to turn off sending the sms in case you want to debug 
                  # something but not wasting your free sms

sub MAXLENGTH ()	{115}

sub hnd_error {
	$_ = shift;
	$WWW::SMS::Error = "Failed at step $_ of module o2UK.pm\n";
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

    # preparing the message for the maximum length available
	$self->{smstext} = substr($self->{smstext}, 0, MAXLENGTH - 1) if (length($self->{smstext})>MAXLENGTH);

    #
    #STEP 1 - checking if all the modules are installed 
	#
    my $step = 1;
    # @todo ahe - check here for the modules needed e.g. Net::Ssl
    print "\n STEP[$step] finished succesfully :-)\n" if $debug;
    #
    #STEP 1 - END
    #

    #
    #STEP 2 - checking if the username and password is passed
	#
    $step = 2;
	return &hnd_error($step) unless (($self->{username} && $self->{password}));
    print "\n STEP[$step] finished succesfully :-)\n" if $debug;
    #
    #STEP 2 - END
    #

    #
	#STEP 3  - first login to O2
    #
	$step = 3;
	$req = POST 'https://gordon.genie.co.uk/login/mblogin',
		[
        'username' => $self->{username},
        'password' => $self->{password} 
		];

    my $file = $ua->request($req)->as_string;
    print $file if ($debug >= 3);
	return &hnd_error($step) unless ($file =~ /firstname/s);

    my $firstname = $1 if ($file =~ m/"firstname"\s+value="(.*)"/); print "\n firstname = $firstname" if ($debug >= 2);
    my $username  = $1 if ($file =~ m/"username"\s+value="(.*)"/);  print "\n username  = $username"  if ($debug >= 2);
    my $dest      = $1 if ($file =~ m/"dest"\s+value="(.*)"/);      print "\n dest      = $dest"      if ($debug >= 2);
    my $mID       = $1 if ($file =~ m/"mID"\s+value="(.*)"/);       print "\n mID       = $mID"       if ($debug >= 2);
    my $mAT       = $1 if ($file =~ m/"mAT"\s+value="(.*)"/);       print "\n mAT       = $mAT"       if ($debug >= 2);      
    my $QE3       = $1 if ($file =~ m/"QE3"\s+value="(.*)"/);       print "\n QE3       = $QE3 \n"    if ($debug >= 2);    

    print "\n STEP[$step] finished succesfully :-)\n" if $debug;
    #
    #STEP 3 - END
    #

    #
    #STEP 4  - second login to O2
    #
    $step = 4;
	$req = POST 'https://ming.mediamessaging.o2.co.uk/login/mm_bglogin',
		[
        'firstname' => $firstname,
        'username'  => $username,
        'dest'      => $dest,
        'mID'       => $mID,
        'mAT'       => $mAT,
        'QE3'       => $QE3
		];

    $file = $ua->request($req)->as_string;
    print $file if ($debug >= 3);
	return &hnd_error($step) unless ($file =~ /firstname/s);

    $firstname = $1 if ($file =~ m/"firstname"\s+value="(.*)"/);    print "\n firstname = $firstname" if ($debug >= 2);
    $username  = $1 if ($file =~ m/"username"\s+value="(.*)"/);     print "\n username  = $username"  if ($debug >= 2);
    $dest      = $1 if ($file =~ m/"dest"\s+value="(.*)"/);         print "\n dest      = $dest"      if ($debug >= 2);
    $mID       = $1 if ($file =~ m/"mID"\s+value="(.*)"/);          print "\n mID       = $mID"       if ($debug >= 2);
    $mAT       = $1 if ($file =~ m/"mAT"\s+value="(.*)"/);          print "\n mAT       = $mAT"       if ($debug >= 2);      
    $QE3       = $1 if ($file =~ m/"QE3"\s+value="(.*)"/);          print "\n QE3       = $QE3 \n"    if ($debug >= 2);

    print "\n STEP[$step] finished succesfully :-)\n" if $debug;
    #
    #STEP 4 - END
    #

    #
    #STEP 5  - third login
    #
    $step = 5;
	$req = POST 'https://zarkov.shop.o2.co.uk/login/bglogin',
		[
        'firstname' => $firstname,
        'username'  => $username,
        'dest'      => $dest,
        'mID'       => $mID,
        'mAT'       => $mAT,
        'QE3'       => $QE3
		];

    $file = $ua->request($req)->as_string;
    print $file if ($debug >= 3);
	return &hnd_error($step) unless ($file =~ /<META HTTP-EQUIV=\"Refresh\" CONTENT="0; URL=http/s);

    print "\n STEP[$step] finished succesfully :-)\n" if $debug;
    #
    #STEP 5
    #

    #
    #STEP 6  - checking if the login was successful
    #
    $step = 6;
	$req = GET 'http://www.O2.co.uk';
    $file = $ua->request($req)->as_string;
    print $file if ($debug >= 3);
	return &hnd_error($step) unless ($file =~ /Welcome back,/s);
    print "\n STEP[$step] finished succesfully :-)\n" if $debug;
    #
    #STEP 6 - END
    #


    #
    #STEP 7  - checking if we still have free sms on this account available
    #
    $step = 7;
    $req = GET 'http://sendtxt.genie.co.uk/cgi-bin/sms/send_sms.cgi';
    $file = $ua->request($req)->as_string;
    print $file if ($debug >= 3 );
    my $free_sms_left_this_month = $1 if ($file =~ /You have (\d+) messages of your Free quota/);
    print "\n free_sms_left_this_month = [$free_sms_left_this_month]\n";
    # @todo ahe - have never tested the next two lines in case that there are no messages left
    return &hnd+error($step+777) if ( $free_sms_left_this_month == '0');
	return &hnd_error($step) unless ($file =~ /messages of your Free quota left to send this month./s);
    print "\n STEP[$step] finished succesfully :-)\n" if $debug;
    #
    #STEP 7 - END
    #

    #
	#STEP 8 - sending SMS - finally :-)
    #
	$step = 8;
	$req = POST 'http://sendtxt.genie.co.uk/cgi-bin/sms/send_sms.cgi',
		[
        'contact'    => '', 
        'RECIPIENT'  => '0' . $self->{prefix} . $self->{telnum} , 
        'SUBJECT'    => '',
		'MESSAGE'    => $self->{smstext} ,
        'action'     => 'Send',
        'check'      => '0', 
        'numbers'    => '', 
        'noOfPhones' => '' ,
		];

    if($send_sms) {    
	   $req->headers->referer('http://www.O2.co.uk');
       $file = $ua->request($req)->as_string;
       print $file if ($debug >= 3);
    }

    # logout -    http://www.o2.co.uk/logout.html
    $req = GET 'http://www.o2.co.uk/logout.html';
    my $res = $ua->request($req);
    print $res->code."\n" if $debug;

    # @todo ahe - is this the right address/filename/?? for the removal ??
    $ua->cookie_jar->clear('sendtxt.genie.co.uk');

	return &hnd_error($step) unless ($file =~ /message%2520has%2520been%2520sent/s);
    print "\n STEP[$step] finished succesfully :-)\n" if $debug;
    #
    #STEP 8 - END
    #

	1;
}

1;

=head2 Install

    perl modules can be found at  http://search.cpan.org/


=head2 openssl


    get the latest openssl from http://www.openssl.org

    linux:/usr/src # tar -zxvf openssl-0.9.6g.tar.gz   

    $ ./config
    $ make
    $ make test
    $ make install

=head2 NET::SSL

    get latest Net::Ssl from  http://search.cpan.org/author/CHAMAS/    
    linux:/usr/src # tar -zxvf Crypt-SSLeay-0.45.tar.gz
      > perl Makefile.PL
      > make
      > make test
      > make install

    and test it :-)

    # lwp-request https://www.nodeworks.com

    use LWP::UserAgent;
    my $ua = new LWP::UserAgent;
    my $req = new HTTP::Request('GET', 'https://www.nodeworks.com');
    my $res = $ua->request($req);
    print $res->code."\n";

    res code should be 200 in case of success

=head2 WWW::SMS

    get latest Www::Sms from http://search.cpan.org/author/GIULIENK/

    update SMS.pm with the new provider if wanted
    copy o2UK.pm into your /WWW/SMS/ perl library directory, e.g. into:
    linux:/usr/lib/perl5/site_perl/5.6.1/WWW/SMS>

    you have to sign up with O2 http://www.o2.co.uk/ (previous genie)
    which is free at the moment and you can send 100 sms/month free
    you have to pass the username/password or the file which contains it
    dunno all the sim cards provided yet: o2 and vodafone work

    and test it :-)

    use WWW::SMS;
    #international prefix, operator prefix, phone number, message text
    my $sms = WWW::SMS->new('44', '7777', '123456', 'This is a test.','username' => 'your_o2_username', 'password' => 'your_o2_password');
    for ( $sms->gateways() ) {
        print "Trying $_...\n";
        if ( $sms->send($_) ) {               # try to send a sms...
            last;                             # until it succeds ;)
        } else {
            print $WWW::SMS::Error;           # unlucky!
        }
    }

=cut
