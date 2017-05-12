package Weixin::Client;
use Weixin::Util;
sub _logout {
    my $self = shift;
    my $type = shift || 0;
    my $api = "https://wx.qq.com/cgi-bin/mmwebwx-bin/webwxlogout";
    my @query_string = (
        redirect    =>  1,
        type        =>  $type,
        skey        =>  uri_escape($self->skey),
    ); 
    my $post = [
        sid => $self->wxsid,
        uin => $self->wxuin,
    ];
    $self->http_post(Weixin::Util::gen_url($api,@query_string),$post,(Referer=>"https://wx.qq.com/?&lang=zh_CN"));  
    return 1;
}
1;
