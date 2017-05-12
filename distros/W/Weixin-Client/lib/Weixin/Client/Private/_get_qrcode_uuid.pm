package Weixin::Client;
sub _get_qrcode_uuid{
    my $self = shift;
    my $api = 'https://login.weixin.qq.com/jslogin'; 
    my @query_string = (
        appid           =>  'wx782c26e4c19acffb',
        redirect_uri    =>  'https://wx.qq.com/cgi-bin/mmwebwx-bin/webwxnewloginpage',
        fun             =>  'new',
        lang            =>  'zh_CN',
        _               =>  $self->now(),
    ); 
    my $r = $self->http_get(Weixin::Util::gen_url2($api,@query_string));
    return undef unless defined $r;
    $r=~s/\s+//g;
    my($code,$uuid) = $r=~/window\.QRLogin\.code=(\d+);window\.QRLogin\.uuid="([^"]+)"/g;
    return ($code==200 and $uuid)?$uuid:undef; 
}

1;
