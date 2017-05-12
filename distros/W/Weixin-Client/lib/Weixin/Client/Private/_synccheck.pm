package Weixin::Client;
sub _synccheck{
    my $self = shift;
    return if $self->{_sync_running} ;
    my $api = "https://webpush.weixin.qq.com/cgi-bin/mmwebwx-bin/synccheck";
    $self->{_synccheck_running} = 1;
    my $callback = sub {
        my $response = shift;
        $self->{_synccheck_running} = 0;
        unless($response->is_success){
            $self->_synccheck() ;
            return ;
        }
        #window.synccheck={retcode:"0",selector:"0"}    
        my($retcode,$selector) = $response->content()=~/window\.synccheck=\{retcode:"([^"]+)",selector:"([^"]+)"\}/g;
        $self->_parse_synccheck_data($retcode,$selector);
    }; 
    my @query_string = (
        skey        =>  $self->skey,  
        callback    =>  "jQuery1830847224326338619_" . $self->now(),
        r           =>  $self->now(), 
        sid         =>  $self->wxsid,
        uin         =>  $self->wxuin,
        deviceid    =>  $self->deviceid,
        synckey     =>  join("|",map {$_->{Key} . "_" . $_->{Val};} @{$self->sync_key->{List}}),
        _           =>  $self->now(),
    );
    my $url = gen_url2($api,@query_string);
    $self->timer2("_synccheck",$self->{_synccheck_interval},sub{
        print "GET $url\n" if $self->{debug};
        $self->asyn_http_get($url,$callback);
    });
}
1;
