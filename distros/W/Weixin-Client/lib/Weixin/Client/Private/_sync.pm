package Weixin::Client;
sub _sync {
    my $self = shift;
    return if $self->{_synccheck_running} ;
    $self->{_sync_running} = 1;
    my $api = 'https://wx.qq.com/cgi-bin/mmwebwx-bin/webwxsync';
    my @query_string = (
        sid     => $self->wxsid,
        skey    => uri_escape($self->skey),
        r       => $self->now(),
        skey    => uri_escape($self->skey),
        pass_ticket => $self->pass_ticket,
    );  
    my $post = {
        BaseRequest =>  {Uin => $self->wxuin,Sid=>$self->wxsid,},
        SyncKey     =>  $self->sync_key,
        rr          =>  $self->now(),
    };
    my $callback = sub{
        $self->{_sync_running} = 0;
        my $response = shift;
        print $response->content(),"\n" if $self->{debug};       
        my $d = $self->json_decode($response->content());
        #return if $d->{BaseResponse}{Ret}!=0;
        $self->_parse_sync_data($d); 
        
    };
    my $url = gen_url($api,@query_string);
    $self->timer2(
        "_sync",
        $self->{_sync_interval},
        sub{
            print "POST $url\n" if $self->{debug};
            $self->asyn_http_post(
                $url,
                ("Content-Type"=>"application/json; charset=UTF-8"),
                Content=>$self->json_encode($post),
                $callback
            );
    });

}
1;
