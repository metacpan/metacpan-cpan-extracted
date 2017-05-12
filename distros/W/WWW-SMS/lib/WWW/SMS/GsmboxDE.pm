#Copyright (c) 2001 Giulio Motta. All rights reserved.
#http://www-sms.sourceforge.net/
#This program is free software; you can redistribute it and/or
#modify it under the same terms as Perl itself.
#
# de.gsmbox.com modelled after GsmboxUK, 
# looks promising, but it does not work...
# The original webpage also fails, hmmm.
# Thu Jun 27 20:19:37 CEST 2002, Juergen Weigert, jw@netvision.de

package WWW::SMS::GsmboxDE;
use Telephone::Number;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw(@PREFIXES _send MAXLENGTH);

@PREFIXES = (Telephone::Number->new('49', [
qw(151 160 170 171 175 152 1520 162 172 173 174 163 177 178 176 179)
        ], undef)
);

$VERSION = '1.00';

sub MAXLENGTH () {120} # maximum message length

sub hnd_error {
    $_ = shift;
    $WWW::SMS::Error = "Failed at step $_ of module GsmboxDE.pm";
    return 0;
}

sub _send {
    my $self = shift;

    use HTTP::Request::Common qw(GET POST);
    use HTTP::Cookies;
    use LWP::UserAgent;

    return hnd_error("0 (GsmboxDE is unfinished)");
    
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
        my $req = POST 'http://de.gsmbox.com/freesms/preview.gsmbox',
                    [
                        messaggio => $self->{smstext},
                        prefisso => $self->{prefix},
                        telefono => $self->{telnum},
                        pluto => '8790',
                        country => 'de',
                        SUBMIT => 'Absenden'
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
                        country => 'de',
 '96fe31369659d886e1723c9a46a08bb6' => 'f667dbb8ed2bbf65cd13476e9a21ea8a',
                        $image_button.'.x' => int(rand($width_button)),
                        $image_button.'.y' => int(rand($height_button)),
                    ];

        $file = $ua->simple_request($req)->as_string;
        return &hnd_error($step) unless $file =~ /successfully/i;
        #STEP 2

    1;
}

1;
