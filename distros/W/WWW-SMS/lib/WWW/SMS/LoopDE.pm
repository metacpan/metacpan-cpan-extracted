#Copyright (c) 2001 Giulio Motta. All rights reserved.
#http://www-sms.sourceforge.net/
#This program is free software; you can redistribute it and/or
#modify it under the same terms as Perl itself.
#
# web2sms.loop.de does only send to german Viag Interkom users, but that is all I need.
# Note that $debug=1 will stress the step parameter of hnd_error a lot.
# Thu Jun 27 20:12:01 CEST 2002, Juergen Weigert, jw@netvision.de

package WWW::SMS::LoopDE;
use Telephone::Number;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw(@PREFIXES _send MAXLENGTH);

@PREFIXES = (Telephone::Number->new('49', [ qw(179 176) ], undef));

$VERSION = '1.00';

sub MAXLENGTH () {120} # maximum message length

sub hnd_error {
    $_ = shift;
    $WWW::SMS::Error = "Failed at step $_ of module LoopDE.pm";
    return 0;
}

sub _send {
    my $self = shift;

    use HTTP::Request::Common qw(GET POST);
    use HTTP::Cookies;
    use LWP::UserAgent;

    my $debug = 0;
    
    $self->{smstext} = substr($self->{smstext}, 0, MAXLENGTH - 1) if (length($self->{smstext})>MAXLENGTH);

        my $ua = LWP::UserAgent->new;
        $ua->agent('Mozilla/5.0');
        $ua->proxy('http', $self->{proxy}) if ($self->{proxy});
        $ua->cookie_jar(HTTP::Cookies->new(
                        file => $self->{cookie_jar},
                        autosave => 1
                        )
                );

        my $step = 1;
        #STEP 1		----------- give me your cookie!
        my $req = GET 'http://web2sms.loop.de/sms_eingabe.asp';
        my $file = $ua->request($req)->as_string;
        return &hnd_error($debug ? "$step ($file)" : $step) unless $file =~ m{sms_agbs.asp}i;

        #STEP 2		----------- give me another cookie
        $step++;
        $req = POST 'http://web2sms.loop.de/sms_agbs.asp',
                    [
                        MessageText => $self->{smstext},
                        prefix => $self->{intpref} . $self->{prefix},
                        MSISDN => $self->{telnum},
		        num => (MAXLENGTH - length($self->{smstext})) ,
			gen_b_senden.x => int(rand(80)),
			gen_b_senden.y => int(rand(14)),
                        SUBMIT => 'Absenden'
                    ];

        $file = $ua->request($req)->as_string;
        return &hnd_error($debug ? "$step ($self->{prefix}, ($file)" : $step) 
	  unless $file =~ m{b_akzeptieren.gif"\s.*alt="akzeptieren"\s};
        #STEP 2

        #STEP 3		----------- now we fire and forget
        $step++;
        $req = POST 'http://web2sms.loop.de/sms_process.asp',
                    [
                        MessageText => $self->{smstext},
                        MSISDN => $self->{intpref} . $self->{prefix} . $self->{telnum},
                        gen_b_akzeptieren.'.x' => int(rand(80)),
                        gen_b_akzeptieren.'.y' => int(rand(14)),
                    ];

        $file = $ua->simple_request($req)->as_string;
        return &hnd_error($debug ? "$step ($file)" : $step) unless $file =~ m{sms_result.asp}i;
        #STEP 3

    1;
}

1;
