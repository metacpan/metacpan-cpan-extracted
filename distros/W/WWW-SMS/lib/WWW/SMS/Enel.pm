#Copyright (c) 2002 Giulio Motta. All rights reserved.
#http://www-sms.sourceforge.net/
#This program is free software; you can redistribute it and/or
#modify it under the same terms as Perl itself.

package WWW::SMS::Enel;
use Telephone::Number;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(MAXLENGTH);
@EXPORT_OK = qw(@PREFIXES _send MAXLENGTH);

@PREFIXES = (Telephone::Number->new('39', [
                qw(320 328 329 340 347 348 349 333 335 338 339 330 336 337 368 360 380 388 389)
                ], undef)
);

$VERSION = '1.01';

sub MAXLENGTH () {320}

sub hnd_error {
    $WWW::SMS::Error = sprintf "Failed at step %d of module %s", shift, __PACKAGE__;
    return;
}

sub _send {
    my $self = shift;

    use HTTP::Request::Common qw(GET POST);
    use LWP::UserAgent;
    
    my $ua = LWP::UserAgent->new;
    $ua->agent('Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.0; Q312461; .NET CLR 1.0.3328)');
    $ua->proxy('http', $self->{proxy}) if ($self->{proxy});

    $self->{smstext} = substr($self->{smstext}, 0, MAXLENGTH - 1) 
        if (length($self->{smstext})>MAXLENGTH);
    
    my $step = 1;
    my $req = GET 'http://www.enel.it/';
    my $file = $ua->simple_request($req)->as_string;
    my (@cookies) = $file =~ /Set-Cookie:\s(.+?);/g;
    return &hnd_error($step) if (@cookies < 2);

    my $cookie = join "; ", @cookies;
    $step++;
    $req = POST 'http://www.enel.it/scrivisms.asp',
                Cookie  => $cookie,
                Referer => 'http://www.enel.it/scrivisms.asp',
                Content => [
                    message => $self->{smstext}, 
                    prefix  => $self->{prefix},
                    gsm     => $self->{telnum},
                    accetta => 'yes',
                    x => int rand 7,
                    y => int rand 12,
                ];
           
    $file = $ua->simple_request($req)->as_string;
    return &hnd_error($step) unless ($file =~ /Messaggio\+SMS\+accodato/s);

    1;
}

1;
