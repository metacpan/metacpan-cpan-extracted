package WWW::PlaceEngine;

use strict;
use vars qw($VERSION);
use Readonly;
use JSON;
use LWP::UserAgent;
$VERSION = '0.03';
$JSON::QuotApos = 1;
$JSON::UTF8 = 1;

Readonly my $API_HOST      => 'http://www.placeengine.com/api';
Readonly my $RTAG_DAEMON   => 'http://localhost:5448';
Readonly my $APKEY_DEFAULT => 'jVX7qKlFTUUcbNOBAnVX7XFhSUm6FyFzapE5oyv4Y.D6asJrrI5w3dUKsBgrpXe8eDIYrAff3WWKtXxnx.SX7OztpPf7SrrcJK-c0fyZKYSNVn-Gp3Kqb-4-VajcTxlFKt12r44C6oK5OPh7UsWLvt-xB3J.TuPHj0ptHJtuGAn1xc.ZA-4R3LBOQyYUsyphZACHrMvKQ1dAlPZPdyiwxpQfFczAZ4AljisHF5eFvjfYk6y5YUNsaT-TOqNCG22UyLTKL4t0bk.43YJU0M2cbdf07TWmDkQOy5JP9NmX1Ea8vbCZTM.DgEqPrsmrOaI9mmvEVppeCxASBz48ON.shw__,cGVybA__,44OR44O844Or44OX44Ot44Kw44Op44Og';
Readonly my $TESTED_RTAGD  => 'w070606';
Readonly my $AGENT_DEFAULT => "WWW::PlaceEngine/$VERSION";
Readonly my $ERR_NOT_OCCUR => 0;
Readonly my $ERR_WIFI_OFF  => 1;
Readonly my $ERR_NO_AP     => 2;
Readonly my $ERR_WIFI_DENY => 4;
Readonly my $ERR_WIFI_TO   => 5;
Readonly my $ERR_NO_APPKEY => 6;
Readonly my $ERR_NO_RTAGD  => 7;
Readonly my $ERR_NO_HOST   => 8;
Readonly my $ERR_RTAGD_OLD => 9;
Readonly my $ERR_NO_LOCAL  => 10;

Readonly my $ERROR_TABLE   => {
                                  $ERR_NOT_OCCUR => '',
                                  $ERR_WIFI_OFF  => 'WiFi device is maybe turned off.',
                                  $ERR_NO_AP     => 'No APs are found or getting WiFi information is denyed.',
                                  $ERR_WIFI_DENY => 'Getting WiFi information is denyed.',
                                  $ERR_WIFI_TO   => 'Getting WiFi information is timeout.',
                                  $ERR_NO_APPKEY => 'Application key is wrong or not found.',
                                  $ERR_NO_RTAGD  => 'PlaceEngine client not found or cannot accessible.',
                                  $ERR_NO_HOST   => 'PlaceEngine API host cannot accessible.',
                                  $ERR_RTAGD_OLD => "PlaceEngine client's version is old. At least $TESTED_RTAGD version is need",
                                  $ERR_NO_LOCAL  => 'No APs are found in local DB.',
                              };

##############################################################################
# CONSTRCUTOR 
##############################################################################

sub new {
    my $class = shift;
    my %opt   = @_;
    bless {
        host    => $API_HOST      ,
        rtagd   => $RTAG_DAEMON   ,
        appkey  => $APKEY_DEFAULT ,
        errcode => $ERR_NOT_OCCUR ,
        err     => ''             ,
        # overwrite
        %opt,
    }, $class;
}

##############################################################################
# ACCESSOR
##############################################################################
BEGIN{
    for my $name (qw/ua host rtagd appkey err errcode rtag t numap version/)
    {
        eval qq{
            sub $name { \$_[0]->{$name} = \$_[1] if(defined \$_[1]); \$_[0]->{$name} }
        };
    }
}

##############################################################################
# METHODS
##############################################################################

sub get_location {
    my $self = shift;
    $self->check_rtagd or return;
    $self->get_rtag or return;
    $self->decode_rtag();
}

