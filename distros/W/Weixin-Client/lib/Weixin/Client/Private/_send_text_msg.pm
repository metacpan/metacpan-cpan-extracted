package Weixin::Client;
sub _send_text_msg {
    my $self = shift;
    my $msg = shift;
    my $api = "https://wx.qq.com/cgi-bin/mmwebwx-bin/webwxsendmsg";
    my @query_string =(
        sid             =>  $self->wxsid,
        skey            =>  uri_escape($self->skey),
        r               =>  $self->now(),
        skey            =>  uri_escape($self->skey),
        pass_ticket     => $self->pass_ticket,
    );  
    my $t = $self->now();
    my $post = {
        BaseRequest =>  {
            DeviceID    => $self->deviceid,
            Sid         => $self->wxsid,
            Skey        => $self->skey,
            Uin         => $self->wxuin, 
        },
        Msg             => {
            ClientMsgId     =>  $t,
            Content         =>  decode("utf8",$msg->{Content}),
            FromUserName    =>  $msg->{FromId},
            LocalID         =>  $t,
            ToUserName      =>  $msg->{ToId},
            Type            =>  1,
        },
    };     
    my $url = gen_url($api,@query_string);
    my $callback = sub {
        my $response = shift;
        my $status = $self->_parse_send_status_data($response->content);
        if(defined $status and $status->{is_success} == 0){
            $self->_send_text_msg($msg);
            return;
        }
        elsif(defined $status){
            if(ref $msg->{cb} eq 'CODE'){
                $msg->{cb}->(
                    $msg,                   #msg
                    $status->{is_success},  #is_success
                    $status->{status}       #status
                );
            }
            if(ref $self->{on_send_msg} eq 'CODE'){
                $self->{on_send_msg}->(
                    $msg,                   #msg
                    $status->{is_success},  #is_success
                    $status->{status}       #status
                );
            }
        }
    };         
    my $post_data = $self->json_encode($post);
    print "POST $url\n$post_data\n" if $self->{debug};;
    $self->timer2(
        "_send_msg",
        $self->{_send_msg_interval},
        sub{
            $self->asyn_http_post(
                $url,
                ("Content-Type"=>"application/json; charset=UTF-8"),
                Content=>$post_data,
                $callback,
            );
        },
    );
    
}
1;
