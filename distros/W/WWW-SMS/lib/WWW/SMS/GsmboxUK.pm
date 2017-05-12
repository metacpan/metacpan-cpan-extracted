#Copyright (c) 2001 Giulio Motta. All rights reserved.
#http://www-sms.sourceforge.net/
#This program is free software; you can redistribute it and/or
#modify it under the same terms as Perl itself.

package WWW::SMS::GsmboxUK;
use Telephone::Number;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw(@PREFIXES _send MAXLENGTH);

@PREFIXES = (Telephone::Number->new('44', [
qw(370 374 378 385 401 402 403 410 411 421 441 467 468 498 585 589 772
780 798 802 831 836 850 860 966 973 976 4481 4624 7000 7002 7074 7624
7730 7765 7771 7781 7787 7866 7939 7941 7956 7957 7958 7961 7967 7970
7977 7979 8700 9797)
        ], undef)
);

$VERSION = '1.00';

sub MAXLENGTH () {120} # maximum message length

sub hnd_error {
    $_ = shift;
    $WWW::SMS::Error = "Failed at step $_ of module GsmboxUK.pm";
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
        my $req = POST 'http://uk.gsmbox.com/freesms/preview.gsmbox',
                    [
                        messaggio => $self->{smstext},
                        prefisso => $self->{prefix},
                        telefono => $self->{telnum},
                        pluto => 'pippo',
                        SUBMIT => 'Send'
                    ];

        my $file = $ua->request($req)->as_string;
        return &hnd_error($step) unless $file =~ /<input type=image border=0 name=(\w+) src=.+? width=(\d+) height=(\d+)>/i;
        my $image_button = $1;
        my $width_button = $2;
        my $height_button = $3;
        #STEP 1

        #STEP 2
        $step++;
        $req = POST 'http://uk.gsmbox.com/freesms/conf_invio.gsmbox',
                    [
                        messaggio => $self->{smstext},
                        telefono => $self->{telnum},
                        prefisso => $self->{prefix},
                        $image_button.'.x' => int(rand($width_button)),
                        $image_button.'.y' => int(rand($height_button)),
                        pluto => 'pippo',
                    ];

        $file = $ua->simple_request($req)->as_string;
        return &hnd_error($step) unless $file =~ /successfully/i;
        #STEP 2

    1;
}

1;
