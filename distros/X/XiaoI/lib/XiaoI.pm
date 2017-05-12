package XiaoI;

use 5.008005;
use strict;
use warnings;
use JSON;
require Exporter;

our @ISA = qw(Exporter);

our $VERSION = '0.03';


# Preloaded methods go here.
use LWP::UserAgent;
use Encode qw/encode decode/;
use Data::Dumper;
sub new {
    my ($class) = @_;
    my $ua = LWP::UserAgent->new;
    $ua->cookie_jar({});

    my $self = {ua => $ua};
    bless $self, $class;
    $self->login;
    return $self;
}



sub login {
    my $self = shift;
    my $ua = $self->{ua};
    my $login_page = $ua->get('http://webbot.xiaoi.com/engine/flashrobot2/webbot.js?encoding=utf-8')->content;
    if ($login_page =~ m{L_IDS_SEND_MESSAGE_URL\s*=\s*"(.*?)";.*?L_IDS_RECV_MESSAGE_URL\s*=\s*"(.*?)";.*?L_IDS_GET_RESOURCE_URL\s*=\s*"(.*?)";.*?__sessionId\s*=\s*"(.*?)";}is) {
        my ($send_url, $recv_url, $resource_url, $sessionid) = ($1, $2, $3, $4);
        $self->{send_url} = $send_url;
        $self->{recv_url} = $recv_url;
        $self->{resource_url} = $resource_url;
        $self->{sessionid} = $sessionid;        
        my $res = $ua->get( $self->join_url());
        
        $self->{last_login_time} = time;
    } else {
        print "login failed\n";
    }
}

sub check_need_login {
    my $self = shift;
    if (time - $self->{last_login_time} > 60 * 60 * 5 ) {
        $self->login;
    }
}

sub get_robot_text {
    my $self = shift;
    my $msg = shift;
    my $try_times = 5;
    my $text;
    for (1..$try_times) {
        $text = $self->_invoke_robot($msg);
        if ($text eq '') {
            $self->login;
        } else {
            last;
        }
    }
    return $text;
}
sub _invoke_robot {
    my $self = shift;
    my $msg = shift;
    
    #$self->check_need_login;
    my $ua = $self->{ua};
    my $res = $ua->get( $self->send_message_url($msg));
    return '' if ($res->code ne '200');    
    $res = $ua->get( $self->recv_message_url());
    return '' if ($res->code ne '200');
    my $text = $res->content;
    if ($text =~ m{processMessageReceived\((.*)\)}s) {
        my $json_text = $1;
        my $ra = JSON->new->utf8(0)->decode($json_text);
        if (@$ra > 0  and $ra->[0]->{CMD} eq 'CHAT') {
            return  encode('utf8', decode('utf8', $ra->[0]->{MSG}) );
        }
    }
    
    return '';    
}


sub join_url {
    my $self = shift;
    my $url = sprintf('%sSID=%s&USR=%s&CMD=JOIN&r=0.%s', $self->{send_url}, $self->{sessionid}, $self->{sessionid}, int(rand(100000)));
    
}

sub send_message_url {
    my $self = shift;
    my $msg = shift;
    my $url = sprintf('%sSID=%s&USR=%s&CMD=CHAT&MSG=%s&r=0.%s', $self->{send_url}, $self->{sessionid}, $self->{sessionid}, $msg, int(rand(100000)));
    
}

sub recv_message_url {
    my $self = shift;

    my $url = sprintf('%sSID=%s&USR=%s&r=0.%s', $self->{recv_url}, $self->{sessionid}, $self->{sessionid},int(rand(100000)) );
    
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

XiaoI - Perl extension for blah blah blah

=head1 SYNOPSIS

  use XiaoI;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for XiaoI, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

A. U. Thor, E<lt>a.u.thor@a.galaxy.far.far.awayE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by A. U. Thor

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut


__END__
http://202.109.73.86/engine/flashrobot2/send.js?encoding=utf-8&SID=79885279463301857&USR=79885279463301857&CMD=CHAT&SIG=%E4%BD%A0&MSG=yun&FTN=%E5%AE%8B%E4%BD%93&FTS=&FTC=000000&r=0.7941525560304943


http://202.109.73.87/engine/flashrobot2/send.js?encoding=utf-8&SID=79885279463301857&USR=79885279463301857&CMD=CHAT&SIG=%E4%BD%A0&MSG=aaa&FTN=%E5%AE%8B%E4%BD%93&FTS=&FTC=000000&r=0.9527757616491458


http://202.109.73.87/engine/flashrobot2/recv.js?encoding=utf-8&SID=79885279463301857&USR=79885279463301857&r=0.435727363177388