sub get_local_location {
    my $self = shift;
    my $time = shift || $self->t || time;
    my $param = '/locdb?t=' . $time;
    $param .= '&appk=' . $self->appkey;

    my $ua = $self->ua || $self->ua(LWP::UserAgent->new(agent=>$AGENT_DEFAULT));
    my $res = $ua->get($self->rtagd . $param);
    return $self->set_err($ERR_NO_RTAGD) if !$res->is_success;

    my $cont = $res->content;
    my ($long,$lat,$result,$opt) = @{jsonToObj($cont)};
    for my $name (qw/long lat result/) {
        $opt->{$name} = eval qq{\$$name};
    }

    if ($result < 0) {
        return $self->set_err($result * -1);
    } elsif ($result == 0) {
        return $self->set_err($ERR_NO_LOCAL) if (($opt->{lat} == 0.0) && ($opt->{long} == 0.0));
    }

    return $opt;
}

sub check_rtagd {
    my $self = shift;

    return $self->version if $self->version;

    my $ua = $self->ua || $self->ua(LWP::UserAgent->new(agent=>$AGENT_DEFAULT));
    my $origto = $ua->timeout;
    $ua->timeout(30);
    my $res = $ua->get($self->rtagd . '/ackjs?t=' . time);
    $ua->timeout($origto);
    return $self->set_err($ERR_NO_RTAGD) if !$res->is_success;

    my ($version) = $res->content =~ /^ackRTAG\("(.*)"\);$/;

    return $self->set_err($ERR_RTAGD_OLD) if ($version lt $TESTED_RTAGD);

    $self->version($version);
}

sub get_rtag {
    my $self = shift;
    $self->set_err;
    $self->numap(0);
    $self->rtag('');
    $self->t(time);
    return $self->set_err($ERR_NO_APPKEY) if !$self->appkey;

    my $ua = $self->ua || $self->ua(LWP::UserAgent->new(agent=>$AGENT_DEFAULT));
    my $origto = $ua->timeout;
    $ua->timeout(30);
    my $res = $ua->get($self->rtagd . '/rtagjs?t=' . $self->t . '&appk=' . $self->appkey);
    $ua->timeout($origto);
    return $self->set_err($ERR_NO_RTAGD) if !$res->is_success;

    my ($rtag,$numap,$time) = $res->content =~ /^recvRTAG\("(.*)",(.*),(.*)\);$/;

    if ($numap < 0) {
        return $self->set_err($numap * -1);
    } elsif ($numap == 0) {
        return $self->set_err($ERR_NO_AP);
    }

    $self->numap($numap);
    $self->t($time);
    $self->rtag($rtag);
}

sub decode_rtag {
    my $self = shift;
    my $rtag = shift || $self->rtag || '';
    my $time = shift || $self->t || time;

    my $param = '/loc?rtag=' . $rtag . '&t=' . $time;
    $param .= '&appk=' . $self->appkey .'&fmt=json';

    my $ua = $self->ua || $self->ua(LWP::UserAgent->new(agent=>$AGENT_DEFAULT));
    my $res = $ua->get($self->host . $param);
    return $self->set_err($ERR_NO_HOST) if !$res->is_success;

    my $cont = $res->content;
    my ($long,$lat,$range,$opt) = @{jsonToObj($cont)};
    for my $name (qw/long lat range/) {
        $opt->{$name} = eval qq{\$$name};
    }

    if ($opt->{range} == -113) {
        return $self->set_err($opt->{range},'Request format is illegal.');
    } elsif ($opt->{range} <= -100) {
        return $self->set_err($opt->{range},'AP has no location information.');
    } elsif ($opt->{range} <= 0) {
        return $self->set_err($opt->{range},'No APs are found.');
    }
    return $opt;
}

##############################################################################
# ERROR 
##############################################################################

sub set_err {
    my $self = shift;
    my ($errcode,$err) = @_;

    $self->errcode($errcode || 0);
    $self->err( $err || $ERROR_TABLE->{$errcode} || 'Unkown error occured.');

    return;
}

1;

__END__

=pod

=head1 NAME

WWW::PlaceEngine - get PC's location information from PlaceEngine.

