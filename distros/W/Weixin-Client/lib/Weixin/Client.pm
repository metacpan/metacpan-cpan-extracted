package Weixin::Client;
use strict;
use File::Spec;
use Weixin::Util;
use LWP::UserAgent;
use Weixin::UserAgent;
use LWP::Protocol::https;

use base qw(
    Weixin::Message 
    Weixin::Client::Callback
    Weixin::Client::Operate
    Weixin::Client::Friend
    Weixin::Client::Chatroom
    Weixin::Client::Request 
    Weixin::Client::Cron
    Weixin::Client::Plugin
    Weixin::Client::Base
);

our $VERSION = "2.1";

sub new{
    my $class = shift;
    my %p = @_;
    my $agent = 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/37.0.2062'; 
    my $tmpdir = File::Spec->tmpdir();
    my $cookie_filename = $p{login_file} || "$tmpdir/weixin_client_login.dat";
    my $self = {
        cookie_jar              => HTTP::Cookies->new(hide_cookie2=>1,file=>$cookie_filename,autosave=>1),
        debug                   => $p{debug},
        _token                  => {},
        _watchers               => {},
        _intervals              => {},
        _synccheck_error_count  => 0,
        _synccheck_running      => 0,
        _sync_running           => 0,
        _sync_interval          => 1,
        _synccheck_interval     => 1,
        _send_msg_interval      => 4,
        _last_sync_time         => undef,
        _last_synccheck_time    => undef,
        _send_message_queue     => Weixin::Message::Queue->new,
        _receive_message_queue  => Weixin::Message::Queue->new,       
        _data       => {
            user                => {},  
            friend              => [],
            chatroom            => [],
        },
        on_run                  => undef,
        on_receive_msg          => undef,
        on_send_msg             => undef,
        is_stop                 => 0,
        plugin_num              => 0,
        plugins                 => {},
        ua_retry_times          => 5,
        tmpdir                  => $tmpdir,
        client_version          => $VERSION,
    };
    $self->{ua} = LWP::UserAgent->new(
        cookie_jar      =>  $self->{cookie_jar},
        agent           =>  $agent,
        timeout         =>  300,
        ssl_opts        =>  {verify_hostname => 0},
    );
    $self->{asyn_ua} = Weixin::UserAgent->new(
        cookie_jar  =>  $self->{cookie_jar},
        agent       =>  $agent,
        request_timeout =>  300,
        inactivity_timeout  =>  300,
    );

    if($self->{debug}){
        $self->{ua}->add_handler(request_send => sub {
            my($request, $ua, $h) = @_;
            print $request->as_string;
            return;
        });
        $self->{ua}->add_handler(
            response_header => sub { my($response, $ua, $h) = @_;
            print $response->as_string;
            return;
            
        });
        $self->{ua}->add_handler(
            response_done => sub { my($response, $ua, $h) = @_;
            print substr($response->content,0,1000),"\n" if $response->header("content-type")=~/^text/;
            return;
        });
    }
    bless $self,$class;
    $self->prepare();
    return $self;
}



1;
