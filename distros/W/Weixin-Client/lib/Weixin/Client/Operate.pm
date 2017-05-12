package Weixin::Client::Operate;
use AE;
use POSIX;

use Weixin::Client::Cache;
use Weixin::Message::Queue;

use Weixin::Util;
use Weixin::Client::Private::_login;
use Weixin::Client::Private::_init;
use Weixin::Client::Private::_logout;
use Weixin::Client::Private::_sync;
use Weixin::Client::Private::_synccheck;

our $CLIENT_COUNT       = 0;
sub login{
    my $self = shift;
    if($self->_login()){
        console "获取基础信息...\n";
        $self->_init();
        $self->update_friend();

        $self->welcome();
        if(ref $self->{on_login} eq 'CODE'){
            eval{
                $self->{on_login}->();
            };
            console $@ . "\n" if $@;
        }
        return 1;
    }
    else{
        exit;
    }
}
sub logout{
    my $self = shift;
    my $type = shift || 0;
    console "客户端注销...";
    $self->_logout($type);
}
sub sync{

}
sub synccheck{

}
sub run{
    my $self = shift;
    $self->ready();
    if(ref $self->{on_run} eq 'CODE'){
        eval{
            $self->{on_run}->();
        };
        console "$@\n" if $@;
    }
    console "客户端运行中...\n";
    $self->{cv} = AE::cv;
    $self->{cv}->recv
}
sub RUN{
    console "启动全局事件循环...\n";
    AE::cv->recv;
}
sub ready{
    my $self = shift;
    console "开始接收消息\n";
    $self->_synccheck();

    if(ref $self->{on_ready} eq 'CODE'){
        eval{
            $self->{on_ready}->();
        };
        console "$@\n" if $@;
    }
    $CLIENT_COUNT++;
}
sub stop{
    my $self = shift;
    $self->{is_stop} = 1;
    if($CLIENT_COUNT > 1){
        $CLIENT_COUNT--;
        $self->{watchers}{rand()} = AE::timer 600,0,sub{
            undef %$self; 
        };
    }
    else{
        exit;         
    }
}
sub prepare {
    my $self = shift;
    $self->{_receive_message_queue}->get(sub{
        my $msg = shift;
        return if $self->{is_stop};
        if(ref $self->{on_receive_msg} eq 'CODE'){
            eval{
                $self->{on_receive_msg}->($msg);
            };
            console $@ . "\n" if $@;
        } 
    });
    $self->{_send_message_queue}->get(sub{
        my $msg = shift;
        return if $self->{is_stop};
        if($msg->{TTL} <= 0){
            my $status = {is_success=>0,status=>"TTL过期"};
            if(ref $msg->{cb} eq 'CODE'){
                $msg->{cb}->(
                    $msg,
                    $status->{is_success},
                    $status->{status},
                );
            }
            if(ref $self->{on_send_msg} eq 'CODE'){
                $self->{on_send_msg}->(
                    $msg,
                    $status->{is_success},
                    $status->{status},
                );
            }
        
            return;
        }
        $msg->{TTL}--;
            $msg->{MsgType} eq "text"       ? $self->_send_text_msg($msg)
        :                                   undef
        ;
    });
    eval{
        my $tmpdir = $self->{tmpdir};
        unlink <$tmpdir/weixin_qrcode_*.jpg>;
    };
}
sub welcome{
    my $self = shift;
    my $w = $self->user;
    console "欢迎回来, $w->{NickName}\n";#($w->{Province} $w->{City})\n";
    console "个性签名: " . ($w->{Signature}?$w->{Signature}:"（无）") . "\n"
}
sub user {
    my $self = shift;
    return $self->{_data}{user};
}

sub sync_key {
    my $self = shift;
    if(defined $_[0]){
        $self->{_token}{sync_key} = $_[0];
    }
    else{
        return $self->{_token}{sync_key}; 
    }
}

sub skey {
    my $self = shift;
    if(defined $_[0]){
        $self->{_token}{skey} = $_[0];
    }
    else{
        return $self->{_token}{skey};
    }
} 
sub wxsid {
    my $self = shift;
    if(defined $_[0]){
        $self->{_token}{wxsid} = $_[0]; 
    }
    else{
       $self->{_token}{wxsid} = $self->search_cookie("wxsid") unless defined $self->{_token}{wxsid};
       return  $self->{_token}{wxsid};
    }
}
sub wxuin{
    my $self = shift;
    if(defined $_[0]){
        $self->{_token}{wxuin} = $_[0];
    }
    else{
        $self->{_token}{wxuin} = $self->search_cookie("wxuin") unless defined $self->{_token}{wxuin};
        return $self->{_token}{wxuin};
    }
}
sub pass_ticket {
    my $self = shift;
    if(defined $_[0]){
        $self->{_token}{pass_ticket} = $_[0];
    }
    else{
        return $self->{_token}{pass_ticket} || "undefined";
    }
}
sub deviceid {
    my $self = shift;
    return $self->{_token}{deviceid} if defined $self->{_token}{deviceid};
    my $a = "e";
    for(my $b = 0;15 > $b;$b++){
        $a .= POSIX::floor(10 * rand());
    }
    $self->{_token}{deviceid} = $a; 
    return $a;
}

1;