=head1 SYNOPSIS

 use WWW::PlaceEngine;
 
 my $wpl = WWW::PlaceEngine->new(
   ua     => $ua,            # LWP::UserAgent's object
   appkey => 'AppKey',       # Application Key
 );
 
 # Check PlaceEngine client exists or not.
 $wpl->check_rtagd() or die $wpl->err;
 
 # Get rtag data.
 my $rtag = $wpl->get_rtag() or die $wpl->err;
 
 my $time  = $wpl->t         # Time of measuring location
 my $numap = $wpl->numap     # Number of found APs
 
 # Get location data.
 my $loc = $wpl->decode_rtag($rtag) or die $wpl->err;
 
 my $lat   = $loc->{lat};    # Latitude
 my $long  = $loc->{long};   # Longitude
 my $addr  = $loc->{addr};   # Address
 my $floor = $loc->{floor};  # Floor
 my $range = $loc->{range};  # Degree of precision
 
 # Or, you can run all process at one method. 
 $loc = $wpl->get_location() or die $wpl->err;
 
 ## Get location from local DB
 $loc = $wpl->get_local_location() or die $wpl->err;
 
 # Get only latlon data from local DB
 my $lat   = $loc->{lat};    # Latitude
 my $long  = $loc->{long};   # Longitude

=head1 DESCRIPTION

This module get PC's location information from PlaceEngine client and API host.
For PlaceEngine, See to http://www.placeengine.com/.

=head1 METHODS

=over 4

=item new()

=item new( %options )

returns a WWW::PlaceEngine object.

 my $wpl = WWW::PlaceEngine->new();

C<new> can take some options.

 my $wpl = WWW::PlaceEngine->new(ua => LWP::UserAgent->new, appkey => 'WRO4eQ....UgTWFw');

Following options are supported:

=over 4

=item ua

=item appkey

PlaceEngine needs application key (appkey) to get location information from host.
Application key is determined from application's name (like perl.exe), and you can get it
form http://www.placeengine.com/appk .
By default, appkey are set to appkey of perl.exe. 
You can change them to your own appkey by this option.

=item host

URL of PlaceEngine API host.
http://www.placeengine.com/api by default.

=item rtagd
URL of PlaceEngine client daemon.
http://localhost:5448 by default.

=back

=item ua()

=item ua( $ua )

get or set LWP::UserAgent's object by this method.

=item appkey()

=item appkey( $appkey )

get or set appkey by this method.

=item host()

=item host( $host )

get or set URL of PlaceEngine API host by this method.

=item rtagd()

=item rtagd( $rtagd )

get or set URL of PlaceEngine client daemon by this method.

=item rtag

get AP's electric field strength data (called B<rtag>).
This property will be set after run C<check_rtagd> method.

=item numap

get found AP's number.
This property will be set after run C<check_rtagd> method.

=item t

get time of mesuring location.
This property will be set after run C<check_rtagd> method.

=item check_rtagd()

check PlaceEngine client is exist or not, and version of it.
If PlaceEngine client is not exist or old version, this method return undef value.
Error message can be checked by C<err> method.

=item get_rtag()

get AP's electric field strength data (called B<rtag>) from PlaceEngine client.
And also, after execute this method, C<rtag>, C<numap> and C<t> properties are set.
If some error occurs, this method return undef value, and error message can be checked by C<err> method.

=item decode_rtag([rtag],[time])

access to API host and decode B<rtag> to  from PC's location information.
Argument rtag and time are optional, and if not given, C<rtag> and C<t> properties are used.
This method returns hash reference of location data and it includes:

=over 4

=item lat

Latitude.

=item long

Longitude.

=item addr

Address string.

=item range

Degree of precision (Unit is meter).

=item floor

Floor.

=item msg

Japanese message returned from PlaceEngine API host.

=item t

Time of mesuring location.

=back

If some error occurs, this method return undef value, and error message can be checked by C<err> method.

=item get_location()

run C<check_rtagd>, C<get_rtag> and C<decode_rtag> methods in order.
If some error occurs, this method return undef value, and error message can be checked by C<err> method.

=item get_local_location()

ask location to local DB.
This method is independent and cannot share rtag data with other methods.
For example, even if you set old rtag data to rtag property, this method returns realtime location data.

 my $wpl = WWW::PlaceEngine->new();
 
 # Set yesterday's rtag data
 my $wpl->rtag($rtag_yesterday);
 
 # Get location from local DB
 my $loc = $wpl->get_local_location();
 
 # $loc is not yesterday's location but now location data.

If some error occurs, this method return undef value, and error message can be checked by C<err> method.

=item err

returns error string if error occurs.

=item errcode

return error code if error occurs.

=back

=head1 DEPENDENCIES

Readonly
JSON

=head1 SEE ALSO

http://www.placeengine.com/

=head1 AUTHOR

OHTSUKA Ko-hei, E<lt>nene[at]kokogiko.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2007 by OHTSUKA Ko-hei

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
